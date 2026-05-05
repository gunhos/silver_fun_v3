# Block & Report Users Sprint Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add user-facing safety features — block, report, and a Settings Safety hub — so seniors can self-manage unwanted interactions without admin intervention.

**Architecture:** A new `features/safety` module owns block/report repos, providers, and UI. Blocked-uid set is exposed as a Riverpod stream and intersected into existing `feedProvider` and `matchThreadsProvider` to filter Discover and Chats. Reports are written to a top-level `reports/` collection plus a per-user `reportedUsers` history copy so Settings can display the user's own report log without granting read access to the global queue.

**Tech Stack:** Flutter, Riverpod, Firebase Auth, Cloud Firestore, `fake_cloud_firestore` for tests, ARB-based l10n (`app_en.arb`, `app_ko.arb`).

---

## 1. Sprint Goal

Ship user-controlled safety primitives in one branch:

1. Block a user from profile detail or chat.
2. Report a user from profile detail or chat with a reason and optional details.
3. View, navigate, and unblock from a Settings → Safety → Blocked users screen.
4. View own report history from Settings → Safety → Reported users.
5. Hide blocked users from Discover.
6. Disable chat send and hide chat threads with blocked users.
7. Update `firestore.rules` (in source — do **not** deploy this sprint).

The result is a coherent, locally testable safety story that does not require an admin tool to be useful.

## 2. Non-Goals

- No admin moderation UI, no `reports/` review queue, no role/claim plumbing. Plan future-compatible schema only.
- No Cloud Functions, push notifications, email, or escalation pipeline.
- No reverse-block visibility ("hide me from users who blocked me"). That requires a global reverse index or Cloud Function and is out of scope.
- No deletion of existing chat documents. Hiding/disabling only.
- No changes to Firebase project config, Android signing, package name, app icon/splash, or Play Store assets.
- No deployment of `firestore.rules`. Commit the rules change; deploy is a separate operator step.
- No automated removal of likes/connections to/from blocked users beyond the atomic batch run by the block action itself.

## 3. Proposed Firestore Schema

### Blocked users (per-blocker subcollection)

`users/{currentUid}/blockedUsers/{blockedUid}`

```json
{
  "blockedUid": "abc123",
  "blockedAt": Timestamp,
  "blockedUserName": "Alice",
  "blockedUserPhotoUrl": "https://...",
  "blockedUserAge": 67
}
```

- Doc ID = blocked user's uid (cheap membership check).
- Denormalized name/photo/age so the Blocked Users screen renders without a second read per row, and survives the blocked user later deleting their account.

### Reports (top-level, admin-readable later)

`reports/{auto-id}`

```json
{
  "reporterUid": "abc123",
  "reportedUid": "xyz789",
  "reason": "harassment",
  "details": "Optional free-text from reporter",
  "source": "profile" | "chat",
  "chatId": "abc123_xyz789",
  "createdAt": Timestamp,
  "status": "new",
  "reportedUserName": "Bob",
  "reportedUserPhotoUrl": "https://...",
  "reporterName": "Alice"
}
```

- `reason` is a stable enum string (not a localized label). UI maps to a localized label at display time.
- `details` is optional, capped at 500 chars in UI.
- `source` distinguishes profile-page reports from chat-page reports (future moderation will want this).
- `chatId` only set when `source == "chat"`.
- `status: "new"` reserves a status field so a future admin tool can transition to `"reviewed" | "actioned" | "dismissed"` without a schema migration.
- Denormalized name/photo so reports stay meaningful if either user later deletes their account.

### Optional report history (per-reporter)

`users/{currentUid}/reportedUsers/{reportId}`

```json
{
  "reportId": "auto-id-from-reports-collection",
  "reportedUid": "xyz789",
  "reason": "harassment",
  "details": "Optional free-text from reporter",
  "createdAt": Timestamp,
  "reportedUserName": "Bob",
  "reportedUserPhotoUrl": "https://...",
  "reportedUserAge": 70
}
```

- Doc ID = reportId (matches the top-level report's id, written in the same batch).
- Lets Settings → Reported users render purely from the user's own subcollection without ever reading the global `reports/` collection.

## 4. Firestore Security Rules Plan

Edit `firestore.rules`. Do **not** deploy.

Add three rule blocks:

```javascript
// Per-user blocked list — only the blocker can read or write their own list.
match /users/{uid}/blockedUsers/{blockedUid} {
  allow read: if isOwner(uid);
  allow create: if isOwner(uid)
    && request.resource.data.blockedUid == blockedUid
    && request.resource.data.blockedAt is timestamp;
  allow delete: if isOwner(uid);
  allow update: if false;
}

// Reports — any signed-in user can create their own; nobody can read or modify
// from the client. Admin tooling (future) will read via a privileged service.
match /reports/{reportId} {
  allow create: if isSignedIn()
    && request.resource.data.reporterUid == request.auth.uid
    && request.resource.data.reportedUid is string
    && request.resource.data.reportedUid != request.auth.uid
    && request.resource.data.reason is string
    && request.resource.data.reason.size() > 0
    && request.resource.data.status == 'new'
    && request.resource.data.createdAt is timestamp;
  allow read, update, delete: if false;
}

// Per-user report history — only the reporter can read or write their own.
match /users/{uid}/reportedUsers/{reportId} {
  allow read: if isOwner(uid);
  allow create: if isOwner(uid)
    && request.resource.data.reportedUid is string
    && request.resource.data.reportedUid != request.auth.uid
    && request.resource.data.reason is string;
  allow update, delete: if false;
}
```

Notes:

- Reuses the existing `isOwner(uid)` and `isSignedIn()` helpers in `firestore.rules`.
- The catch-all `match /{document=**} { allow read, write: if false; }` already at the bottom of `firestore.rules` does NOT need to move; nested matches above it take precedence.
- We deliberately disallow client reads of `reports/{reportId}` so a normal user cannot enumerate other people's reports.
- We allow self-delete on `blockedUsers` (used by unblock) but disallow update — an "edit blocked user" operation has no meaning here.
- Reports are append-only from the client. No client edits, no client deletes.

## 5. UI/UX Plan

### Profile detail (`/profile/:userId`)

Modify `ProfileViewScreen` (`lib/features/feed/screens/profile_view_screen.dart`):

- Add an overflow icon button (`Icons.more_vert`) inside the `_BackPill` row, top-right corner.
- Tapping shows a bottom sheet (`SafetyActionSheet`) with two large rows: "Block <name>" and "Report <name>".
- Both rows use 56pt-tall list tiles, accent-colored icons, and uppercase-free labels — matches the senior-friendly tap target standard already used in `SettingsScreen`.

### Chat (`/chat/:userId`)

Modify `ChatScreen` (`lib/features/chat/screens/chat_screen.dart`):

- Add `Icons.more_vert` to `_Header`, replacing the static heart icon's right-margin slot (keep heart, just place menu after it).
- Tapping shows the same `SafetyActionSheet` plus a third row "View profile".
- When the displayed counterpart appears in `blockedSetProvider`, the screen renders a banner above `_SendBar`: localized "You blocked this person. Unblock from Settings → Safety to continue chatting." and disables both `TextField` and the send button.
- The banner is visible in addition to the (already-implemented) match-card; new messages are NOT shown in the input but historical messages remain visible.

### Settings → Safety (`/settings`)

Modify `SettingsScreen` (`lib/features/profile/screens/settings_screen.dart`):

- Add a new `_SectionTitle('Safety')` section between "Notifications" and "Account".
- Inside a `_SettingsCard`, two `ListTile` rows:
  - "Blocked users" → `context.push('/settings/blocked')`
  - "Reported users" → `context.push('/settings/reported')`
- Both rows use `Icons.chevron_right` per existing convention.

### Blocked Users screen (`/settings/blocked`)

New file `lib/features/safety/screens/blocked_users_screen.dart`:

- AppBar title "Blocked users".
- ListView of denormalized name + photo + age. Each row has a trailing "Unblock" button (text button styled with accent color).
- Tapping "Unblock" opens a confirmation dialog: "Unblock <name>? They will be able to see your profile and like you again." with Cancel / Unblock actions. Unblock is destructive-styled (accent), Cancel is ghost.
- After unblock, show a toast via `showToast(ref, l.toastUnblocked(name))`.
- Empty state: localized "No one is blocked." with a one-line subtitle "When you block someone, they show up here."

### Reported Users screen (`/settings/reported`)

New file `lib/features/safety/screens/reported_users_screen.dart`:

- AppBar title "Reported users".
- ListView of denormalized name + photo + age + localized reason label + relative timestamp.
- Read-only — no actions (no "delete report" since reports are immutable from the client).
- Empty state: localized "You haven't reported anyone." + subtitle.

### Block confirmation dialog

`lib/features/safety/widgets/block_confirm_dialog.dart`:

- Material `AlertDialog`.
- Title: "Block <name>?"
- Body: "They won't see your profile in Discover, you won't see theirs, and your chats will be hidden. You can unblock anytime from Settings to restore everything."
- Actions: Cancel (ghost), Block (accent, semibold).
- The wording deliberately avoids implying anything is deleted — block is fully reversible. See §6.

### Report reason picker

`lib/features/safety/widgets/report_dialog.dart`:

- Modal bottom sheet using `showModalBottomSheet` — bottom sheets play better on small screens than `AlertDialog` for radio lists with optional details.
- `RadioGroup<ReportReason>` with the six reasons (see §7).
- A multi-line `TextField` for optional details (max 500 chars, hint "Add anything moderators should know (optional)").
- Footer row: Cancel (ghost) + Submit (accent, disabled until a reason is picked).
- After successful submit, show toast "Report sent. Thank you for keeping our community safe."

### Unblock flow

- Single entry point: tap "Unblock" on a row in `BlockedUsersScreen`.
- No reverse-side notification, no analytics ping in this sprint.

## 6. Blocking Behavior

**Revised product decision (2026-05-03):** Block does **not** delete any data. It is purely a filter layer applied on top of the existing data graph. The first implementation preserves likes, the like-derived match set, and chat documents. Unblock is therefore lossless and instant — every previously visible relationship comes back the moment the block doc is deleted. This is the safer default for a senior-targeted app: an accidental block can be undone with no loss.

The atomic "delete likes on block" approach from the original draft is rejected. We may revisit it later if support tickets show that ex-matches are pestering users post-unblock, but that requires data-loss confirmation flows and a measured product debate that does not belong in this sprint.

### Discover filtering

`feedProvider` in `lib/features/feed/providers/feed_provider.dart` already composes `watchFeed` + `likedByMeProvider`. Add `blockedSetProvider` (Stream<Set<String>>) and pull a third value out of the existing pipeline:

- Filter `profiles.where((p) => !blockedSet.contains(p.uid))` after the existing liked-set merge.
- Compose at the provider level — do **not** push a `blockedUids` parameter into `FeedRepository.watchFeed`. Repos stay storage-shaped; provider does the cross-cutting filter.

### Likes / matches / Liked-You filtering

Likes documents (`likes/.../liked/...` and `likedBy/.../from/...`) are **never** written or deleted by the block flow. Filtering happens at the consumer-provider layer:

- **`matchesProvider`** (`lib/features/chat/providers/chats_provider.dart`): currently `liked.intersection(likers)`. Change to `liked.intersection(likers).difference(blocked)`. This makes the connection appear severed in the UI without touching either like edge.
- **`likedYouScreen`** consumers: filter `likedByOthersProvider` output by `blockedSetProvider` so a blocked user does not appear in the blocker's "Liked you" list. Filter at the screen / a small derived provider, not inside `LikesRepository`.
- **`likedByMeProvider`**: do not filter. The set is internal plumbing (used to mark profile cards as `liked: true` and to compute matches). Since blocked users are filtered out of Discover anyway, leaving the set untouched costs nothing and keeps the underlying graph honest.

The other direction (B's view) is not modified in this sprint. B's `likedYouScreen` may still show A as a liker; B's `matchesProvider` may still include A. Symmetric hiding ("hide me from people who blocked me") would require a public reverse index or Cloud Function and remains out of scope (see §2 and §12.6).

### Chat hiding/disabling

- `matchThreadsProvider` in `lib/features/chat/providers/chats_provider.dart`: depends on `matchesProvider`, which now already excludes blocked uids. No additional filter needed here once `matchesProvider` is fixed — but cancel any in-flight chat-message subscriptions for newly blocked uids to prevent listener leaks (see §12.3).
- `ChatScreen`: render a banner + disabled send bar when the counterpart is in `blockedSetProvider` (see §5).
- The `chats/{chatId}` document and all `messages/` are preserved untouched. Historical messages remain readable to the blocker. After unblock, the thread reappears with full history — no "what just happened?" surprise.
- The other side can still send messages because `chats/{chatId}` rules are unchanged. Those messages persist in Firestore but never appear in the blocker's `matchThreadsProvider` list, and entering the chat via deep link shows the blocked banner. Server-side enforcement of "block prevents incoming messages" needs a Cloud Function and is out of scope.

### Block action — what it actually writes

Single-document write, no batch needed:

1. Sets `users/A/blockedUsers/B` with denormalized name/photo/age/timestamp.

That is the entire transaction. No like edges are read, written, or deleted. No chat documents are touched.

### What happens after unblock

- The block doc is deleted.
- All previously hidden surfaces re-emerge in real time because the filters are reactive Streams:
  - B reappears in A's Discover.
  - If A and B were a match before the block, the match returns and the chat thread re-appears in A's Chats list with full message history intact.
  - B reappears in A's Liked-You list if B had liked A.
- Nothing needs to be recreated; nothing needs re-confirmation.
- The unblock confirmation dialog should communicate this clearly so users aren't worried about losing their connection by experimenting with block.

## 7. Reporting Behavior

### Report reasons (initial set)

Stable enum strings in `ReportReason`:

- `harassment` — "Harassing or rude messages"
- `fake_profile` — "Fake profile or impersonation"
- `spam` — "Spam or scam"
- `inappropriate_content` — "Inappropriate photos or content"
- `underage` — "Appears to be under 18"
- `other` — "Something else"

UI shows the localized label; Firestore stores the enum string. Add new reasons later without breaking old reports.

### Optional details

Free-text TextField, max 500 chars, optional, hint encourages context but never required.

### Whether the reported user is notified

**No.** The reported user is not notified, does not receive any in-app indication, and `reports/{reportId}` is not readable from the client. This sprint treats reports as a one-way, fire-and-forget channel into a future moderation queue.

### Admin / moderation future compatibility

- `status: "new"` field reserved for a future admin tool.
- Top-level `reports/` collection is the queue.
- Denormalized reporter/reported names and photos let an admin tool render a list view without joining against `users/`.
- Future admin role can be added via Firebase Auth custom claims; rule will become `allow read: if request.auth.token.admin == true;`.
- Per-user `reportedUsers` history is independent of the global queue, so admins can purge `reports/` without erasing user-visible history (or vice versa).

## 8. Files Likely To Edit

**Create:**

- `lib/features/safety/models/blocked_user.dart`
- `lib/features/safety/models/report_entry.dart`
- `lib/features/safety/models/report_reason.dart`
- `lib/features/safety/repository/block_repository.dart`
- `lib/features/safety/repository/report_repository.dart`
- `lib/features/safety/providers/safety_providers.dart`
- `lib/features/safety/widgets/safety_action_sheet.dart`
- `lib/features/safety/widgets/block_confirm_dialog.dart`
- `lib/features/safety/widgets/report_dialog.dart`
- `lib/features/safety/screens/blocked_users_screen.dart`
- `lib/features/safety/screens/reported_users_screen.dart`
- `test/features/safety/blocked_user_model_test.dart`
- `test/features/safety/report_entry_model_test.dart`
- `test/features/safety/block_repository_test.dart`
- `test/features/safety/report_repository_test.dart`
- `test/features/safety/blocked_users_screen_test.dart`
- `test/features/safety/reported_users_screen_test.dart`
- `test/features/safety/report_dialog_test.dart`

**Modify:**

- `firestore.rules` (do not deploy)
- `lib/features/feed/providers/feed_provider.dart` — filter blocked set
- `lib/features/chat/providers/chats_provider.dart` — filter blocked set out of `matchThreadsProvider`
- `lib/features/feed/screens/profile_view_screen.dart` — overflow menu
- `lib/features/chat/screens/chat_screen.dart` — overflow menu + blocked banner + disabled send
- `lib/features/profile/screens/settings_screen.dart` — Safety section
- `lib/core/router/router.dart` — `/settings/blocked` and `/settings/reported`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_ko.arb`
- `test/features/feed/feed_repository_test.dart` (no — repo signature unchanged)
- Existing widget tests for profile/chat/settings screens may need golden-key updates.

## 9. Localization Keys Needed

Add to both `lib/l10n/app_en.arb` and `lib/l10n/app_ko.arb`. After editing both `.arb` files, run `flutter gen-l10n` (the project is configured via `l10n.yaml` to regenerate `app_localizations*.dart`).

```text
safetyMenuBlock                  → "Block {name}" / "{name}님 차단"
safetyMenuReport                 → "Report {name}" / "{name}님 신고"
safetyMenuViewProfile            → "View profile" / "프로필 보기"

blockDialogTitle                 → "Block {name}?" / "{name}님을 차단할까요?"
blockDialogBody                  → "They won't see your profile in Discover, you won't see theirs, and your chats will be hidden. You can unblock anytime from Settings to restore everything."
                                    / "서로의 프로필이 둘러보기에서 보이지 않게 되고 대화도 숨겨집니다. 설정에서 언제든 차단을 해제하면 모두 그대로 돌아와요."
blockDialogCancel                → "Cancel" / "취소"
blockDialogConfirm               → "Block" / "차단하기"

unblockDialogTitle               → "Unblock {name}?" / "{name}님 차단을 해제할까요?"
unblockDialogBody                → "They will reappear in Discover. If you were already connected, your chat and message history will come back."
                                    / "둘러보기에 다시 나타나요. 이미 연결된 사이였다면 대화와 메시지 기록도 그대로 돌아옵니다."
unblockDialogCancel              → "Cancel" / "취소"
unblockDialogConfirm             → "Unblock" / "차단 해제"

reportDialogTitle                → "Report {name}" / "{name}님 신고"
reportDialogSubtitle             → "Why are you reporting this person?" / "어떤 이유로 신고하시나요?"
reportReasonHarassment           → "Harassing or rude messages" / "괴롭힘 또는 무례한 메시지"
reportReasonFakeProfile          → "Fake profile or impersonation" / "가짜 프로필 또는 사칭"
reportReasonSpam                 → "Spam or scam" / "스팸 또는 사기"
reportReasonInappropriateContent → "Inappropriate photos or content" / "부적절한 사진 또는 게시물"
reportReasonUnderage             → "Appears to be under 18" / "미성년자로 보임"
reportReasonOther                → "Something else" / "기타"
reportDetailsHint                → "Add anything moderators should know (optional)" / "관리자에게 전할 내용을 적어 주세요 (선택)"
reportDialogCancel               → "Cancel" / "취소"
reportDialogSubmit               → "Submit" / "보내기"

settingsSectionSafety            → "Safety" / "안전"
settingsBlockedUsers             → "Blocked users" / "차단한 사용자"
settingsReportedUsers            → "Reported users" / "신고한 사용자"

blockedUsersTitle                → "Blocked users" / "차단한 사용자"
blockedUsersEmptyTitle           → "No one is blocked." / "차단한 사용자가 없어요."
blockedUsersEmptySubtitle        → "When you block someone, they show up here." / "누군가를 차단하면 여기에 표시돼요."
blockedUsersUnblock              → "Unblock" / "해제"

reportedUsersTitle               → "Reported users" / "신고한 사용자"
reportedUsersEmptyTitle          → "You haven't reported anyone." / "아직 신고한 사용자가 없어요."
reportedUsersEmptySubtitle       → "When you report someone, the report shows up here." / "누군가를 신고하면 여기에 표시돼요."

chatBlockedBanner                → "You blocked this person. Unblock from Settings → Safety to continue chatting."
                                    / "이분을 차단했어요. 다시 대화하려면 설정 → 안전에서 차단을 해제해 주세요."

toastBlocked                     → "Blocked {name}." / "{name}님을 차단했어요."
toastUnblocked                   → "Unblocked {name}." / "{name}님 차단을 해제했어요."
toastReported                    → "Report sent. Thank you for keeping our community safe."
                                    / "신고가 접수되었어요. 안전한 커뮤니티를 만들어 주셔서 감사합니다."
toastBlockFailed                 → "Could not block. Please try again." / "차단에 실패했어요. 다시 시도해 주세요."
toastReportFailed                → "Could not send report. Please try again." / "신고를 보내지 못했어요. 다시 시도해 주세요."
```

ICU `{name}` placeholders follow the existing `profileNameAge` / `chatMatchCardHelloNamed` pattern in this project.

## 10. Tests To Add / Update

**Add (new files):**

- `test/features/safety/blocked_user_model_test.dart` — `fromFirestore` / `toMap` round-trip, missing-fields fallback.
- `test/features/safety/report_entry_model_test.dart` — same shape as above.
- `test/features/safety/block_repository_test.dart` — using `FakeFirebaseFirestore`:
  - `block` writes `users/me/blockedUsers/target` with denormalized fields.
  - `block` does **not** read, write, or delete any `likes/...` or `likedBy/...` docs (assert by seeding both like edges, calling block, and re-reading them — both must still exist).
  - `block` does not touch any `chats/{chatId}` document.
  - `block` is idempotent (calling twice doesn't error and leaves a single doc; `blockedAt` stays the original timestamp or is overwritten — pick one and assert it; recommend overwrite-with-server-timestamp for simplicity).
  - `unblock` deletes only the block doc, does not touch likes or chats.
  - `unblock` is idempotent (calling on an unblocked uid does not throw).
  - `watchBlockedSet` emits set of uids.
  - `watchBlockedList` emits list ordered by `blockedAt desc`.
- `test/features/safety/report_repository_test.dart`:
  - `submitReport` writes a doc to `reports/` with all required fields and `status == "new"`.
  - `submitReport` writes a copy to `users/me/reportedUsers/{reportId}` with the same auto-id in the same batch.
  - `watchMyReports` emits list ordered by `createdAt desc`.
  - Cannot submit a report against yourself (controller-level guard).
- `test/features/safety/blocked_users_screen_test.dart` — pumps the screen with seeded fake firestore, verifies row rendering, taps Unblock, confirms dialog appears, taps Confirm, asserts row is gone.
- `test/features/safety/reported_users_screen_test.dart` — empty state + populated state + reason label localization.
- `test/features/safety/report_dialog_test.dart` — Submit disabled until reason chosen, details persists in payload.

**Update (existing tests):**

- `test/features/feed/feed_repository_test.dart` — no change (repo signature unchanged).
- A new test in `test/features/feed/` for the feed provider's blocked-set filter, OR extend an existing provider-level test if one exists — verify a profile in the blocked set is excluded from the emitted list.
- `test/features/chat/chat_repository_test.dart` — no change (repo unchanged).
- Add a provider-level test confirming `matchesProvider` returns `liked.intersection(likers).difference(blocked)` and `matchThreadsProvider` therefore excludes blocked uids while preserving the underlying like edges in Firestore.
- Add a test asserting that **after a block is removed**, `matchesProvider` re-includes the previously blocked uid (because likes were never deleted) and `matchThreadsProvider` re-emits the thread.
- `test/features/profile/you_screen_test.dart` and any `settings_screen_test.dart` if present — confirm Safety section renders and rows navigate.

**Convention to follow:** the project's existing tests pattern using `FakeFirebaseFirestore` (see `test/features/feed/likes_repository_test.dart` and `test/features/feed/feed_repository_test.dart`). No mocks for Firestore; only `firebase_auth_mocks` for auth.

## 11. Manual QA Checklist

Run on a real device or emulator with two test accounts (A blocker, B target).

- [ ] **Block from profile detail:** A opens B's profile, taps overflow → Block → Confirm. Toast shown. B disappears from A's Discover within ~1s.
- [ ] **Block from chat:** A and B are connected and have an active chat. A opens chat, taps overflow → Block → Confirm. Chat thread vanishes from A's Chats list. Reopening the chat by deep link shows the blocked banner and a disabled send bar.
- [ ] **Block preserves likes:** Verified through Firestore console — all four like docs (`likes/A/liked/B`, `likes/B/liked/A`, `likedBy/A/from/B`, `likedBy/B/from/A`) are **untouched** after block. The block writes only `users/A/blockedUsers/B`.
- [ ] **Block preserves chat history:** `chats/{chatId}` and all `messages/` subcollection docs are untouched.
- [ ] **Discover filter:** B continues to publish; A never sees B in `/app/feed`.
- [ ] **Liked-You filter:** B previously liked A. After A blocks B, B no longer appears in A's Liked-You list (filter applied at provider/screen level, not by deleting the like edge).
- [ ] **Settings → Safety → Blocked users:** Shows B with the photo and age denormalized at block time, even after B deletes their account.
- [ ] **Unblock restores everything:** Tap Unblock on B's row → dialog → Confirm. Toast shown. Within ~1s of confirm: B reappears in A's Discover, the original chat thread reappears in A's Chats with full message history, and B reappears in A's Liked-You list (if B's like edge still exists). No relike required.
- [ ] **Report from profile detail:** A opens B's profile → Report → choose reason → Submit. Toast shown. Verify in Firestore console: a `reports/{auto-id}` doc with reason, source: "profile", chatId absent. Verify `users/A/reportedUsers/{same-id}` exists.
- [ ] **Report from chat:** Same as above with `source: "chat"` and `chatId` populated.
- [ ] **Report Submit disabled** until a reason is selected.
- [ ] **Settings → Safety → Reported users:** Shows the reports A submitted with localized reason labels.
- [ ] **Korean locale:** Switch device locale to Korean. All new strings render in Korean (no English fallbacks).
- [ ] **Senior tap targets:** All overflow menu items, dialog buttons, and unblock buttons are at least 44×44 logical px. Ratio looks correct on a small phone.
- [ ] **Cannot self-report or self-block:** Open own profile path `/profile/<myUid>` (deep link); no overflow menu shows safety actions, or actions are no-ops.
- [ ] **Offline behavior:** Toggle airplane mode and try to block — graceful failure toast, no app crash.

## 12. Risks And Things To Watch

1. **Firestore rule regression.** New rule blocks could shadow existing matches if placed below the catch-all. Always place new `match` blocks above the final `match /{document=**}`. Test rule changes with the Firebase emulator before deploying (deployment is out of scope for this sprint, but the rule edit lands on `main`).
2. **Filter completeness.** Because no data is deleted, every consumer of like/match data must explicitly subtract the blocked set, or a blocked user will leak through. The audit list: `feedProvider`, `matchesProvider`, `matchThreadsProvider`, `LikedYouScreen`, plus any future surface that derives from `likedByMeProvider` / `likedByOthersProvider`. Add a comment near `blockedSetProvider` listing the consumers that must apply the filter, so a future contributor knows where to plug in when adding a new like-derived view.
3. **Stale `matchThreadsProvider` subscriptions.** The provider opens a chat-message subscription per match. If a uid is blocked while subscribed, the listener should be canceled, not just filtered out — otherwise it leaks until app restart. Fix by including the blocked set in the dependency graph and re-running the init pass when it changes.
4. **Senior UX: confirmation hygiene.** Block is reversible but still consequential (chats vanish, contact appears severed). Always require a confirmation dialog and use copy that emphasizes reversibility, so users do not avoid the feature out of fear of breaking something.
5. **Deep links to blocked users.** A could still navigate to `/profile/<blockedUid>` or `/chat/<blockedUid>` via a stale link. Profile view continues to load — Firestore rules still allow read of any published profile — but the overflow menu should swap "Block" for "Unblock" when the target is already in `blockedSetProvider`. Implement consistently across both surfaces.
6. **Reverse-block not enforced.** If B blocks A, A can still see B in Discover, like B, and message B (provided existing matches). This is a known limitation and is documented as out of scope. If product wants symmetric blocking later, the path is a Cloud Function or a public reverse `blockedBy/{uid}` index.
7. **Reports cannot be deleted by the user.** This is intentional but should be flagged in the Reported users screen (e.g. "Reports cannot be undone.") to set expectations.
8. **Localization completeness.** The CI/lint config does not (yet) catch missing Korean ARB keys. Manually diff `app_en.arb` and `app_ko.arb` after editing.
9. **Existing widget tests.** `you_screen_test.dart` and `settings_language_row_test.dart` may break if they assert exact `_SettingsCard` row counts or section order. Update assertions, do not weaken them.
10. **`flutter gen-l10n` regeneration.** Generated files (`app_localizations*.dart`) must be regenerated after every ARB change. Add `flutter gen-l10n` to the per-task verify step.
11. **Future hard-delete migration.** If product later decides to delete likes on block, the migration must (a) add a confirmation flow that warns about data loss, and (b) decide what to do with already-blocked users from this sprint — leave them alone or retroactively delete their like edges. Capturing this here so the deferral is explicit and doesn't get rediscovered as a surprise later.

## 13. Suggested Implementation Order

Execution order (each is a separate task, runnable independently after its predecessors):

1. **Models:** `BlockedUser`, `ReportEntry`, `ReportReason` enum.
2. **`BlockRepository` + tests** — `block(currentUid, target)` writes only the block doc; `unblock` deletes only the block doc; both idempotent; tests assert that seeded like edges and chat docs are untouched after block/unblock; `watchBlockedSet`, `watchBlockedList`.
3. **`ReportRepository` + tests** — submit (top-level + history copy in one batch); watchMyReports.
4. **Providers** in `lib/features/safety/providers/safety_providers.dart` — `blockedSetProvider`, `blockedListProvider`, `myReportsProvider`, `BlockController`, `ReportController`.
5. **Discover filter wiring** — modify `feedProvider` to subtract `blockedSetProvider` (after the existing liked-set merge). Add provider-level test that asserts a blocked uid is excluded.
6. **Match-set filter wiring** — modify `matchesProvider` in `lib/features/chat/providers/chats_provider.dart` to compute `liked.intersection(likers).difference(blocked)`. `matchThreadsProvider` inherits the change. Cancel any in-flight chat-message subscriptions for newly-blocked uids inside the existing `initFor` / dispose machinery so listeners don't leak. Add provider-level tests for both blocking (thread vanishes) and unblocking (thread re-emerges with prior state because likes were never deleted).
7. **Liked-You filter wiring** — filter `likedByOthersProvider` consumers in `LikedYouScreen` (or via a small derived `unblockedLikersProvider`) so blocked users do not surface as recent likers. Update the existing `likes_controller_test` / liked-you tests if needed.
8. **Block confirmation dialog** widget + tests. Copy emphasizes reversibility.
9. **Unblock confirmation dialog** + tests. Copy emphasizes that chats and connections come back.
10. **Report dialog** (bottom sheet) widget + tests.
11. **`SafetyActionSheet`** (Block / Report / View profile) widget — composes the dialogs. Switches "Block" → "Unblock" when the target is already in `blockedSetProvider`.
12. **Profile detail integration** — overflow menu opens `SafetyActionSheet`. Widget test for both block and unblock paths.
13. **Chat screen integration** — overflow menu, blocked banner, disabled send bar. Banner reads `chatBlockedBanner`. Widget test asserts that the send button is disabled and the `TextField` is read-only when the counterpart is blocked, and that history remains visible.
14. **`BlockedUsersScreen`** + tests — list rows + Unblock row action wired to the unblock dialog.
15. **`ReportedUsersScreen`** + tests — read-only list, localized reason labels.
16. **Settings Safety section** + router routes (`/settings/blocked`, `/settings/reported`). Widget test.
17. **Localization** — add all keys to both ARB files, run `flutter gen-l10n`, verify all callers compile. Manual diff between `app_en.arb` and `app_ko.arb` to catch missing keys.
18. **Firestore rules** — edit `firestore.rules` per §4. Do **not** deploy. Add a comment in the PR description telling the deploying operator: "Run `firebase deploy --only firestore:rules` after merging."
19. **Manual QA** per §11 on a device, then sweep §12 risks 2 and 3 with the audit list — touch every consumer of `likedByMeProvider` / `likedByOthersProvider` and confirm a blocked user is filtered out. File any follow-ups before merging.

This ordering keeps every prefix shippable: tasks 1-4 are pure data/provider plumbing testable with `FakeFirebaseFirestore`; tasks 5-7 fully wire the filter layer; tasks 8-11 build reusable UI primitives; tasks 12-13 deliver the user-visible block/report actions; tasks 14-16 deliver the Settings hub; rules and QA close out the sprint.

## 14. Suggested Commit Message

For the squashed merge to `main`:

```
feat(safety): add block, report, and Settings → Safety hub

Lets users block and report each other from Profile and Chat. Blocked users
are hidden from Discover, the Liked-You list, and the Chats list, and the
chat screen disables sending with a clear banner. Block is purely a filter
layer — likes, matches, and chat history are preserved, so unblock fully
restores every connection. A new Settings → Safety section lists blocked
users (with unblock) and the user's own report history.

Reports go to a top-level reports/ collection (admin-only, future-readable
by a moderation tool) plus a per-user reportedUsers history copy that is
self-readable.

Adds Firestore rules for blockedUsers, reports, and reportedUsers. Rules
are NOT deployed by this commit — operator must run firebase deploy
--only firestore:rules to activate.

en + ko localization included.
```

For per-task commits during implementation, use Conventional Commits:

- `feat(safety): add BlockedUser model`
- `feat(safety): add BlockRepository`
- `feat(safety): wire blocked set into Discover`
- `feat(safety): add Report dialog`
- `feat(safety): add Settings → Safety section`
- `chore(rules): add block/report Firestore rules (not deployed)`
- `chore(l10n): add safety strings (en + ko)`
