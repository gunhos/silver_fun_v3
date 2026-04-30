# Silvers Fun — Senior Polish Sprint

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebrand the user-facing app from "Kindred" to "Silvers Fun," soften match/dating language to a senior-friendly companionship tone, refresh the interest pool for adults 65+, add a simple in-chat safety reminder, and bump readability (body text size, button size, muted-text contrast) — all via copy/UI-only edits.

**Architecture:** Pure presentation-layer sprint. No Firestore schema changes, no new routes, no new providers, no new repositories. Internal Dart symbols using "match" (e.g. `MatchThread`, `matchesProvider`, `matchThreadsProvider`, `_MatchCard`, `_MatchBubble`) are intentionally left alone — they are not user-visible and renaming them risks broad breakage for zero user benefit.

**Tech Stack:** Flutter 3.x · existing app — no new dependencies.

---

## Sprint goal

Make Silvers Fun feel like a safe, friendly companionship app for adults 65+ on first launch:

- The app says "Silvers Fun" everywhere a user can see it.
- Tagline and onboarding copy invite friendship, not dating.
- Interest chips look like things a 65+ user would pick.
- The first thing a user sees in any chat thread is a one-line safety reminder.
- "It's a match!" and "Matched" are replaced with "connection" / "friend" language.
- Body text and primary buttons are noticeably easier to read.
- The existing app keeps working; no regressions in feed, likes, chats, onboarding, or settings.

## Non-goals

- No package rename (`name: silver_fun` in `pubspec.yaml` stays — renaming the Dart package would require rewriting every `package:silver_fun/...` import).
- No internal symbol rename (`MatchThread`, `matchesProvider`, etc. stay).
- No Firestore schema changes (collections, fields, security rules untouched).
- No minimum-age change (still 18+ at the validator level — copy will signal 65+ target audience but won't block younger sign-ups). Logged in Risks for follow-up.
- No new features: no ID verification, no calling/voice/video, no GPS/location, no payments, no moderation dashboards, no family-helper accounts.
- No new icons, logos, or splash artwork (existing pink heart icon stays).
- No deep theme overhaul — only the targeted readability bumps below.

## Files likely to edit

Branding & metadata
- `pubspec.yaml` — `description`
- `web/index.html` — `<title>`, meta description, `apple-mobile-web-app-title`
- `web/manifest.json` — `name`, `short_name`, `description`
- `lib/main.dart` — `MaterialApp.title`, class rename `KindredApp` → `SilversFunApp`

User-facing copy
- `lib/features/auth/screens/sign_in_screen.dart` — wordmark + tagline
- `lib/features/onboarding/screens/name_age_screen.dart` — age helper line
- `lib/features/chat/screens/chat_screen.dart` — header subtitle, fallback name, match-card text + safety line
- `lib/features/chat/screens/chat_list_screen.dart` — empty state, hint, "Say hi to a match"
- `lib/features/feed/providers/likes_provider.dart` — match toast text

Interest pool
- `lib/core/constants.dart` — `kInterestPool`

Readability
- `lib/core/theme/app_colors.dart` — `muted` darker for contrast
- `lib/core/theme/app_theme.dart` — bump body font sizes
- `lib/core/widgets/btn.dart` — taller button, larger label
- `lib/core/widgets/chip_tag.dart` — slightly larger chip text

Tests
- `test/core/widgets/toast_overlay_test.dart` — string used in test no longer says "match"

---

## Step-by-step implementation tasks

### Task 1 — Branding & metadata

- [ ] **1.1** Edit `pubspec.yaml` line 2:
  - From: `description: "Kindred — a social discovery app."`
  - To: `description: "Silvers Fun — a friendly companionship app for adults 65+."`

- [ ] **1.2** Edit `web/index.html`:
  - Line 21 (`<meta name="description" content="A new Flutter project.">`) → `<meta name="description" content="Silvers Fun — friendly companionship for adults 65+.">`
  - Line 26 (`apple-mobile-web-app-title` content) → `Silvers Fun`
  - Line 32 (`<title>silver_fun</title>`) → `<title>Silvers Fun</title>`

- [ ] **1.3** Edit `web/manifest.json`:
  - `"name": "silver_fun"` → `"name": "Silvers Fun"`
  - `"short_name": "silver_fun"` → `"short_name": "Silvers Fun"`
  - `"description": "A new Flutter project."` → `"description": "Silvers Fun — friendly companionship for adults 65+."`

- [ ] **1.4** Edit `lib/main.dart`:
  - Rename class `KindredApp` → `SilversFunApp` (lines 17, 18; also update reference on line 14 inside `runApp(...)`).
  - Change `title: 'Kindred'` (line 24) → `title: 'Silvers Fun'`.

- [ ] **1.5** Run `flutter analyze` and confirm no new issues. Run `flutter test` and confirm all tests still pass (no test currently imports `KindredApp`).

### Task 2 — Sign-in screen rebrand + tagline

- [ ] **2.1** Edit `lib/features/auth/screens/sign_in_screen.dart`:
  - Line 50 (`'Kindred'`) → `'Silvers Fun'`
  - Line 58 (`'Find your kindred spirits.'`) → `'Friendly company for the next chapter.'`

- [ ] **2.2** Pump app or run a focused test if present; visually confirm the sign-in screen reads "Silvers Fun" and the new tagline.

### Task 3 — Onboarding copy

- [ ] **3.1** Edit `lib/features/onboarding/screens/name_age_screen.dart` line 122:
  - From: `'You must be 18 or older to use Kindred.'`
  - To: `'Silvers Fun is built for adults 65+. You must be 18 or older to sign up.'`

  (Validator stays at `a >= 18` in `OnboardingFormState.isNameAgeValid` — see Risks.)

### Task 4 — Senior-friendly interest pool

- [ ] **4.1** Replace the entire body of `lib/core/constants.dart` with a 24-item senior-friendly pool. Note: `Coffee` and `Reading` are kept because `test/features/profile/you_screen_test.dart` builds a fixture profile with those interests — keeping them in-pool means the test stays meaningful.

  ```dart
  const List<String> kInterestPool = [
    'Gardening',
    'Walking',
    'Cooking',
    'Baking',
    'Coffee',
    'Travel',
    'Reading',
    'Photography',
    'Yoga',
    'Bird watching',
    'Crafts',
    'Knitting',
    'Board games',
    'Cards & bridge',
    'Movies',
    'Theatre',
    'Art',
    'Live music',
    'Dancing',
    'Volunteering',
    'Grandkids',
    'Dogs',
    'Cats',
    'Plants',
  ];
  ```

- [ ] **4.2** Run `flutter test test/` — `you_screen_test.dart` still passes (it doesn't depend on the pool order, just on `Coffee` / `Reading` being valid chip labels — both kept).

### Task 5 — Soften match/dating language in chats

- [ ] **5.1** Edit `lib/features/chat/screens/chat_screen.dart`:
  - Line 192 (`name.isEmpty ? 'Match' : name`) → `name.isEmpty ? 'Friend' : name`
  - Line 200 (`'Matched'`) → `'Connected'`
  - Line 286 (`"It's a match! 🎉"`) → `"You're now connected! 🎉"`
  - Lines 293–295: keep the conditional but soften — replace:
    ```dart
    name.isEmpty
        ? 'Say hi to start the conversation.'
        : 'Say hi to $name to start the conversation.',
    ```
    with:
    ```dart
    name.isEmpty
        ? 'Say hello to start chatting.'
        : 'Say hello to $name to start chatting.',
    ```

- [ ] **5.2** In the same file, add a one-line safety reminder inside `_MatchCard` directly under the existing subtitle Text. Insert after the closing `)` of the subtitle Text (around line 297, inside the inner `Column`'s `children:`):

  ```dart
  const SizedBox(height: 10),
  Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(
        Icons.shield_outlined,
        size: 16,
        color: AppColors.muted,
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          'Stay safe — never share personal info, passwords, or money.',
          style: text.bodySmall?.copyWith(color: AppColors.muted),
        ),
      ),
    ],
  ),
  ```

  This banner now appears at the top of every chat thread (the `_MatchCard` is always inserted as item 0 in `_MessagesList.itemBuilder`, line 234), so every conversation surfaces the reminder.

- [ ] **5.3** Edit `lib/features/chat/screens/chat_list_screen.dart`:
  - Line 267 (`'Say hi to a match'`) → `'Say hello to a new connection'`
  - Line 272 (`'Tap a match above to start a conversation.'`) → `'Tap a friend above to start a conversation.'`
  - Line 294 (`'No matches yet.'`) → `'No connections yet.'`

- [ ] **5.4** Edit `lib/features/feed/providers/likes_provider.dart` line 62:
  - From: `name.isEmpty ? "It's a match! 🎉" : "It's a match with $name! 🎉",`
  - To: `name.isEmpty ? "You're now connected! 🎉" : "You and $name are now connected! 🎉",`

- [ ] **5.5** Edit `test/core/widgets/toast_overlay_test.dart` lines 63 and 66:
  - Replace `"It's a match!"` (both occurrences) with `"You're now connected!"`
  - The test asserts the overlay renders whatever string is set, so the new copy keeps the test meaningful and aligned with the production string.

- [ ] **5.6** Run `flutter test test/core/widgets/toast_overlay_test.dart` — passes.

### Task 6 — Readability bumps

- [ ] **6.1** Darken muted text in `lib/core/theme/app_colors.dart` line 9:
  - From: `static const Color muted = Color(0xFF6F6A99);`
  - To: `static const Color muted = Color(0xFF544F7C);`

  (Bumps contrast against the lavender bg `#F2EEFF` from ~3.6:1 to ~6.7:1 — clears WCAG AA for normal body text.)

- [ ] **6.2** In `lib/core/theme/app_theme.dart`, enlarge body styles. Replace lines 25–28:

  ```dart
  bodyLarge: body.bodyLarge?.copyWith(color: AppColors.ink),
  bodyMedium: body.bodyMedium?.copyWith(color: AppColors.ink),
  bodySmall: body.bodySmall?.copyWith(color: AppColors.muted),
  labelLarge: body.labelLarge?.copyWith(color: AppColors.ink),
  ```

  With:

  ```dart
  bodyLarge: body.bodyLarge?.copyWith(color: AppColors.ink, fontSize: 18),
  bodyMedium: body.bodyMedium?.copyWith(color: AppColors.ink, fontSize: 16),
  bodySmall: body.bodySmall?.copyWith(color: AppColors.muted, fontSize: 14),
  labelLarge: body.labelLarge?.copyWith(color: AppColors.ink, fontSize: 16),
  ```

- [ ] **6.3** Make primary `Btn` taller and louder. In `lib/core/widgets/btn.dart`:
  - Line 46 (`height: 54`) → `height: 60`
  - Line 67 (`fontSize: 16`) → `fontSize: 18`

- [ ] **6.4** Bump chip readability in `lib/core/widgets/chip_tag.dart` line 28:
  - From: `final fontSize = isSm ? 12.0 : 14.0;`
  - To: `final fontSize = isSm ? 14.0 : 16.0;`

- [ ] **6.5** Run `flutter analyze` and `flutter test` — both clean.

### Task 7 — Final verification

- [ ] **7.1** Run `flutter test` from the repo root. Confirm all existing tests still pass (`test/core/`, `test/features/`, `test/models/`).

- [ ] **7.2** Run `flutter analyze`. Confirm zero issues introduced.

- [ ] **7.3** `flutter run` (or web build) and walk the manual QA checklist below.

- [ ] **7.4** Commit using the suggested commit message.

---

## Acceptance criteria

- `flutter analyze` reports no new issues.
- `flutter test` is fully green.
- The string "Kindred" (case-insensitive) does not appear in any user-visible surface — verified by `grep -ri 'kindred' lib/ web/ pubspec.yaml` returning no hits in user-facing strings (the historical plan file under `docs/` may still mention it; that is acceptable).
- Sign-in screen displays "Silvers Fun" wordmark and the new tagline.
- Onboarding interests screen shows the new senior-friendly chip pool (Gardening, Walking, Bird watching, Cards & bridge, Knitting, Grandkids, etc.).
- A new chat thread shows "You're now connected! 🎉" plus a single shield-icon safety line above the message field.
- Chat list empty / "no conversations yet" copy uses "connection" / "friend," not "match."
- The mutual-like toast says "You and {name} are now connected! 🎉" (or the no-name fallback "You're now connected! 🎉").
- Body text on the discover feed, profile view, and chat is visibly larger than before; the primary button is taller (60px) with 18px label.

## Manual QA checklist

Run on a phone-sized window after `flutter run`.

- [ ] Cold launch with no auth → sign-in screen shows "Silvers Fun" and "Friendly company for the next chapter."
- [ ] Sign in with a fresh account → name screen helper text reads "Silvers Fun is built for adults 65+. You must be 18 or older to sign up."
- [ ] Photo step → still works (no copy change there, just confirm no regression).
- [ ] Bio step → still works.
- [ ] Interests step → 24 chips visible, includes Gardening / Walking / Bird watching / Cards & bridge / Knitting / Grandkids; selecting 3–6 still enables Continue.
- [ ] Preview → publishes successfully; lands in Discover.
- [ ] Discover feed → cards readable, name/age and chips visible, heart button still toggles.
- [ ] Like a profile that already liked you → toast reads "You and {name} are now connected! 🎉".
- [ ] Open Chats tab → if no threads, empty state says "No connections yet."; if threads exist with no messages, hint says "Say hello to a new connection" / "Tap a friend above to start a conversation."
- [ ] Open a chat thread → top card says "You're now connected! 🎉" with the "Stay safe — never share personal info, passwords, or money." line below; header subtitle reads "Connected"; fallback name (if profile name empty) reads "Friend."
- [ ] Send a message → still posts; mark-read still fires.
- [ ] You tab → status pill, bio card, and chips all render with the larger body text without clipping.
- [ ] Settings → toggle Pause profile still works; copy unchanged here.
- [ ] Sign out → returns to sign-in screen showing the new branding.
- [ ] Web build (`flutter run -d chrome`) → browser tab title reads "Silvers Fun".

## Suggested commit message

```
feat: rebrand to Silvers Fun and soften copy for senior audience

- Rename user-visible app from Kindred to Silvers Fun (sign-in,
  onboarding helper, MaterialApp title, web title/meta/manifest,
  pubspec description, KindredApp -> SilversFunApp).
- Replace dating-coded "match" copy with "connection" / "friend"
  in chat header, chat list, mutual-like toast, and the in-thread
  banner card.
- Add a one-line safety reminder above every chat thread.
- Refresh kInterestPool with senior-friendly options (Gardening,
  Walking, Bird watching, Cards & bridge, Knitting, Grandkids, ...).
- Bump readability: body text 14/16 -> 16/18, primary button
  54px/16pt -> 60px/18pt, chip text 12/14 -> 14/16, muted color
  darkened from #6F6A99 to #544F7C for WCAG AA contrast.
- No schema, route, repository, or provider changes.
```

## Risks / things to watch

- **Layout regressions from larger text.** Bumping `bodyLarge` to 18 and `bodyMedium` to 16 ripples through every screen. Watch for two-line clipping on the feed grid (`_ProfileCard` chip row is height-constrained at 28px — Task 6.4's larger chip font may push that). Manual QA the feed grid first; if chips clip, raise the `SizedBox(height: 28)` in `lib/features/feed/screens/feed_screen.dart` line 148 to 34. Not pre-changed here because we want a real visual check first.
- **Internal "match" symbols are intentionally untouched.** `MatchThread`, `matchesProvider`, `matchThreadsProvider`, `_MatchCard`, `_MatchBubble` stay. If a future sprint wants full naming consistency, do it as a dedicated rename PR — it touches `chats_provider.dart`, `chat_list_screen.dart`, `chat_screen.dart`, `main_shell.dart`, and the `main_shell_test.dart` import. Out of scope for this sprint.
- **Min-age validator still at 18.** The copy now signals 65+ target audience but `OnboardingFormState.isNameAgeValid` (`lib/features/onboarding/notifiers/onboarding_form_notifier.dart:22`) still allows 18+. If product wants a hard 65+ floor, that's a follow-up sprint — bumping the validator changes test fixtures (`you_screen_test.dart` uses age 31) and may require migration messaging for any existing under-65 users.
- **Safety reminder placement is per-thread, not global.** It's repeated above every chat. If that becomes noisy, a future iteration can move it to a one-time-per-thread dismissible banner (would require a new `seenSafetyReminderAt` field on the user — schema change, deliberately deferred).
- **`muted` color change is global.** Every `AppColors.muted` consumer gets darker text. Visually verify status pill on the You screen, settings subtitle text, and chat-bubble timestamps still feel right against white surfaces.
- **Web manifest `name` change.** PWA installers may keep the old name on already-installed instances until reinstall. Acceptable for a pre-release app.
- **Historic plan file** `docs/superpowers/plans/kindred_implementation_plan.md` still references "Kindred." That's documentation of past work, intentionally untouched.
