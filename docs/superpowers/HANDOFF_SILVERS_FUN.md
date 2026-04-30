# Silvers Fun — Post-Sprint Handoff

_Written 2026-04-30. Read this before touching code or distributing builds._

---

## 1. Current app status

- **Branch state:** Phases 1–7 of the original implementation plan are merged. The `senior-polish-sprint` rebrand and copy/readability sprint is merged on top.
- **User-facing brand:** **Silvers Fun.**
- **Internal package name (unchanged):** `dev.mathminds.silver_fun`. Pubspec name: `silver_fun`. Don't rename either — many imports and the Firebase Android app registration depend on them.
- **Verification at hand-off:** `flutter analyze` clean, `flutter test` 65/65 green.
- **Platforms:** Android primary, web works for QA. iOS is NOT configured (no `GoogleService-Info.plist`, no Podfile auth setup).

---

## 2. Completed features

| Area | What works |
|---|---|
| Auth | Google sign-in via `google_sign_in` + `FirebaseAuth`; sign-out from Settings |
| Router | `RouterNotifier` redirects unauthed → `/signin`, authed+unpublished → `/onboarding/name`, authed+published → `/app/feed` |
| Onboarding | 4-step flow (name+age → photo → bio → interests) → preview → publish; each step writes incrementally to Firestore |
| Discover | Live `users` feed, 2-column grid, heart toggle, mutual-like toast, profile-paused users excluded |
| Likes | Forward (`likes/{from}/liked/{to}`) + reverse (`likedBy/{to}/from/{from}`) indices written atomically |
| Liked you tab | Reverse-index list with unread badge |
| Chat | Mutual-match threads, real-time messages, deterministic `chatId`, unread counts, mark-read on open |
| Profile tab | You screen, standalone Edit Bio (`/edit-bio`), Settings with Pause Profile + Sign out |
| Shell | Bottom nav with badge counts, top toast overlay |
| Branding | "Silvers Fun" wordmark, sign-in tagline, onboarding age helper, web title/manifest |
| Tone | "match" copy → "connection"/"friend"/"connected" in chat header, list, toast, welcome card |
| Safety | Shield-icon reminder line at the top of every chat thread |
| Interests | 24-item senior-friendly chip pool |
| Readability | Body 16/18, primary button 60px @ 18pt, chips 14/16, muted `#544F7C` (WCAG AA) |

---

## 3. Firebase project / config notes

| Setting | Value |
|---|---|
| Firebase project ID | **`silver-fun-v2`** |
| Project number | `703995993998` |
| Storage bucket | `silver-fun-v2.firebasestorage.app` |
| Registered Android package | `dev.mathminds.silver_fun` |
| Registered SHA-1 (debug) | `02:57:D4:2F:D5:E7:18:79:FD:B1:E1:3B:C6:22:F1:4F:2D:FB:07:EC` (one fingerprint registered as of hand-off) |
| `firebase_options.dart` | Generated, committed, points at `silver-fun-v2` |
| `android/app/google-services.json` | Committed. Contains residual entries for `com.example.firebase_auth_flutterfire_ui` and `com.example.silver2` — harmless cruft from earlier setups |

**Anyone running on a new dev machine needs their own debug-keystore SHA-1 added to the Firebase Android app, then a refreshed `google-services.json`.** Without that, Google sign-in returns `ApiException: 10 (DEVELOPER_ERROR)`.

---

## 4. Deployed rules status

Both rule files are deployed via `firebase deploy --only firestore:rules,storage` (see `firebase.json`).

**Firestore (`firestore.rules`):**
- `users/{uid}` — owner-only writes; readable if owner OR `published == true`.
- `likes/{from}/liked/{to}` — owner-only writes; readable by `from` and `to`.
- `likedBy/{to}/from/{from}` — owner-only writes; readable by `to` and `from`.
- `chats/{chatId}` and `chats/{chatId}/messages/{id}` — only chat participants (uids found in `chatId.split('_')`); messages must have `senderId == auth.uid`; deletes denied.
- Default deny on all other paths.

**Storage (`storage.rules`):**
- `profile-photos/{file}` — readable by any signed-in user; writeable only when `file == auth.uid + '.jpg'`, `< 5 MB`, content-type `image/*`.
- Default deny everywhere else.

To re-deploy: `firebase deploy --only firestore:rules` or `--only storage`.

---

## 5. Known minor issues / polish backlog

Tracked, not urgent. None block student distribution.

- **Settings has placeholder rows** that look tappable but do nothing: `Edit profile photo`, `Who can see me`, `Privacy`, `Help`. The two `Notifications` toggles (`New likes`, `Weekly digest`) are `_UiOnlyToggleRow` — visual only, no persistence.
- **Min-age validator is 18+** even though copy says "Designed for adults 65+." Intentional for now; tighten when product decides.
- **Chat safety reminder shows on every thread visit.** Could become one-time-per-thread (would add a `seenSafetyAt` field; deferred to avoid schema change).
- **Internal Dart symbols still say "match"** (`MatchThread`, `matchesProvider`, `matchThreadsProvider`, `_MatchCard`, `_MatchBubble`, `_MatchBubblesRow`). User-invisible; rename only if a future sprint wants full naming consistency.
- **Web manifest theme colors** still `#0175C2` (Flutter default blue), not the lavender/coral palette. Cosmetic.
- **`README.md` is the Flutter default** ("A new Flutter project."). Replace when the project goes public.
- **iOS not configured.** Code is iOS-compatible but missing `GoogleService-Info.plist`, Podfile auth setup, and URL schemes for `google_sign_in`.
- **`google-services.json` cruft.** Two leftover Android client entries from earlier app IDs — safe to ignore, can be cleaned up next time the file is regenerated via `flutterfire configure`.

---

## 6. Two-device QA checklist

Run with two real devices (or one device + one emulator) signed in to **different Google accounts**. Both must have their debug SHA-1 registered (see §8).

**Setup**
- [ ] Device A: fresh install → Google sign-in → onboarding (name, age, photo, bio, interests) → publish.
- [ ] Device B: fresh install → same as above with a different account, name, photo.

**Discover & like**
- [ ] On A: B appears in Discover; tap card → profile view shows photo, name+age, bio, chips.
- [ ] On A: tap heart → toast `Liked {B's name}`.
- [ ] On B: A appears in Discover; tap heart → toast `You and {A's name} are now connected! 🎉`.

**Liked-you tab**
- [ ] On A: Liked-you tab badge increments to 1, A's row shows B (because B liked A back, the order shipped here may also surface in Chats — confirm both feel correct).
- [ ] On B: Liked-you tab also shows A.

**Chat**
- [ ] On both: Chats tab shows the mutual-connection bubble at top.
- [ ] Open the thread on A → top card reads "You're now connected! 🎉" with shield-icon line `Stay safe — never share personal info, passwords, or money.`
- [ ] Header subtitle says `Connected`; if profile name was missing, fallback says `Friend`.
- [ ] A sends a message → B receives in real time; B's Chats badge increments and bubble shows unread dot.
- [ ] B opens the thread → unread clears.
- [ ] B replies → A sees it; bubble alignment correct (mine right / theirs left).
- [ ] Long message wraps inside the bubble; very short message doesn't break layout.

**Pause / publish**
- [ ] A → Settings → toggle Pause profile ON → toast "Profile paused".
- [ ] B refreshes Discover → A no longer appears.
- [ ] A toggles Pause OFF → A reappears in B's feed (may take a stream tick).

**Sign-out**
- [ ] A: Sign out → returns to sign-in screen showing `Silvers Fun` wordmark.
- [ ] A: Sign back in with the same account → lands directly on Discover (profile already published).

**Readability sanity**
- [ ] Discover chips on the card render fully (no clipped "Cookina" — should read "Cooking"). Default chip row height is 34px.
- [ ] Primary buttons are tall (60px) with 18pt text — clearly thumb-sized.
- [ ] Muted text (timestamps, helper lines, chat safety) is dark enough to read on the lavender bg.

---

## 7. Student distribution checklist

For each student you onboard:

- [ ] Confirm they have **Flutter 3.x** (`flutter --version` shows ≥ 3.11.5) and Android Studio with an SDK platform installed.
- [ ] Confirm they have a Google account they can sign in with for testing.
- [ ] You (project owner) have **owner/editor access** to the `silver-fun-v2` Firebase project.
- [ ] Student runs the SHA-1 command (§8 step 2) and sends you the fingerprint over a private channel.
- [ ] You add their SHA-1 in Firebase Console → Project settings → `Silvers Fun (Android)` → Add fingerprint.
- [ ] You re-download `google-services.json` from the Firebase Console and either commit it to a `students/` branch or send it to the student over a private channel.
- [ ] Student replaces `android/app/google-services.json` with the new one (DO NOT commit their personal copy if it contains other students' SHA-1s — keep it local).
- [ ] Student runs `flutter pub get && flutter run` and confirms Google sign-in works (no `DEVELOPER_ERROR`).
- [ ] Student runs through the §6 two-device checklist with a partner.
- [ ] Student understands NOT to push their personal `google-services.json` if it differs from the committed one.

---

## 8. Exact student instructions — clone, SHA, run

Paste this into a doc you give the student.

### Step 1 — Clone and install dependencies

```bash
git clone <your-repo-url> silver_fun_v3
cd silver_fun_v3
flutter pub get
```

### Step 2 — Get your debug-keystore SHA fingerprints

The Android debug keystore is auto-created by Android Studio on first build. Default location: `~/.android/debug.keystore`.

**macOS / Linux:**

```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  -keypass android \
  | grep -E 'SHA1|SHA-256'
```

**Windows (PowerShell):**

```powershell
keytool -list -v `
  -keystore "$env:USERPROFILE\.android\debug.keystore" `
  -alias androiddebugkey `
  -storepass android `
  -keypass android `
  | Select-String -Pattern 'SHA1|SHA-256'
```

Copy both the `SHA1:` and `SHA-256:` lines. Send them to the project owner over a private channel.

### Step 3 — Wait for the project owner to register your fingerprint

The owner will:
1. Open Firebase Console → project `silver-fun-v2` → Project settings → "Your apps" → the `dev.mathminds.silver_fun` Android app.
2. Click "Add fingerprint" and paste your SHA-1.
3. Re-download the updated `google-services.json` from that page.
4. Send you the new file.

### Step 4 — Replace `google-services.json`

```bash
# Back up the committed one first (optional)
cp android/app/google-services.json android/app/google-services.json.bak

# Replace with the file the owner sent you
mv ~/Downloads/google-services.json android/app/google-services.json
```

**Do NOT commit your personal `google-services.json`** unless the owner tells you to — it may contain other students' fingerprints.

### Step 5 — Run the app

```bash
flutter pub get
flutter run
```

On first launch you should see the lavender Silvers Fun sign-in screen. Tap "Continue with Google", pick your account, and the app should land on either onboarding or the Discover feed.

If you get `PlatformException(sign_in_failed, ApiException: 10, …)`: SHA-1 isn't registered yet, or you didn't replace `google-services.json`. Re-do steps 2–4.

---

## 9. Next recommended sprint options

Pick one, in rough order of user value:

1. **Senior-polish v2 (small).** Bump min-age validator to 65 with a friendly error; clean up Settings placeholders (remove `Edit profile photo`, `Who can see me`, `Privacy`, `Help` rows OR wire them up); make chat safety reminder dismissible per-thread; rename internal `Match*` symbols to `Connection*` for consistency.
2. **Real photo management (medium).** Wire Settings → Edit profile photo to the existing image-picker pipeline; allow up to 3 photos per user (model + storage rule changes); profile carousel on Discover and profile view.
3. **iOS support (medium).** Run `flutterfire configure` for iOS, commit `GoogleService-Info.plist`, add the `REVERSED_CLIENT_ID` URL scheme to Info.plist, and verify Google sign-in on a physical iPhone.
4. **Push notifications (medium).** Add `firebase_messaging`, send a notification on new mutual connection and on new chat message; opt-out toggle in Settings (replaces the current UI-only toggle).
5. **Report / block (medium).** Long-press on a profile to report; mutual block hides both users from each other's feed and chat list. Adds `blocks/{blockerUid}/blocked/{blockedUid}` collection + rule.
6. **Web build polish (small).** Update `web/manifest.json` `theme_color`/`background_color` to the Silvers Fun palette; replace placeholder PWA icons with branded ones; replace the default `README.md`.

Each is a single-sprint scope. Brainstorm before picking — products with senior audiences often surface needs (font scaling, voice messages, family-helper accounts) that change the priority order.
