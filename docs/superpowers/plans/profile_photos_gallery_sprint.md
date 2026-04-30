# Profile Photos Gallery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let each Silvers Fun member have up to 6 profile photos, with one designated as the "main" photo used everywhere a single avatar is shown today (Discover cards, Liked-you rows, You screen, chat avatars). Other users see all photos as a swipeable carousel on the profile detail screen. Existing single-`photoUrl` accounts continue working unchanged.

**Architecture:** Minimal schema change — keep `users/{uid}.photoUrl` as the canonical "main photo" URL (so every existing read path keeps working), and add a new `users/{uid}.photoUrls: List<String>` whose first element mirrors `photoUrl`. New uploads go to `profile-photos/{uid}/{millisSinceEpoch}.jpg`; legacy `profile-photos/{uid}.jpg` remains readable. A new `EditPhotosScreen` is reachable from the You screen and Settings, and `ProfileViewScreen` swaps its single `PhotoWidget` for a new reusable `PhotoCarousel` widget. All photo gallery operations live on `ProfileRepository`. Tests use `FakeFirebaseFirestore`; storage uploads/deletions are abstracted behind injected typedefs (same pattern as the existing `OnboardingRepository`). Firestore rules unchanged; Storage rules updated **locally only** (no `firebase deploy`).

**Tech Stack:** Flutter 3.11.5+ · `cloud_firestore` 5.4 · `firebase_storage` 12.3 · `flutter_riverpod` 2.5 · `go_router` 14.2 · `image_picker` 1.1 · `flutter_image_compress` 2.3 · `cached_network_image` 3.4 · `flutter_localizations` (EN + KO) · `fake_cloud_firestore` (tests) — no new third-party deps.

---

## Sprint goal

Ship a v1 photo gallery for Silvers Fun adults 65+:

- A user can have **1–6** profile photos. The first photo (`photoUrls[0]`) is always the main photo, and `users/{uid}.photoUrl` mirrors it for backward compatibility.
- A new **Edit photos** screen, reachable from the You screen and from Settings → "Edit profile photo", lets the user add a photo (from the **camera** or the **gallery**, chosen via a bottom sheet), remove a photo, and set any existing photo as main.
- The **profile detail screen** (`/profile/:userId`) swaps its single hero image for a swipeable carousel that pages through `photoUrls` with a small dot indicator.
- The **Discover cards**, **Liked-you rows**, **You screen**, **chat list bubbles/rows**, and **chat header/match card** continue to render the single main `photoUrl` — no change to those layouts.
- **Existing accounts** that only have `photoUrl` (no `photoUrls`) keep working: the model normalizes them to a one-element gallery on read; the Edit photos screen shows their existing photo as the first/main entry.
- All new user-visible strings exist in both English and Korean ARB files.
- Firestore rules unchanged; Storage rules are extended **locally only** to permit `profile-photos/{uid}/{file}` writes by the owner (≤ 5 MB, `image/*`) while preserving read access to legacy `profile-photos/{uid}.jpg`. The user will deploy rules manually.
- The existing test suite stays green; new tests cover model normalization, repository gallery operations, and the new screen/widget.

## Non-goals

- No image cropping UI, filters, or video.
- No comments, reactions, or moderation on photos.
- No Cloud Functions (no server-side resizing, EXIF stripping, or orphan cleanup).
- No drag-and-drop reordering — set-as-main is the only reordering action in v1.
- No storage-orphan cleanup. Removing a photo from the gallery best-effort deletes its Storage object via `refFromURL().delete()`; if that fails (e.g., file already gone) we swallow the error and keep the Firestore update authoritative.
- No per-photo metadata (captions, alt text, timestamps) in v1.
- No `firebase deploy` — rules are updated in `storage.rules` locally only.
- No package rename (`name: silver_fun` in `pubspec.yaml` stays).
- No change to onboarding flow length — still a single-photo step. Multi-photo curation happens after publish via Edit photos.
- Onboarding photo step stays **gallery-only** in v1 (camera support is added only in the Edit photos screen). Surfacing camera in onboarding too is a follow-up — straightforward once the bottom-sheet pattern lands.

---

## Recommended Firestore schema

**Document:** `users/{uid}` (existing — additive change only)

| Field | Type | Required? | Notes |
|---|---|---|---|
| `photoUrl` | `String` | yes | **Main** photo URL. Empty string `''` means "no photo". Continues to be the field every existing screen reads. After this sprint, always equals `photoUrls[0]` when `photoUrls` is non-empty. |
| `photoUrls` | `List<String>` | optional (new) | All photo URLs in display order, **including the main photo at index 0**. May be missing on legacy docs that predate this sprint — the model normalizes those to `[photoUrl]` on read. New writes always set both fields. Capped at 6 client-side. |

**Why "main mirrors photoUrls[0]" instead of a separate `mainPhotoUrl` field:**

- Every existing screen and every existing test reads `photoUrl`. Keeping that field load-bearing means **no read-path code change** in Discover/Liked-you/You/Chat — they keep rendering the right image automatically as long as writes mirror `photoUrls[0]` into `photoUrl`.
- `users` documents are owner-write; the client controls both fields atomically in one `set(..., merge: true)` call, so drift is bounded to the duration of a single in-flight write.
- A future migration to a richer schema (per-photo metadata, e.g. blurhash) can rename `photoUrls` to `photos: List<Map>` without disturbing `photoUrl`.

**No Firestore rule change** is required: `users/{uid}` already restricts writes to the owner and reads to owner-or-published, which is correct for the new field. (The "Rules changes needed" section below is Storage-only.)

**No new index** is required: nothing queries by `photoUrls`.

---

## Storage path plan

**New uploads** (after this sprint): `profile-photos/{uid}/{millisSinceEpoch}.jpg`

- Per-uid sub-folder makes ownership trivially checkable in rules: `uid == request.auth.uid`.
- Millisecond timestamp filename guarantees no collision when the same user uploads two photos quickly. We pad with zeros in case Dart returns equal millis on the same tick by appending a 4-digit random suffix as a defensive guard.
- Filename format: `${DateTime.now().millisecondsSinceEpoch}_${random4digits}.jpg` — final example: `1714512345678_4291.jpg`.
- Content-type written as `image/jpeg`; size limited by client-side compression (`flutter_image_compress` `quality: 85`, `minWidth/minHeight: 800`) — same compression contract the existing onboarding uploader already enforces.

**Legacy reads:** `profile-photos/{uid}.jpg`

- Continues to be readable by any signed-in user (rule preserved for backward compat).
- No new writes are allowed to this single-segment path. Old accounts that uploaded their first photo before this sprint already have a download URL pointing at this path stored in `photoUrl`; that URL keeps working forever.

**Deletion:** when a photo is removed from the gallery, `FirebaseStorage.instance.refFromURL(url).delete()` is called best-effort. Failures are logged and ignored — the Firestore update is the source of truth.

**Why timestamps and not UUIDs:** Dart's stdlib has no UUID primitive; pulling in a UUID dependency for v1 is overkill. `millis_random4` collision odds are vanishingly small for realistic upload cadence, and the value is opaque to users.

---

## Backward compatibility plan

Existing accounts have `users/{uid}.photoUrl` set (often pointing at `profile-photos/{uid}.jpg`) and **no** `photoUrls` field. The plan keeps them functional with **zero migration**:

1. **Model layer (`UserProfile.fromFirestore`):** new normalization step.
   - Parse `photoUrl` as before.
   - Parse `photoUrls` as `List<String>` (filter out non-string and empty entries).
   - If the parsed list is empty AND `photoUrl` is non-empty → set `photoUrls = [photoUrl]`.
   - If the parsed list is non-empty AND `photoUrl` is empty → set `photoUrl = photoUrls[0]` (defensive; should not happen after this sprint but protects against partial writes).
   - If both empty → `photoUrls = const []`, `photoUrl = ''` (existing "no photo" semantics).
2. **Repository layer (every gallery write):** always writes both `photoUrl` and `photoUrls` together so the document is in canonical form after the very next save.
3. **Edit photos screen:** opens by reading `myProfileProvider` (which already streams `users/{uid}`) and calling `profile.photoUrls` — for a legacy user that's `[their existing photoUrl]`, so the screen shows their existing photo as the main entry and lets them add up to 5 more.
4. **Read paths (Discover, Liked-you, You, Chat):** unchanged. They continue to read `profile.photoUrl`. As soon as the user adds/sets a main photo via Edit photos, that field gets updated atomically alongside `photoUrls`.
5. **Storage:** legacy URLs (`https://firebasestorage.../profile-photos%2F{uid}.jpg?...`) remain valid because the legacy single-segment Storage rule keeps `read: if request.auth != null`.

**The first time** a legacy user opens Edit photos and saves any change, their document is upgraded to the new dual-field shape. Until they touch it, they remain on the legacy shape and everything still works.

---

## Recommended UX

### Profile detail screen (other user's profile, `/profile/:userId`)

- The current single hero `PhotoWidget` (square aspect ratio, 1:1) is replaced by a `PhotoCarousel` covering the same square slot.
- A horizontal `PageView` pages through `profile.photoUrls`. One photo per page, full-bleed, `BoxFit.cover`.
- Below the photo, overlaid bottom-center, a row of small dots (filled = current page, hollow = others). Hidden when `photoUrls.length <= 1`.
- Swipe left/right to advance. Tap a dot to jump (optional — v1 keeps swipe-only for simplicity; dots are non-interactive indicators).
- For legacy accounts (1 photo), the carousel renders identically to today's single image, with no dots.

### You screen (current user's profile)

- Avatar circle continues to render `profile.photoUrl` (main photo). Layout untouched.
- Add a new ghost button **"Edit photos"** below "Edit interests" / "Edit bio", routing to `/edit-photos`.
- Existing buttons stay in their current order:
  1. **Preview profile** (ghost)
  2. **Edit photos** ← **new**
  3. **Edit interests** (ghost)
  4. **Edit bio** (primary)

### Settings screen

- The existing "Edit profile photo" placeholder row (which today does nothing) becomes tappable and navigates to `/edit-photos`.
- Subtitle stays out (none today); no toggle change.

### Edit photos screen (`/edit-photos`)

- AppBar: title "Edit photos", back arrow.
- Body (scrollable):
  - 2-column `GridView` of square photo tiles (8pt gap, 16pt page padding), one per `photoUrls` entry.
    - Each tile is a `ClipRRect` with `radius=16`, full-bleed `PhotoWidget`.
    - The main photo (index 0) shows a small "MAIN" pill badge top-left (lavender accent background, white text, 11pt, 999-radius, 6pt horizontal padding).
    - Each tile has a small white circular "more" button (Material `Icons.more_horiz`) bottom-right that opens a Material bottom sheet with two actions:
      - **"Set as main"** — disabled if this is already the main photo.
      - **"Remove"** — disabled if removing this photo would leave 0 photos (the screen requires at least 1 photo to remain).
  - One trailing **"+ Add photo"** tile at the end of the grid, only when `photoUrls.length < 6`. Tapping opens a **source bottom sheet** with three rows:
    - **Take photo** (`Icons.photo_camera_outlined`) → calls `image_picker` with `ImageSource.camera`.
    - **Choose from gallery** (`Icons.photo_library_outlined`) → calls `image_picker` with `ImageSource.gallery`.
    - **Cancel** (`Icons.close`) → dismisses the sheet, no upload.
  - After the user picks a source and a photo, the same compression pipeline as onboarding runs (`flutter_image_compress`, 800×800, quality 85, JPEG) and the resulting URL is appended via `addPhoto`.
- Bottom-of-screen sticky helper text in muted style: localized "**{n} of 6 photos**" counter.
- Toast feedback after every action: "Photo added", "Photo removed", "Main photo updated".
- Loading: while a single upload is in progress, the "+ Add photo" tile shows a `CircularProgressIndicator`. The grid is otherwise interactive (other deletions/main-changes can happen during an upload).
- Errors: snackbar/toast with "Could not add photo. Please try again." or "Could not remove photo. Please try again." Errors do not roll back optimistically — for v1 the screen waits on the Firestore round-trip before updating.

### Onboarding photo step (`/onboarding/photo`)

- Unchanged for v1. Still a single-photo upload. Once published, the user can curate their gallery via Edit photos. The onboarding `savePhotoUrl` write is updated under the hood to also set `photoUrls: [url]` so newly-published accounts come up canonical.

---

## Files likely to edit

**New files:**
- `lib/core/widgets/photo_carousel.dart` — reusable PageView + dot indicator.
- `lib/features/profile/screens/edit_photos_screen.dart` — the new screen.
- `test/core/widgets/photo_carousel_test.dart` — widget tests.
- `test/features/profile/edit_photos_screen_test.dart` — widget tests.
- `test/models/user_profile_photo_urls_test.dart` — focused tests for the new normalization (alternatively folded into `test/models/user_profile_test.dart`).

**Modified:**
- `lib/models/user_profile.dart` — add `photoUrls` field with normalization, `toMap`, `copyWith`.
- `lib/features/profile/repository/profile_repository.dart` — add `addPhoto`, `removePhoto`, `setMainPhoto`. Add an injected photo uploader/deleter pair for testability.
- `lib/features/profile/providers/my_profile_provider.dart` — no change beyond what `profileRepositoryProvider` already provides; the new repo methods come along for free.
- `lib/features/onboarding/repository/onboarding_repository.dart` — `savePhotoUrl` and `publishProfile` now write both `photoUrl` and `photoUrls: [url]`. Onboarding upload path moved to the per-uid folder (`profile-photos/{uid}/{millis}.jpg`) so we have a single canonical path going forward; legacy reads still work via the legacy storage rule.
- `lib/features/feed/screens/profile_view_screen.dart` — replace the single `PhotoWidget` hero with `PhotoCarousel(urls: profile.photoUrls)`.
- `lib/features/profile/screens/you_screen.dart` — add "Edit photos" button row routing to `/edit-photos`.
- `lib/features/profile/screens/settings_screen.dart` — wire the existing "Edit profile photo" `ListTile.onTap` to push `/edit-photos`.
- `lib/core/router/router.dart` — add `GoRoute` for `/edit-photos`.
- `lib/l10n/app_en.arb`, `lib/l10n/app_ko.arb` — new strings.
- `storage.rules` — add per-uid sub-folder write rule; preserve legacy read rule.
- `ios/Runner/Info.plist` — **forward-looking only** (iOS is not currently configured per `docs/superpowers/HANDOFF_SILVERS_FUN.md` §5); add `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` strings if/when iOS is enabled. Not required to ship the Android-primary build. Plan task 12 documents the exact keys; do NOT add this task in v1 unless the user explicitly enables iOS.
- `test/models/user_profile_test.dart` — extend round-trip and parse tests for `photoUrls`.
- `test/features/profile/profile_repository_test.dart` — extend with `addPhoto`/`removePhoto`/`setMainPhoto` cases.
- `test/features/onboarding/onboarding_repository_test.dart` — assert `savePhotoUrl` and `publishProfile` write both `photoUrl` and `photoUrls`.
- `test/features/profile/you_screen_test.dart` — assert the "Edit photos" button renders.

**Untouched (intentionally):**
- `lib/features/feed/screens/feed_screen.dart` — already reads `profile.photoUrl`.
- `lib/features/profile/screens/liked_you_screen.dart` — already reads `profile.photoUrl`.
- `lib/features/chat/screens/chat_list_screen.dart`, `chat_screen.dart` — already read `profile.photoUrl`.
- `lib/features/onboarding/screens/add_photo_screen.dart` — single-photo flow, unchanged at the screen level (the underlying repo write is what changes).
- `firestore.rules` — no change needed.

---

## Localization keys needed

Add to **both** `lib/l10n/app_en.arb` and `lib/l10n/app_ko.arb`. After editing the ARB files, run `flutter gen-l10n` (or the next `flutter run` will regenerate).

| Key | English | Korean |
|---|---|---|
| `editPhotosTitle` | `Edit photos` | `사진 수정` |
| `editPhotosSubtitle` | `Add up to 6 photos. The first one is your main photo.` | `사진은 최대 6장까지 올릴 수 있어요. 첫 번째 사진이 대표 사진이에요.` |
| `editPhotosCounter` | `{count} of 6 photos` | `사진 {count} / 6장` (placeholder `count: int`) |
| `editPhotosAdd` | `Add photo` | `사진 추가` |
| `editPhotosActionTakePhoto` | `Take photo` | `사진 찍기` |
| `editPhotosActionChooseFromGallery` | `Choose from gallery` | `사진첩에서 고르기` |
| `editPhotosMainBadge` | `MAIN` | `대표` |
| `editPhotosActionSetMain` | `Set as main` | `대표 사진으로 지정` |
| `editPhotosActionRemove` | `Remove` | `삭제` |
| `editPhotosActionCancel` | `Cancel` | `취소` |
| `editPhotosCannotRemoveLast` | `You need at least one photo.` | `사진이 한 장 이상 있어야 해요.` |
| `editPhotosErrorAdd` | `Could not add photo. Please try again.` | `사진을 올리지 못했어요. 다시 시도해 주세요.` |
| `editPhotosErrorRemove` | `Could not remove photo. Please try again.` | `사진을 삭제하지 못했어요. 다시 시도해 주세요.` |
| `editPhotosErrorSetMain` | `Could not update main photo. Please try again.` | `대표 사진을 바꾸지 못했어요. 다시 시도해 주세요.` |
| `toastPhotoAdded` | `Photo added` | `사진을 추가했어요` |
| `toastPhotoRemoved` | `Photo removed` | `사진을 삭제했어요` |
| `toastMainPhotoUpdated` | `Main photo updated` | `대표 사진을 바꿨어요` |
| `youEditPhotos` | `Edit photos` | `사진 수정` |

The existing `settingsEditPhoto` key (already defined: "Edit profile photo" / "프로필 사진 바꾸기") stays unchanged — Settings still says "Edit profile photo" because the row historically referred to the main photo and seniors recognize that label. The destination just now points at the new gallery screen.

---

## Platform permissions / config (camera + gallery)

The `image_picker` 1.1 plugin already in `pubspec.yaml` supports both `ImageSource.camera` and `ImageSource.gallery`. Per the plugin's official setup docs:

### Android — no manifest changes required for v1

- `image_picker` invokes the **system camera intent** for `ImageSource.camera`. Because we never declare `<uses-permission android:name="android.permission.CAMERA"/>` in `AndroidManifest.xml`, the system camera app handles the capture itself — Android does **not** prompt for runtime camera permission and we do **not** need to wire up `permission_handler`. (If we ever declared the CAMERA permission, Android would then require us to request it at runtime; the plan deliberately keeps the manifest untouched to avoid that complexity in v1.)
- For `ImageSource.gallery`, on Android 13+ (API 33+) `image_picker` uses the system Photo Picker, which requires no app-side permission. On older Android, the system gallery intent is used; again no manifest declaration is needed beyond what's already there.
- Reference: <https://pub.dev/packages/image_picker> "Android" section.
- **Outcome:** zero changes to `android/app/src/main/AndroidManifest.xml` for this feature.

### iOS — required only when iOS is enabled

The project is currently Android-primary (per handoff §3, iOS is not configured). When iOS is enabled in a future sprint, `ios/Runner/Info.plist` must include the two `<key>…<string>` pairs below or the app will crash the moment `pickImage(source: …)` is called:

```xml
<key>NSCameraUsageDescription</key>
<string>Silvers Fun uses your camera so you can take a profile photo.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Silvers Fun uses your photo library so you can choose a profile photo.</string>
```

These strings must also be localized for Korean once iOS ships (via an `InfoPlist.strings` file). Out of scope for this sprint — documented here so it isn't lost.

### Devices without a camera (tablets, emulators)

Calling `ImageSource.camera` on a device with no camera hardware results in `pickImage` either returning `null` (most cases) or throwing `PlatformException`. The screen treats both outcomes the same way: an error toast (`editPhotosErrorAdd`) and no Firestore write. This is acceptable for v1 — we don't pre-detect camera availability or hide the "Take photo" row dynamically.

---

## Rules changes needed

### `storage.rules` (LOCAL ONLY — do not run `firebase deploy`)

Replace the current `match /profile-photos/{file}` block with the two-block structure below. The legacy block keeps `profile-photos/{uid}.jpg` readable forever; the new block lets the owner write to their per-uid sub-folder.

```
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {

    // Legacy single-photo path (read-only after this sprint).
    // Existing users may still have download URLs pointing here; those URLs
    // remain valid as long as reads are allowed. New uploads go to the
    // per-uid sub-folder rule below.
    match /profile-photos/{file} {
      allow read: if request.auth != null;
      allow write: if false;
    }

    // Profile photo gallery: profile-photos/{uid}/{filename}
    match /profile-photos/{uid}/{file} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && uid == request.auth.uid
        && request.resource.size < 5 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }

    // Deny everything else.
    match /{path=**} {
      allow read, write: if false;
    }
  }
}
```

> Note: Storage path matching is segment-by-segment, so `profile-photos/{file}` only matches one-segment files (the legacy case) and `profile-photos/{uid}/{file}` only matches two-segment files (the new case) — they do not overlap.

The existing single-photo onboarding write currently relies on `file == request.auth.uid + '.jpg'`. Once we move the onboarding uploader to the new per-uid sub-folder path, that check is replaced by `uid == request.auth.uid` in the new block. **Until the user redeploys storage rules**, the new sub-folder upload will be denied at the Storage layer; this means **the new upload path requires the user to deploy storage rules before the feature can be exercised end-to-end**. Call this out in the PR description and the manual QA checklist.

### `firestore.rules`

No change. The `users/{uid}` rule already covers `photoUrls`.

---

## Tests to add/update

All tests live under `test/`. Use `FakeFirebaseFirestore` (already in dev-deps) for Firestore. Storage interactions are tested via injected uploader/deleter typedefs — there is no Firebase Storage fake.

### Unit/model tests
- `test/models/user_profile_test.dart` — extend:
  - **`fromFirestore` parses `photoUrls` when present.**
  - **`fromFirestore` synthesizes `photoUrls` from legacy `photoUrl` when `photoUrls` is missing.**
  - **`fromFirestore` returns `photoUrls: []` and `photoUrl: ''` when both are missing.**
  - **`fromFirestore` filters non-string and empty-string entries from `photoUrls`.**
  - **`toMap` writes both `photoUrl` and `photoUrls`.**
  - **`copyWith` overrides `photoUrls`.**
  - **Round-trip** preserves a 3-photo gallery.

### Repository tests (Firestore)
- `test/features/profile/profile_repository_test.dart` — extend:
  - **`addPhoto` appends to `photoUrls` and sets `photoUrl` only when no main exists yet.**
  - **`addPhoto` does not change `photoUrl` when a main is already set.**
  - **`removePhoto` removes the URL from `photoUrls`.**
  - **`removePhoto` of the main photo promotes the next photo to main (`photoUrl` becomes `photoUrls[1]`).**
  - **`removePhoto` of the only remaining photo clears `photoUrl` to `''` and `photoUrls` to `[]`.**
  - **`setMainPhoto` reorders `photoUrls` so the chosen URL is index 0 and updates `photoUrl`.**
  - **`setMainPhoto` is a no-op when the URL is not in `photoUrls`.**

- `test/features/onboarding/onboarding_repository_test.dart` — extend:
  - **`savePhotoUrl` writes both `photoUrl` AND `photoUrls: [url]`.**
  - **`publishProfile` writes both `photoUrl` AND `photoUrls: [form.photoUrl]`.**
  - Existing assertions (other fields preserved, etc.) remain unchanged.

### Widget tests
- `test/core/widgets/photo_carousel_test.dart` — new:
  - **Renders one `PhotoWidget` per URL passed.**
  - **Renders no dot indicator when only one URL is provided.**
  - **Renders N dots when N > 1 URLs are provided.**
  - **Falls back to the empty placeholder (`Icons.person`) when an empty list is passed.**

- `test/features/profile/edit_photos_screen_test.dart` — new (uses an injected fake uploader/deleter pair to avoid touching Storage):
  - **Renders a tile per photo plus an "Add photo" tile when count < 6.**
  - **Hides the "Add photo" tile when count == 6.**
  - **Shows the "MAIN" badge on `photoUrls[0]` only.**
  - **Tapping the "more" button on a non-main tile, then "Set as main", calls `setMainPhoto` with that URL.**
  - **Tapping the "more" button on a non-main tile, then "Remove", calls `removePhoto` with that URL.**
  - **Counter text reads `{count} of 6 photos`.**

- `test/features/profile/you_screen_test.dart` — extend:
  - **"Edit photos" button is rendered when profile is published.**

---

## Acceptance criteria

A reviewer should be able to verify each of these in <10 minutes:

- [ ] `flutter analyze` is clean.
- [ ] `flutter test` is green and total test count grew by ≥ 12 (model normalization + repo gallery ops + carousel widget + edit screen + you screen).
- [ ] On a fresh install with a brand-new Google account: onboarding completes with one photo; `users/{uid}` document in Firestore has both `photoUrl` and `photoUrls: [<that url>]`.
- [ ] On the same account, opening Edit photos shows the existing photo as MAIN; tapping "Add photo" adds a new tile; tapping "Set as main" on the new photo swaps the MAIN badge to it and updates `users/{uid}.photoUrl` in Firestore.
- [ ] On a **different signed-in account**, opening the first user's profile detail page shows the new main photo first; swiping reveals the second photo; the dot indicator highlights the active page.
- [ ] On a **legacy account** (one created before this sprint, with only `photoUrl`): Discover, Liked-you, You, and chat screens still render its photo. Opening Edit photos on that account shows that single photo as MAIN with no console errors.
- [ ] Storage rules file in the repo permits owner writes under `profile-photos/{uid}/{file}` and read-only legacy access at `profile-photos/{uid}.jpg`. **Rules are NOT auto-deployed** by this branch.
- [ ] Localization: switching device/app locale to Korean re-renders all new screens with Korean strings; English fallback works for all other locales.
- [ ] No regressions in existing flows: Discover, Liked you, Chat, Meetups, Settings → Pause profile, Settings → Language, Settings → Edit interests, Sign out.

---

## Manual two-device QA checklist

Run with two devices (or one device + one emulator) signed in to **different** Google accounts, both with their debug SHA-1 registered (per `docs/superpowers/HANDOFF_SILVERS_FUN.md` §8). **Before starting, deploy the updated storage rules locally with `firebase deploy --only storage`** — without this the new upload path is rejected by Storage.

**Setup**
- [ ] Device A: fresh install → Google sign-in → onboarding (name, age, photo, bio, interests) → publish.
- [ ] Device B: fresh install → same as above with a different account, name, photo.

**Single-photo carryover (backward compat)**
- [ ] On A, open the You screen. The avatar shows the photo selected during onboarding.
- [ ] In Firestore console, open `users/{A}`. Verify both `photoUrl` and `photoUrls: [<that url>]` are present.
- [ ] On B, navigate to A's profile. Carousel renders A's photo with **no** dot indicator (only one photo).

**Add a second photo via gallery**
- [ ] On A, You → "Edit photos". Existing photo shows MAIN badge.
- [ ] Tap "+ Add photo" → bottom sheet opens with three rows: **Take photo**, **Choose from gallery**, **Cancel**.
- [ ] Tap "Choose from gallery" → pick a new image → wait for upload. New tile appears at index 1 (no MAIN badge). Toast "Photo added".
- [ ] In Firestore console, `users/{A}.photoUrls` now has 2 entries; `photoUrl` is unchanged (still the original).
- [ ] On B, refresh A's profile detail. Two dots appear; swiping right shows the new photo.

**Add a third photo via camera**
- [ ] On A, Edit photos → "+ Add photo" → bottom sheet → "Take photo".
- [ ] System camera app opens (no Android runtime permission prompt expected — we use the camera intent, not the CAMERA permission).
- [ ] Capture a photo → confirm/accept in the camera app.
- [ ] Returns to Edit photos with a new tile at index 2. Toast "Photo added".
- [ ] In Firestore console, `users/{A}.photoUrls` length is now 3.

**Cancel from the source bottom sheet**
- [ ] On A, Edit photos → "+ Add photo" → bottom sheet → "Cancel".
- [ ] Sheet dismisses. No upload, no toast, no Firestore write.

**Cancel from the picker itself**
- [ ] On A, Edit photos → "+ Add photo" → "Choose from gallery" → press back without picking a photo.
- [ ] No upload, no error toast, no Firestore write. Spinner on the Add tile clears.

**Set a different photo as main**
- [ ] On A, Edit photos → tap "more" on the second photo → "Set as main".
- [ ] MAIN badge moves to the second photo. Toast "Main photo updated".
- [ ] In Firestore: `users/{A}.photoUrl` now equals the previously-second URL; `photoUrls[0]` matches.
- [ ] On B, the **Discover** card for A now shows the new main photo (may need to refresh; the stream should auto-update). Profile detail's first carousel page is the new main; swiping shows the original photo on page 2.

**Remove a photo**
- [ ] On A, Edit photos → tap "more" on the non-main photo → "Remove" → confirm.
- [ ] Tile disappears; counter reads "1 of 6 photos". Toast "Photo removed".
- [ ] In Firestore: `photoUrls` length is 1; `photoUrl` matches.
- [ ] On B, A's profile detail shows only the remaining photo; no dot indicator.

**Add up to the cap**
- [ ] On A, add photos until `photoUrls.length == 6`. The "+ Add photo" tile disappears.
- [ ] Try to add a 7th: confirm it is not possible (no Add tile).
- [ ] Counter reads "6 of 6 photos".

**Cannot remove the last photo**
- [ ] On A, remove photos one-by-one until 1 remains.
- [ ] Tap "more" on the last photo. The "Remove" action is **disabled** (greyed out).

**Settings entry point**
- [ ] On A, Settings → tap "Edit profile photo" row → lands on the same Edit photos screen.

**Localization (Korean)**
- [ ] On A, switch the language to Korean via Settings → Language.
- [ ] Edit photos screen shows Korean labels: title `사진 수정`, badge `대표`, button `사진 추가`, counter `사진 N / 6장`, more-actions sheet `대표 사진으로 지정` / `삭제` / `취소`, source sheet `사진 찍기` / `사진첩에서 고르기` / `취소`.
- [ ] Profile detail still works (carousel is non-text).

**No regressions**
- [ ] Discover grid still loads and the heart/like flow still produces the right toast.
- [ ] Liked-you list still shows rows with avatars.
- [ ] Chat list bubble row + chat header avatars still render.
- [ ] Meetups tab, Settings → Pause profile, Sign out all still work.

---

## Risks / things to watch

1. **Deploy gap on storage rules.** If a tester runs the new build against the **un-deployed** storage rules, all new uploads fail with `[firebase_storage/unauthorized]`. Surface this clearly: PR description must say "Run `firebase deploy --only storage` before testing." The Edit photos screen's error toast already covers this from the user's POV but the dev needs to know.
2. **Read-path drift between `photoUrl` and `photoUrls[0]`.** If a manual Firestore edit puts them out of sync, the model normalizer covers `photoUrl == ''` but assumes `photoUrls[0]` is canonical when both are non-empty. The repo writes always set both, so this is bounded to manual-edit pathology — acceptable for v1.
3. **Storage orphans.** When a user removes a photo, we best-effort delete the underlying Storage object. If the delete fails (network blip, already-gone file), the file lingers. There's no orphan-cleanup job in v1; budget this as a known issue.
4. **`refFromURL` on legacy URLs.** A legacy photo (single-segment path) currently lives at `profile-photos/{uid}.jpg`. After the storage rule change the legacy path becomes `write: if false`. That means we **cannot delete** a legacy photo via the new gallery — `refFromURL().delete()` will return permission denied. The Firestore update still succeeds, so from the user's POV the photo is "gone"; it just leaks one Storage object. Tolerable for the migration window. Document in the PR.
5. **`PageView` accessibility.** Seniors with reduced motor control may struggle with horizontal swipes. We do not add tap-the-dot navigation in v1 (kept for future). Profile detail still uses a tall, finger-friendly hit area; acceptable but watch user feedback.
6. **Image picker permission prompts.** First add-photo-after-onboarding triggers a fresh gallery permission prompt on iOS-style flows (we are Android-primary, but worth noting). The existing onboarding step handles this with the `XFile? null` early-return; the new screen reuses the same `image_picker` so behavior is identical.
7. **6-photo cap is hard-coded.** Defining it in one place: `const int kMaxProfilePhotos = 6;` in `lib/core/constants.dart`. If the cap changes, only that constant and the localized counter strings need to update.
8. **Multi-photo upload during a slow connection.** v1 uploads one photo at a time and shows a spinner on the Add tile. We do not allow queuing uploads. If the user double-taps "Add photo", the second tap is ignored while `_uploading` is true (same guard pattern as `add_photo_screen.dart`).
9. **Camera-capable device assumption.** Tablets and emulators without camera hardware will fail when "Take photo" is selected. v1 does not hide the camera row on cameraless devices — failures surface as a generic error toast. If product wants a cleaner experience, a follow-up sprint can probe for camera availability via `image_picker_android` / `image_picker_ios` capability APIs and conditionally render the row.
10. **iOS Info.plist crash trap.** If iOS is brought online without first adding `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` to `ios/Runner/Info.plist`, the app **terminates immediately** the first time the user taps "Take photo" or "Choose from gallery". The plan documents the strings in the platform-permissions section so the iOS-enable sprint doesn't miss them. No impact on the Android-primary build.
11. **Camera-roll vs. system camera privacy expectation.** On Android 13+, the system Photo Picker shows only photos (no metadata or full-roll access). On older Android, the system gallery intent likewise grants per-pick access. We are NOT asking for blanket photo-library permission. If product wants to add features like "pick multiple photos at once" later, that decision needs a permission-policy review — not in scope for v1.

---

## Suggested commit message

```
feat(profile): multi-photo gallery with carousel + edit screen

- UserProfile gains photoUrls (List<String>); photoUrl mirrors photoUrls[0] for backward compat.
- ProfileRepository: addPhoto, removePhoto, setMainPhoto.
- New EditPhotosScreen reachable from You and Settings; capped at 6.
- Add photo flow opens a bottom sheet: Take photo (camera) / Choose from gallery / Cancel.
- ProfileViewScreen swaps single hero for swipeable PhotoCarousel with dot indicator.
- Storage uploads move to profile-photos/{uid}/{millis_random}.jpg; legacy single-segment path stays read-only.
- storage.rules updated locally (deploy with `firebase deploy --only storage`).
- Onboarding writes both photoUrl and photoUrls: [url] going forward.
- EN + KO localization for all new strings.
- Tests: model normalization, repository gallery ops, carousel widget, edit screen.

No Firestore rules change. No Cloud Functions. No package rename.
```

---

# Step-by-step implementation tasks

> Each task is self-contained: file paths are absolute from the repo root, code blocks are complete, commands are exact. Follow TDD — write the test first, watch it fail, implement, watch it pass, commit.

---

### Task 1: Add `kMaxProfilePhotos` constant

**Files:**
- Modify: `lib/core/constants.dart`

- [ ] **Step 1: Read the existing file**

```bash
cat lib/core/constants.dart
```

Confirm it currently exports `kInterestPool` and possibly other constants.

- [ ] **Step 2: Append the constant**

Add at the bottom of the file:

```dart
/// Maximum number of profile photos a single user can have.
const int kMaxProfilePhotos = 6;
```

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze lib/core/constants.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/core/constants.dart
git commit -m "chore: add kMaxProfilePhotos constant"
```

---

### Task 2: Extend `UserProfile` model with `photoUrls` (TDD)

**Files:**
- Modify: `lib/models/user_profile.dart`
- Test: `test/models/user_profile_test.dart`

- [ ] **Step 1: Add failing tests**

Open `test/models/user_profile_test.dart` and add the following tests inside the existing `group('UserProfile', ...)` block, after the existing `'fromFirestore filters non-string interests'` test:

```dart
test('fromFirestore parses photoUrls when present', () async {
  await firestore.collection('users').doc('p1').set({
    'photoUrl': 'https://x/main.jpg',
    'photoUrls': [
      'https://x/main.jpg',
      'https://x/2.jpg',
      'https://x/3.jpg',
    ],
  });

  final doc = await firestore.collection('users').doc('p1').get();
  final profile = UserProfile.fromFirestore(doc);

  expect(profile.photoUrl, 'https://x/main.jpg');
  expect(profile.photoUrls, [
    'https://x/main.jpg',
    'https://x/2.jpg',
    'https://x/3.jpg',
  ]);
});

test('fromFirestore synthesizes photoUrls from legacy photoUrl', () async {
  await firestore.collection('users').doc('p2').set({
    'photoUrl': 'https://x/legacy.jpg',
  });

  final doc = await firestore.collection('users').doc('p2').get();
  final profile = UserProfile.fromFirestore(doc);

  expect(profile.photoUrl, 'https://x/legacy.jpg');
  expect(profile.photoUrls, ['https://x/legacy.jpg']);
});

test('fromFirestore returns empty photoUrls when both fields are missing',
    () async {
  await firestore.collection('users').doc('p3').set(<String, dynamic>{});

  final doc = await firestore.collection('users').doc('p3').get();
  final profile = UserProfile.fromFirestore(doc);

  expect(profile.photoUrl, '');
  expect(profile.photoUrls, isEmpty);
});

test('fromFirestore filters non-string and empty entries from photoUrls',
    () async {
  await firestore.collection('users').doc('p4').set({
    'photoUrl': 'https://x/main.jpg',
    'photoUrls': ['https://x/main.jpg', '', 42, null, 'https://x/2.jpg'],
  });

  final doc = await firestore.collection('users').doc('p4').get();
  final profile = UserProfile.fromFirestore(doc);

  expect(profile.photoUrls, ['https://x/main.jpg', 'https://x/2.jpg']);
});

test('fromFirestore promotes photoUrls[0] to photoUrl when photoUrl is empty',
    () async {
  await firestore.collection('users').doc('p5').set({
    'photoUrl': '',
    'photoUrls': ['https://x/2.jpg', 'https://x/3.jpg'],
  });

  final doc = await firestore.collection('users').doc('p5').get();
  final profile = UserProfile.fromFirestore(doc);

  expect(profile.photoUrl, 'https://x/2.jpg');
  expect(profile.photoUrls, ['https://x/2.jpg', 'https://x/3.jpg']);
});

test('toMap writes both photoUrl and photoUrls', () {
  const profile = UserProfile(
    uid: 'p6',
    name: 'M',
    age: 30,
    bio: 'b',
    photoUrl: 'https://x/main.jpg',
    photoUrls: ['https://x/main.jpg', 'https://x/2.jpg'],
    interests: ['Coffee'],
    city: 'NYC',
    published: true,
    profilePaused: false,
  );

  final map = profile.toMap();

  expect(map['photoUrl'], 'https://x/main.jpg');
  expect(map['photoUrls'], ['https://x/main.jpg', 'https://x/2.jpg']);
});

test('copyWith overrides photoUrls', () {
  const a = UserProfile(
    uid: 'p7',
    name: 'A',
    age: 30,
    bio: 'b',
    photoUrl: 'https://x/main.jpg',
    photoUrls: ['https://x/main.jpg'],
    interests: ['Coffee'],
    city: 'NYC',
    published: true,
    profilePaused: false,
  );

  final b = a.copyWith(photoUrls: ['https://x/main.jpg', 'https://x/2.jpg']);

  expect(b.photoUrls, ['https://x/main.jpg', 'https://x/2.jpg']);
  expect(b.photoUrl, 'https://x/main.jpg');
});
```

Also update the existing `'fromFirestore parses a fully populated document'` test to assert `profile.photoUrls` (it should equal `['https://example.com/maya.jpg']` because the seed doc has only `photoUrl`). Add this line near the other expects:

```dart
expect(profile.photoUrls, ['https://example.com/maya.jpg']);
```

And the existing `'fromFirestore applies safe defaults for missing fields'` test gains:

```dart
expect(profile.photoUrls, isEmpty);
```

And the round-trip test adds `photoUrls: ['https://example.com/j.jpg']` to the const constructor.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/models/user_profile_test.dart`
Expected: failures with messages like "Expected: ['...'] Actual: <not yet implemented>" or constructor errors complaining about missing `photoUrls` parameter.

- [ ] **Step 3: Update the model**

Replace the entire contents of `lib/models/user_profile.dart` with:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final int age;
  final String bio;

  /// Main profile photo URL. Equals `photoUrls[0]` when `photoUrls` is non-empty.
  /// Empty string means the user has no photo.
  final String photoUrl;

  /// All profile photos in display order, including the main photo at index 0.
  /// May be empty when the user has no photos.
  final List<String> photoUrls;

  final List<String> interests;
  final String city;
  final bool published;
  final bool profilePaused;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool liked;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.age,
    required this.bio,
    required this.photoUrl,
    this.photoUrls = const <String>[],
    required this.interests,
    required this.city,
    required this.published,
    required this.profilePaused,
    this.createdAt,
    this.updatedAt,
    this.liked = false,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};

    final mainUrl = (data['photoUrl'] as String?) ?? '';
    final rawList = ((data['photoUrls'] as List?) ?? const [])
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList(growable: false);

    final List<String> normalizedUrls;
    final String normalizedMain;
    if (rawList.isEmpty) {
      if (mainUrl.isEmpty) {
        normalizedUrls = const <String>[];
        normalizedMain = '';
      } else {
        normalizedUrls = <String>[mainUrl];
        normalizedMain = mainUrl;
      }
    } else {
      normalizedUrls = rawList;
      normalizedMain = mainUrl.isEmpty ? rawList.first : mainUrl;
    }

    return UserProfile(
      uid: doc.id,
      name: (data['name'] as String?) ?? '',
      age: (data['age'] as num?)?.toInt() ?? 0,
      bio: (data['bio'] as String?) ?? '',
      photoUrl: normalizedMain,
      photoUrls: normalizedUrls,
      interests: ((data['interests'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      city: (data['city'] as String?) ?? '',
      published: (data['published'] as bool?) ?? false,
      profilePaused: (data['profilePaused'] as bool?) ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'bio': bio,
      'photoUrl': photoUrl,
      'photoUrls': photoUrls,
      'interests': interests,
      'city': city,
      'published': published,
      'profilePaused': profilePaused,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  UserProfile copyWith({
    String? uid,
    String? name,
    int? age,
    String? bio,
    String? photoUrl,
    List<String>? photoUrls,
    List<String>? interests,
    String? city,
    bool? published,
    bool? profilePaused,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? liked,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      photoUrls: photoUrls ?? this.photoUrls,
      interests: interests ?? this.interests,
      city: city ?? this.city,
      published: published ?? this.published,
      profilePaused: profilePaused ?? this.profilePaused,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      liked: liked ?? this.liked,
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/models/user_profile_test.dart`
Expected: all tests pass.

- [ ] **Step 5: Run the full suite — no regressions**

Run: `flutter test`
Expected: all existing tests still pass. (None of them reference `photoUrls` yet, and the new field defaults to `const <String>[]` so existing `const UserProfile(...)` calls in test fixtures still compile.)

- [ ] **Step 6: Commit**

```bash
git add lib/models/user_profile.dart test/models/user_profile_test.dart
git commit -m "feat(profile): UserProfile.photoUrls with backward-compat normalization"
```

---

### Task 3: Add gallery operations on `ProfileRepository` (TDD)

**Files:**
- Modify: `lib/features/profile/repository/profile_repository.dart`
- Test: `test/features/profile/profile_repository_test.dart`

- [ ] **Step 1: Add failing tests**

Open `test/features/profile/profile_repository_test.dart` and add inside the existing `group('ProfileRepository', ...)`:

```dart
test('addPhoto appends to photoUrls and sets photoUrl when no main exists',
    () async {
  await firestore.collection('users').doc('u1').set({
    'name': 'Maya',
    'photoUrl': '',
  });

  await repo.addPhoto(uid: 'u1', url: 'https://x/1.jpg');

  final data = (await firestore.collection('users').doc('u1').get()).data()!;
  expect(data['photoUrl'], 'https://x/1.jpg');
  expect(data['photoUrls'], ['https://x/1.jpg']);
});

test('addPhoto does not change photoUrl when a main is already set',
    () async {
  await firestore.collection('users').doc('u1').set({
    'photoUrl': 'https://x/main.jpg',
    'photoUrls': ['https://x/main.jpg'],
  });

  await repo.addPhoto(uid: 'u1', url: 'https://x/2.jpg');

  final data = (await firestore.collection('users').doc('u1').get()).data()!;
  expect(data['photoUrl'], 'https://x/main.jpg');
  expect(data['photoUrls'], ['https://x/main.jpg', 'https://x/2.jpg']);
});

test('removePhoto removes a non-main url from photoUrls', () async {
  await firestore.collection('users').doc('u1').set({
    'photoUrl': 'https://x/main.jpg',
    'photoUrls': ['https://x/main.jpg', 'https://x/2.jpg'],
  });

  await repo.removePhoto(uid: 'u1', url: 'https://x/2.jpg');

  final data = (await firestore.collection('users').doc('u1').get()).data()!;
  expect(data['photoUrl'], 'https://x/main.jpg');
  expect(data['photoUrls'], ['https://x/main.jpg']);
});

test('removePhoto of the main photo promotes the next photo', () async {
  await firestore.collection('users').doc('u1').set({
    'photoUrl': 'https://x/main.jpg',
    'photoUrls': ['https://x/main.jpg', 'https://x/2.jpg'],
  });

  await repo.removePhoto(uid: 'u1', url: 'https://x/main.jpg');

  final data = (await firestore.collection('users').doc('u1').get()).data()!;
  expect(data['photoUrl'], 'https://x/2.jpg');
  expect(data['photoUrls'], ['https://x/2.jpg']);
});

test('removePhoto of the only photo clears photoUrl and photoUrls',
    () async {
  await firestore.collection('users').doc('u1').set({
    'photoUrl': 'https://x/main.jpg',
    'photoUrls': ['https://x/main.jpg'],
  });

  await repo.removePhoto(uid: 'u1', url: 'https://x/main.jpg');

  final data = (await firestore.collection('users').doc('u1').get()).data()!;
  expect(data['photoUrl'], '');
  expect(data['photoUrls'], isEmpty);
});

test('setMainPhoto reorders photoUrls and updates photoUrl', () async {
  await firestore.collection('users').doc('u1').set({
    'photoUrl': 'https://x/1.jpg',
    'photoUrls': ['https://x/1.jpg', 'https://x/2.jpg', 'https://x/3.jpg'],
  });

  await repo.setMainPhoto(uid: 'u1', url: 'https://x/3.jpg');

  final data = (await firestore.collection('users').doc('u1').get()).data()!;
  expect(data['photoUrl'], 'https://x/3.jpg');
  expect(data['photoUrls'],
      ['https://x/3.jpg', 'https://x/1.jpg', 'https://x/2.jpg']);
});

test('setMainPhoto is a no-op when the url is not in photoUrls', () async {
  await firestore.collection('users').doc('u1').set({
    'photoUrl': 'https://x/1.jpg',
    'photoUrls': ['https://x/1.jpg', 'https://x/2.jpg'],
  });

  await repo.setMainPhoto(uid: 'u1', url: 'https://x/unknown.jpg');

  final data = (await firestore.collection('users').doc('u1').get()).data()!;
  expect(data['photoUrl'], 'https://x/1.jpg');
  expect(data['photoUrls'], ['https://x/1.jpg', 'https://x/2.jpg']);
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/profile/profile_repository_test.dart`
Expected: all 7 new tests fail with "method not found" / "addPhoto is undefined" errors.

- [ ] **Step 3: Implement the methods**

Replace `lib/features/profile/repository/profile_repository.dart` with:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/user_profile.dart';

class ProfileRepository {
  final FirebaseFirestore _db;

  ProfileRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  Stream<UserProfile?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map(
      (doc) => doc.exists ? UserProfile.fromFirestore(doc) : null,
    );
  }

  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _users.doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
  }

  Future<void> updateField(String uid, String field, Object? value) async {
    await _users.doc(uid).set({field: value}, SetOptions(merge: true));
  }

  /// Append [url] to `photoUrls`. If no main photo is set yet, also set
  /// `photoUrl` to [url] so the gallery and the main photo stay in sync.
  Future<void> addPhoto({required String uid, required String url}) async {
    final doc = _users.doc(uid);
    final snap = await doc.get();
    final data = snap.data() ?? const <String, dynamic>{};
    final existing = ((data['photoUrls'] as List?) ?? const [])
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    final mainUrl = (data['photoUrl'] as String?) ?? '';
    final next = [...existing, url];
    final updates = <String, dynamic>{
      'photoUrls': next,
    };
    if (mainUrl.isEmpty) {
      updates['photoUrl'] = url;
    }
    await doc.set(updates, SetOptions(merge: true));
  }

  /// Remove [url] from `photoUrls`. If [url] is the current main photo,
  /// promote the next-remaining url to main, or clear `photoUrl` if the
  /// gallery becomes empty.
  Future<void> removePhoto({required String uid, required String url}) async {
    final doc = _users.doc(uid);
    final snap = await doc.get();
    final data = snap.data() ?? const <String, dynamic>{};
    final existing = ((data['photoUrls'] as List?) ?? const [])
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    final mainUrl = (data['photoUrl'] as String?) ?? '';
    final next = existing.where((u) => u != url).toList();
    final updates = <String, dynamic>{
      'photoUrls': next,
    };
    if (mainUrl == url) {
      updates['photoUrl'] = next.isEmpty ? '' : next.first;
    }
    await doc.set(updates, SetOptions(merge: true));
  }

  /// Move [url] to position 0 of `photoUrls` and update `photoUrl` to match.
  /// No-op when [url] is not in the current gallery.
  Future<void> setMainPhoto({required String uid, required String url}) async {
    final doc = _users.doc(uid);
    final snap = await doc.get();
    final data = snap.data() ?? const <String, dynamic>{};
    final existing = ((data['photoUrls'] as List?) ?? const [])
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    if (!existing.contains(url)) return;
    final reordered = [url, ...existing.where((u) => u != url)];
    await doc.set({
      'photoUrl': url,
      'photoUrls': reordered,
    }, SetOptions(merge: true));
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/profile/profile_repository_test.dart`
Expected: all tests pass (existing 5 + new 7).

- [ ] **Step 5: Commit**

```bash
git add lib/features/profile/repository/profile_repository.dart test/features/profile/profile_repository_test.dart
git commit -m "feat(profile): add gallery operations to ProfileRepository"
```

---

### Task 4: Update onboarding repo to write `photoUrls` and use per-uid storage path (TDD)

**Files:**
- Modify: `lib/features/onboarding/repository/onboarding_repository.dart`
- Test: `test/features/onboarding/onboarding_repository_test.dart`

- [ ] **Step 1: Update existing failing tests**

In `test/features/onboarding/onboarding_repository_test.dart`, modify the existing `'savePhotoUrl writes the url and preserves other fields'` test to additionally assert `photoUrls`:

```dart
test('savePhotoUrl writes both photoUrl and photoUrls', () async {
  await firestore.collection('users').doc('u1').set({'name': 'Maya'});

  await repo.savePhotoUrl(
    uid: 'u1',
    url: 'https://example.com/u1.jpg',
  );

  final data = await readUser('u1');
  expect(data['photoUrl'], 'https://example.com/u1.jpg');
  expect(data['photoUrls'], ['https://example.com/u1.jpg']);
  expect(data['name'], 'Maya');
});
```

And the existing `'publishProfile writes all fields plus published and createdAt'` test gains:

```dart
expect(data['photoUrls'], ['https://example.com/u1.jpg']);
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/onboarding/onboarding_repository_test.dart`
Expected: the two updated assertions fail because `photoUrls` is not yet written.

- [ ] **Step 3: Update `OnboardingRepository`**

Replace `lib/features/onboarding/repository/onboarding_repository.dart` with:

```dart
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/providers/my_profile_provider.dart';
import '../notifiers/onboarding_form_notifier.dart';

typedef PhotoUploader = Future<String> Function(String uid, XFile file);

class OnboardingRepository {
  final FirebaseFirestore _db;
  final PhotoUploader _uploadPhotoFn;

  OnboardingRepository(
    this._db, {
    PhotoUploader? photoUploader,
  }) : _uploadPhotoFn = photoUploader ?? _defaultUploader;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Future<void> saveNameAge({
    required String uid,
    required String name,
    required int age,
  }) {
    return _users.doc(uid).set({
      'name': name.trim(),
      'age': age,
    }, SetOptions(merge: true));
  }

  Future<void> saveBio({required String uid, required String bio}) {
    return _users.doc(uid).set({
      'bio': bio.trim(),
    }, SetOptions(merge: true));
  }

  Future<void> saveInterests({
    required String uid,
    required List<String> interests,
  }) {
    return _users.doc(uid).set({
      'interests': interests,
    }, SetOptions(merge: true));
  }

  /// Write the onboarding photo as both the main photo and the only entry of
  /// the gallery. After this call the user document is in canonical
  /// dual-field shape.
  Future<void> savePhotoUrl({
    required String uid,
    required String url,
  }) {
    return _users.doc(uid).set({
      'photoUrl': url,
      'photoUrls': [url],
    }, SetOptions(merge: true));
  }

  Future<String> uploadPhoto({
    required String uid,
    required XFile file,
  }) {
    return _uploadPhotoFn(uid, file);
  }

  Future<void> publishProfile({
    required String uid,
    required OnboardingFormState form,
  }) {
    return _users.doc(uid).set({
      'name': form.name.trim(),
      'age': form.age,
      'bio': form.bio.trim(),
      'photoUrl': form.photoUrl,
      'photoUrls': form.photoUrl.isEmpty ? <String>[] : [form.photoUrl],
      'interests': form.interests,
      'published': true,
      'profilePaused': false,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

Future<String> _defaultUploader(String uid, XFile file) async {
  final raw = await file.readAsBytes();
  final Uint8List bytes = await FlutterImageCompress.compressWithList(
    raw,
    minWidth: 800,
    minHeight: 800,
    quality: 85,
    format: CompressFormat.jpeg,
  );
  final ms = DateTime.now().millisecondsSinceEpoch;
  final rand = Random.secure().nextInt(10000).toString().padLeft(4, '0');
  final ref = FirebaseStorage.instance.ref('profile-photos/$uid/${ms}_$rand.jpg');
  await ref.putData(
    bytes,
    SettableMetadata(contentType: 'image/jpeg'),
  );
  return ref.getDownloadURL();
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(ref.watch(firestoreProvider));
});
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/onboarding/onboarding_repository_test.dart`
Expected: all tests pass, including the two updated ones.

- [ ] **Step 5: Run the full test suite**

Run: `flutter test`
Expected: green.

- [ ] **Step 6: Commit**

```bash
git add lib/features/onboarding/repository/onboarding_repository.dart test/features/onboarding/onboarding_repository_test.dart
git commit -m "feat(onboarding): write photoUrls and use per-uid storage path"
```

---

### Task 5: Update `storage.rules` (LOCAL only — do not deploy)

**Files:**
- Modify: `storage.rules`

- [ ] **Step 1: Replace the rules file**

Open `storage.rules` and replace its entire contents with:

```
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {

    // Legacy single-photo path (read-only after multi-photo gallery sprint).
    // Existing users may still have download URLs pointing here; those URLs
    // remain valid as long as reads are allowed. New uploads go to the
    // per-uid sub-folder rule below.
    match /profile-photos/{file} {
      allow read: if request.auth != null;
      allow write: if false;
    }

    // Profile photo gallery: profile-photos/{uid}/{filename}
    match /profile-photos/{uid}/{file} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && uid == request.auth.uid
        && request.resource.size < 5 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }

    // Deny everything else.
    match /{path=**} {
      allow read, write: if false;
    }
  }
}
```

- [ ] **Step 2: Verify file is well-formed**

Run: `cat storage.rules`
Confirm both `match` blocks for `profile-photos/{file}` and `profile-photos/{uid}/{file}` are present, plus the deny-all fallback.

- [ ] **Step 3: Do NOT deploy**

The user controls deploy timing. The PR description must call out: "Run `firebase deploy --only storage` before testing."

- [ ] **Step 4: Commit**

```bash
git add storage.rules
git commit -m "chore(storage): add per-uid sub-folder rule for photo gallery"
```

---

### Task 6: Add localization keys (EN + KO)

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ko.arb`
- Generated (do not edit by hand): `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_ko.dart`

- [ ] **Step 1: Append English keys**

Open `lib/l10n/app_en.arb`. Before the closing `}`, after the `toastInterestsUpdated` line, add:

```json
,
  "editPhotosTitle": "Edit photos",
  "editPhotosSubtitle": "Add up to 6 photos. The first one is your main photo.",
  "editPhotosCounter": "{count} of 6 photos",
  "@editPhotosCounter": {
    "placeholders": { "count": { "type": "int" } }
  },
  "editPhotosAdd": "Add photo",
  "editPhotosActionTakePhoto": "Take photo",
  "editPhotosActionChooseFromGallery": "Choose from gallery",
  "editPhotosMainBadge": "MAIN",
  "editPhotosActionSetMain": "Set as main",
  "editPhotosActionRemove": "Remove",
  "editPhotosActionCancel": "Cancel",
  "editPhotosCannotRemoveLast": "You need at least one photo.",
  "editPhotosErrorAdd": "Could not add photo. Please try again.",
  "editPhotosErrorRemove": "Could not remove photo. Please try again.",
  "editPhotosErrorSetMain": "Could not update main photo. Please try again.",
  "toastPhotoAdded": "Photo added",
  "toastPhotoRemoved": "Photo removed",
  "toastMainPhotoUpdated": "Main photo updated",
  "youEditPhotos": "Edit photos"
```

(Make sure the previously-final `,` after the line above remains correct JSON — `toastInterestsUpdated`'s line gets a comma added before the new block.)

- [ ] **Step 2: Append Korean keys**

Open `lib/l10n/app_ko.arb`. In the same location (before the closing `}`, after `toastInterestsUpdated`), add:

```json
,
  "editPhotosTitle": "사진 수정",
  "editPhotosSubtitle": "사진은 최대 6장까지 올릴 수 있어요. 첫 번째 사진이 대표 사진이에요.",
  "editPhotosCounter": "사진 {count} / 6장",
  "editPhotosAdd": "사진 추가",
  "editPhotosActionTakePhoto": "사진 찍기",
  "editPhotosActionChooseFromGallery": "사진첩에서 고르기",
  "editPhotosMainBadge": "대표",
  "editPhotosActionSetMain": "대표 사진으로 지정",
  "editPhotosActionRemove": "삭제",
  "editPhotosActionCancel": "취소",
  "editPhotosCannotRemoveLast": "사진이 한 장 이상 있어야 해요.",
  "editPhotosErrorAdd": "사진을 올리지 못했어요. 다시 시도해 주세요.",
  "editPhotosErrorRemove": "사진을 삭제하지 못했어요. 다시 시도해 주세요.",
  "editPhotosErrorSetMain": "대표 사진을 바꾸지 못했어요. 다시 시도해 주세요.",
  "toastPhotoAdded": "사진을 추가했어요",
  "toastPhotoRemoved": "사진을 삭제했어요",
  "toastMainPhotoUpdated": "대표 사진을 바꿨어요",
  "youEditPhotos": "사진 수정"
```

- [ ] **Step 3: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: command exits 0 and `lib/l10n/app_localizations.dart` plus `_en.dart` / `_ko.dart` are updated. (The next `flutter run` would also regenerate, but explicit is better here.)

- [ ] **Step 4: Verify ARB files parse**

Run: `flutter analyze lib/l10n/`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_ko.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_ko.dart
git commit -m "i18n: add edit-photos strings (EN + KO)"
```

---

### Task 7: Build the `PhotoCarousel` widget (TDD)

**Files:**
- Create: `lib/core/widgets/photo_carousel.dart`
- Test: `test/core/widgets/photo_carousel_test.dart`

- [ ] **Step 1: Add failing tests**

Create `test/core/widgets/photo_carousel_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silver_fun/core/widgets/photo_carousel.dart';
import 'package:silver_fun/core/widgets/photo_widget.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: 320, height: 320, child: child),
    ),
  );
}

void main() {
  testWidgets('renders one PhotoWidget per URL', (tester) async {
    await tester.pumpWidget(_wrap(
      const PhotoCarousel(urls: [
        'https://x/1.jpg',
        'https://x/2.jpg',
        'https://x/3.jpg',
      ]),
    ));
    await tester.pumpAndSettle();

    // PageView lazily builds, so only the first page is mounted; assert
    // by counting PhotoWidgets across the tree at startup.
    expect(find.byType(PhotoWidget), findsWidgets);
  });

  testWidgets('hides dot indicator when only one URL is provided',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const PhotoCarousel(urls: ['https://x/only.jpg']),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('photo-carousel-dots')), findsNothing);
  });

  testWidgets('renders N dots when N > 1 URLs are provided', (tester) async {
    await tester.pumpWidget(_wrap(
      const PhotoCarousel(urls: [
        'https://x/1.jpg',
        'https://x/2.jpg',
        'https://x/3.jpg',
      ]),
    ));
    await tester.pumpAndSettle();

    final dots = find.byKey(const ValueKey('photo-carousel-dots'));
    expect(dots, findsOneWidget);
    expect(
      find.descendant(
        of: dots,
        matching: find.byKey(const ValueKey('photo-carousel-dot')),
      ),
      findsNWidgets(3),
    );
  });

  testWidgets('renders an empty placeholder when urls is empty',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const PhotoCarousel(urls: []),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(PhotoWidget), findsOneWidget);
    expect(find.byKey(const ValueKey('photo-carousel-dots')), findsNothing);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/core/widgets/photo_carousel_test.dart`
Expected: failures — file `lib/core/widgets/photo_carousel.dart` does not exist yet.

- [ ] **Step 3: Implement the widget**

Create `lib/core/widgets/photo_carousel.dart` with:

```dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'photo_widget.dart';

/// A horizontally swipeable carousel of profile photos with a small dot
/// indicator below. Falls back to a single placeholder when [urls] is empty
/// and hides the indicator when [urls] has 0 or 1 items.
class PhotoCarousel extends StatefulWidget {
  final List<String> urls;
  final BoxFit fit;

  const PhotoCarousel({
    super.key,
    required this.urls,
    this.fit = BoxFit.cover,
  });

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) {
      return PhotoWidget(url: null, fit: widget.fit);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.urls.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) =>
              PhotoWidget(url: widget.urls[i], fit: widget.fit),
        ),
        if (widget.urls.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: _Dots(
              key: const ValueKey('photo-carousel-dots'),
              count: widget.urls.length,
              activeIndex: _index,
            ),
          ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _Dots({
    super.key,
    required this.count,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          Container(
            key: const ValueKey('photo-carousel-dot'),
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == activeIndex
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.45),
              border: Border.all(
                color: AppColors.ink.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/core/widgets/photo_carousel_test.dart`
Expected: all 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/photo_carousel.dart test/core/widgets/photo_carousel_test.dart
git commit -m "feat(widgets): PhotoCarousel with PageView and dot indicator"
```

---

### Task 8: Use the carousel in `ProfileViewScreen`

**Files:**
- Modify: `lib/features/feed/screens/profile_view_screen.dart`

- [ ] **Step 1: Replace the single PhotoWidget**

In `lib/features/feed/screens/profile_view_screen.dart`, find the `_ProfileBody` build method's `AspectRatio` block (around line 108):

```dart
AspectRatio(
  aspectRatio: 1,
  child: PhotoWidget(url: profile.photoUrl),
),
```

Replace with:

```dart
AspectRatio(
  aspectRatio: 1,
  child: PhotoCarousel(urls: profile.photoUrls),
),
```

Then add the import at the top of the file (alphabetically with other `core/widgets` imports):

```dart
import '../../../core/widgets/photo_carousel.dart';
```

- [ ] **Step 2: Verify it analyzes**

Run: `flutter analyze lib/features/feed/screens/profile_view_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Run the full suite**

Run: `flutter test`
Expected: green (no test reads `profile_view_screen.dart` directly today; this change is rendering-only).

- [ ] **Step 4: Commit**

```bash
git add lib/features/feed/screens/profile_view_screen.dart
git commit -m "feat(profile): use PhotoCarousel on profile detail screen"
```

---

### Task 9: Build the `EditPhotosScreen` (TDD)

**Files:**
- Create: `lib/features/profile/screens/edit_photos_screen.dart`
- Test: `test/features/profile/edit_photos_screen_test.dart`

- [ ] **Step 1: Add a Riverpod-ready provider for the photo upload/delete pair**

Open `lib/features/profile/providers/my_profile_provider.dart` and append:

```dart
/// Picks a photo from [source] (`ImageSource.camera` or `ImageSource.gallery`)
/// and uploads it for [uid], returning the download URL. Returns `null` when
/// the user cancels the picker (so the caller can distinguish "user backed
/// out" from "upload failed"). Injected so widget tests can substitute a fake.
typedef ProfilePhotoUploader =
    Future<String?> Function(String uid, ImageSource source);

/// Best-effort deletes a photo at [url] from Storage. Failures are
/// swallowed inside the implementation. Injected so widget tests can
/// substitute a fake.
typedef ProfilePhotoDeleter = Future<void> Function(String url);

final profilePhotoUploaderProvider = Provider<ProfilePhotoUploader>((ref) {
  return _defaultProfilePhotoUploader;
});

final profilePhotoDeleterProvider = Provider<ProfilePhotoDeleter>((ref) {
  return _defaultProfilePhotoDeleter;
});

Future<String?> _defaultProfilePhotoUploader(
  String uid,
  ImageSource source,
) async {
  final picker = _picker ??= ImagePicker();
  final file = await picker.pickImage(source: source);
  if (file == null) return null;
  final raw = await file.readAsBytes();
  final Uint8List bytes = await FlutterImageCompress.compressWithList(
    raw,
    minWidth: 800,
    minHeight: 800,
    quality: 85,
    format: CompressFormat.jpeg,
  );
  final ms = DateTime.now().millisecondsSinceEpoch;
  final rand = Random.secure().nextInt(10000).toString().padLeft(4, '0');
  final ref = FirebaseStorage.instance.ref('profile-photos/$uid/${ms}_$rand.jpg');
  await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
  return ref.getDownloadURL();
}

Future<void> _defaultProfilePhotoDeleter(String url) async {
  try {
    await FirebaseStorage.instance.refFromURL(url).delete();
  } catch (_) {
    // Best-effort. The Firestore update is the source of truth.
  }
}

ImagePicker? _picker;
```

And add the imports at the top of the file:

```dart
import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
```

- [ ] **Step 2: Add failing widget tests**

Create `test/features/profile/edit_photos_screen_test.dart` (uses the same `MockFirebaseAuth` + `MockUser` pattern as `test/features/profile/edit_interests_screen_test.dart`):

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silver_fun/features/auth/providers/auth_provider.dart';
import 'package:silver_fun/features/profile/providers/my_profile_provider.dart';
import 'package:silver_fun/features/profile/screens/edit_photos_screen.dart';
import 'package:silver_fun/l10n/app_localizations.dart';
import 'package:silver_fun/models/user_profile.dart';

UserProfile _profile({List<String> urls = const ['https://x/1.jpg']}) {
  return UserProfile(
    uid: 'me',
    name: 'Maya',
    age: 30,
    bio: 'Hi.',
    photoUrl: urls.isEmpty ? '' : urls.first,
    photoUrls: urls,
    interests: const ['Coffee'],
    city: '',
    published: true,
    profilePaused: false,
  );
}

Widget _harness({
  required UserProfile profile,
  ProfilePhotoUploader? uploader,
  ProfilePhotoDeleter? deleter,
}) {
  final mockUser = MockUser(uid: 'me', email: 'me@example.com');
  final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(
        (ref) => Stream<User?>.value(mockAuth.currentUser),
      ),
      myProfileProvider.overrideWith((ref) => Stream.value(profile)),
      if (uploader != null)
        profilePhotoUploaderProvider.overrideWithValue(uploader),
      if (deleter != null)
        profilePhotoDeleterProvider.overrideWithValue(deleter),
    ],
    child: MaterialApp(
      home: const EditPhotosScreen(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  testWidgets('renders a tile per photo plus an Add tile when count < 6',
      (tester) async {
    await tester.pumpWidget(_harness(
      profile: _profile(urls: const ['https://x/1.jpg', 'https://x/2.jpg']),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('edit-photos-tile-https://x/1.jpg')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('edit-photos-tile-https://x/2.jpg')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('edit-photos-add-tile')), findsOneWidget);
  });

  testWidgets('hides the Add tile when at the 6-photo cap', (tester) async {
    final urls = List.generate(6, (i) => 'https://x/$i.jpg');
    await tester.pumpWidget(_harness(profile: _profile(urls: urls)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('edit-photos-add-tile')), findsNothing);
  });

  testWidgets('shows the MAIN badge on photoUrls[0] only', (tester) async {
    await tester.pumpWidget(_harness(
      profile: _profile(urls: const ['https://x/1.jpg', 'https://x/2.jpg']),
    ));
    await tester.pumpAndSettle();

    final mainBadges = find.text('MAIN');
    expect(mainBadges, findsOneWidget);
  });

  testWidgets('renders the localized counter', (tester) async {
    await tester.pumpWidget(_harness(
      profile: _profile(urls: const [
        'https://x/1.jpg',
        'https://x/2.jpg',
        'https://x/3.jpg',
      ]),
    ));
    await tester.pumpAndSettle();

    expect(find.text('3 of 6 photos'), findsOneWidget);
  });
}
```

> **Note** — These widget tests do not exercise tap interactions on the bottom-sheet menu (Flutter's `showModalBottomSheet` opens an OverlayEntry that's awkward to drive in widget tests for v1). The repository-level tests already cover the underlying `setMainPhoto` / `removePhoto` calls. The bottom-sheet flow is covered by the manual QA checklist. A future sprint can migrate it to an integration test if needed.

- [ ] **Step 3: Run tests to verify they fail**

Run: `flutter test test/features/profile/edit_photos_screen_test.dart`
Expected: failures — file `lib/features/profile/screens/edit_photos_screen.dart` does not exist.

- [ ] **Step 4: Implement the screen**

Create `lib/features/profile/screens/edit_photos_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/providers/toast_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/photo_widget.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/my_profile_provider.dart';

class EditPhotosScreen extends ConsumerStatefulWidget {
  const EditPhotosScreen({super.key});

  @override
  ConsumerState<EditPhotosScreen> createState() => _EditPhotosScreenState();
}

class _EditPhotosScreenState extends ConsumerState<EditPhotosScreen> {
  bool _uploading = false;

  Future<void> _showAddPhotoSheet() async {
    if (_uploading) return;
    final l = context.l10n;
    final selected = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: AppColors.ink,
              ),
              title: Text(l.editPhotosActionTakePhoto),
              onTap: () => Navigator.of(sheetCtx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.ink,
              ),
              title: Text(l.editPhotosActionChooseFromGallery),
              onTap: () => Navigator.of(sheetCtx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.close, color: AppColors.muted),
              title: Text(l.editPhotosActionCancel),
              onTap: () => Navigator.of(sheetCtx).pop(),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    await _onAdd(selected);
  }

  Future<void> _onAdd(ImageSource source) async {
    final user = ref.read(authProvider).valueOrNull;
    final l = context.l10n;
    if (user == null || _uploading) return;

    setState(() => _uploading = true);
    try {
      final uploader = ref.read(profilePhotoUploaderProvider);
      final url = await uploader(user.uid, source);
      if (url == null) return; // user canceled the picker
      await ref.read(profileRepositoryProvider).addPhoto(uid: user.uid, url: url);
      if (!mounted) return;
      showToast(ref, l.toastPhotoAdded);
    } catch (_) {
      if (!mounted) return;
      showToast(ref, l.editPhotosErrorAdd);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _onSetMain(String url) async {
    final user = ref.read(authProvider).valueOrNull;
    final l = context.l10n;
    if (user == null) return;
    try {
      await ref
          .read(profileRepositoryProvider)
          .setMainPhoto(uid: user.uid, url: url);
      if (!mounted) return;
      showToast(ref, l.toastMainPhotoUpdated);
    } catch (_) {
      if (!mounted) return;
      showToast(ref, l.editPhotosErrorSetMain);
    }
  }

  Future<void> _onRemove(String url) async {
    final user = ref.read(authProvider).valueOrNull;
    final l = context.l10n;
    if (user == null) return;
    try {
      await ref
          .read(profileRepositoryProvider)
          .removePhoto(uid: user.uid, url: url);
      // Best-effort delete from Storage. Failure is logged inside the deleter.
      await ref.read(profilePhotoDeleterProvider)(url);
      if (!mounted) return;
      showToast(ref, l.toastPhotoRemoved);
    } catch (_) {
      if (!mounted) return;
      showToast(ref, l.editPhotosErrorRemove);
    }
  }

  Future<void> _showActions({
    required String url,
    required bool isMain,
    required bool canRemove,
  }) async {
    final l = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              enabled: !isMain,
              leading: const Icon(Icons.star_border, color: AppColors.ink),
              title: Text(l.editPhotosActionSetMain),
              onTap: isMain
                  ? null
                  : () {
                      Navigator.of(sheetCtx).pop();
                      _onSetMain(url);
                    },
            ),
            ListTile(
              enabled: canRemove,
              leading: const Icon(Icons.delete_outline, color: AppColors.ink),
              title: Text(l.editPhotosActionRemove),
              subtitle: canRemove
                  ? null
                  : Text(
                      l.editPhotosCannotRemoveLast,
                      style: const TextStyle(color: AppColors.muted),
                    ),
              onTap: !canRemove
                  ? null
                  : () {
                      Navigator.of(sheetCtx).pop();
                      _onRemove(url);
                    },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: AppColors.muted),
              title: Text(l.editPhotosActionCancel),
              onTap: () => Navigator.of(sheetCtx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final profile = ref.watch(myProfileProvider).valueOrNull;

    if (profile == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final urls = profile.photoUrls;
    final canAdd = urls.length < kMaxProfilePhotos;
    final canRemove = urls.length > 1;

    final tiles = <Widget>[
      for (int i = 0; i < urls.length; i++)
        _PhotoTile(
          key: ValueKey('edit-photos-tile-${urls[i]}'),
          url: urls[i],
          isMain: i == 0,
          onMore: () => _showActions(
            url: urls[i],
            isMain: i == 0,
            canRemove: canRemove,
          ),
        ),
      if (canAdd)
        _AddTile(
          key: const ValueKey('edit-photos-add-tile'),
          uploading: _uploading,
          onTap: _showAddPhotoSheet,
        ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l.editPhotosTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.editPhotosSubtitle,
                style: text.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: tiles,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  l.editPhotosCounter(urls.length),
                  style: text.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String url;
  final bool isMain;
  final VoidCallback onMore;

  const _PhotoTile({
    super.key,
    required this.url,
    required this.isMain,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          PhotoWidget(url: url),
          if (isMain)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l.editPhotosMainBadge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          Positioned(
            right: 6,
            bottom: 6,
            child: GestureDetector(
              onTap: onMore,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.more_horiz,
                  color: AppColors.ink,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final bool uploading;
  final VoidCallback onTap;

  const _AddTile({super.key, required this.uploading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: uploading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line, width: 1.5),
        ),
        alignment: Alignment.center,
        child: uploading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: AppColors.accent, size: 32),
                  const SizedBox(height: 6),
                  Text(
                    l.editPhotosAdd,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run tests**

Run: `flutter test test/features/profile/edit_photos_screen_test.dart`
Expected: all 4 tests pass.

- [ ] **Step 6: Run the full suite**

Run: `flutter test`
Expected: green.

- [ ] **Step 7: Commit**

```bash
git add lib/features/profile/screens/edit_photos_screen.dart lib/features/profile/providers/my_profile_provider.dart test/features/profile/edit_photos_screen_test.dart
git commit -m "feat(profile): EditPhotosScreen with add/remove/set-as-main"
```

---

### Task 10: Add `/edit-photos` route + wire navigation from You + Settings (TDD on the You screen)

**Files:**
- Modify: `lib/core/router/router.dart`
- Modify: `lib/features/profile/screens/you_screen.dart`
- Modify: `lib/features/profile/screens/settings_screen.dart`
- Test: `test/features/profile/you_screen_test.dart`

- [ ] **Step 1: Add a failing test for the You screen button**

In `test/features/profile/you_screen_test.dart`, inside the existing first test `'YouScreen renders name, status, bio, chips'`, add:

```dart
expect(find.text('Edit photos'), findsOneWidget);
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/features/profile/you_screen_test.dart`
Expected: failure — "Expected: exactly one matching candidate, Actual: 0".

- [ ] **Step 3: Add the route**

Open `lib/core/router/router.dart` and add inside the top-level `routes:` list (alongside `/edit-bio` and `/edit-interests`):

```dart
GoRoute(
  path: '/edit-photos',
  builder: (_, _) => const EditPhotosScreen(),
),
```

Add the import at the top of the file:

```dart
import '../../features/profile/screens/edit_photos_screen.dart';
```

- [ ] **Step 4: Add the You screen button**

Open `lib/features/profile/screens/you_screen.dart`. In `_YouBody.build`, find the existing button block:

```dart
const SizedBox(height: 12),
Btn(
  label: l.youEditInterests,
  variant: BtnVariant.ghost,
  onPressed: () => context.push('/edit-interests'),
),
```

Insert a new button **before** this Edit interests button:

```dart
const SizedBox(height: 12),
Btn(
  label: l.youEditPhotos,
  variant: BtnVariant.ghost,
  onPressed: () => context.push('/edit-photos'),
),
```

Final order: Preview profile → **Edit photos** → Edit interests → Edit bio.

- [ ] **Step 5: Wire the Settings row**

Open `lib/features/profile/screens/settings_screen.dart`. Find the existing `ListTile` for `l.settingsEditPhoto`:

```dart
ListTile(
  title: Text(l.settingsEditPhoto),
  trailing: const Icon(
    Icons.chevron_right,
    color: AppColors.muted,
  ),
),
```

Replace with:

```dart
ListTile(
  title: Text(l.settingsEditPhoto),
  trailing: const Icon(
    Icons.chevron_right,
    color: AppColors.muted,
  ),
  onTap: () => context.push('/edit-photos'),
),
```

- [ ] **Step 6: Run the You screen test**

Run: `flutter test test/features/profile/you_screen_test.dart`
Expected: green.

- [ ] **Step 7: Run the full suite**

Run: `flutter test`
Expected: green.

- [ ] **Step 8: Run analyze**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 9: Commit**

```bash
git add lib/core/router/router.dart lib/features/profile/screens/you_screen.dart lib/features/profile/screens/settings_screen.dart test/features/profile/you_screen_test.dart
git commit -m "feat(profile): wire /edit-photos route from You and Settings"
```

---

### Task 11: Final verification + smoke test instructions

**Files:** none (verification only)

- [ ] **Step 1: Final analyzer pass**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 2: Final test pass**

Run: `flutter test`
Expected: total tests increased by ~12, all green.

- [ ] **Step 3: Confirm no rules deploy happened**

Run: `git diff main -- firestore.rules`
Expected: no diff.

Run: `git diff main -- storage.rules`
Expected: shows the legacy + per-uid sub-folder structure.

- [ ] **Step 4: Cross-check the changeset**

Run: `git log --oneline main..HEAD`
Expected: 9 or 10 commits, each named per the plan.

Run: `git diff --stat main..HEAD`
Expected: changes confined to:
- `lib/core/constants.dart`
- `lib/core/widgets/photo_carousel.dart` (new)
- `lib/core/router/router.dart`
- `lib/features/profile/screens/edit_photos_screen.dart` (new)
- `lib/features/profile/screens/you_screen.dart`
- `lib/features/profile/screens/settings_screen.dart`
- `lib/features/profile/repository/profile_repository.dart`
- `lib/features/profile/providers/my_profile_provider.dart`
- `lib/features/onboarding/repository/onboarding_repository.dart`
- `lib/features/feed/screens/profile_view_screen.dart`
- `lib/models/user_profile.dart`
- `lib/l10n/app_en.arb`, `app_ko.arb`, generated `app_localizations*.dart`
- `storage.rules`
- `test/...` (new + extended)

Nothing in `firestore.rules`. Nothing in `pubspec.yaml`.

- [ ] **Step 5: Manual smoke (English locale)**

Run the app on an emulator or device:

```bash
flutter run
```

Walk through:
1. Sign in with a fresh account (or one whose Firestore doc you have cleaned up).
2. Onboard with one photo. Confirm Firestore has both `photoUrl` and `photoUrls: [<url>]`.
3. You → Edit photos. Confirm the existing photo shows the MAIN badge.
4. Add a second photo. Confirm the new tile appears, no MAIN badge.
5. Tap "..." on the second photo → Set as main. Confirm the badge moves and the You-screen avatar (after popping back) updates.
6. From a second device or another signed-in account, view the first user's profile detail. Confirm two dots, swipe between photos.
7. Switch language to Korean via Settings → Language. Confirm the Edit photos screen renders Korean strings.

(See "Manual two-device QA checklist" above for the full grid.)

- [ ] **Step 6: Push the branch**

```bash
git push -u origin profile-photos-gallery
```

(No PR creation in this task — defer to the human reviewer's preferred PR workflow.)

---

## End of plan
