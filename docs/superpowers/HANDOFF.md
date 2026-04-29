# Kindred — Session Handoff

_Written 2026-04-29. Use this to orient a new session before touching any code._

---

## 1. Project Goal

Build **Kindred** — an Android-primary Flutter social app where users sign in with Google, create a profile, browse a discover feed, like other users, and chat with mutual matches. The working directory is `/Users/mathmind/silver_fun_v3`. No Flutter code exists yet; the directory currently contains only design artefacts and docs.

---

## 2. Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3.x |
| Platform | Android primary (`minSdkVersion 21`) |
| Package name | `dev.mathminds.silver_fun` |
| Auth | Firebase Auth + `google_sign_in` |
| Database | Cloud Firestore |
| Storage | Firebase Storage |
| State | `flutter_riverpod` 2.x (`StreamProvider`, `AsyncNotifier`, `Notifier`, `StateProvider`) |
| Navigation | `go_router` 14.x with a `RouterNotifier` redirect guard |
| Images | `image_picker` + `flutter_image_compress` + `cached_network_image` |
| Fonts | `google_fonts` (Fraunces display, Plus Jakarta Sans body) |
| Testing | `flutter_test`, `fake_cloud_firestore`, `firebase_auth_mocks`, `mockito` |

The user already has a Firebase project. They will run `flutterfire configure` to generate `firebase_options.dart` during Phase 2.

---

## 3. Important Design Decisions

**Visual theme — Bold Playful only.** Three themes were prototyped; user selected #3. Palette: bg `#f2eeff`, accent `#ff5a6e`, ink `#1a1440`, muted `#6f6a99`, line `#e0d9ff`, surface white, chipBg `#ebe4ff`. Radii: 26px card, 16px small, 999px pills.

**Riverpod — hand-written providers, no code generation.** No `riverpod_annotation` / `riverpod_generator` at this stage. All providers written manually.

**Onboarding form state is local, not global.** `OnboardingFormNotifier extends Notifier<OnboardingFormState>` lives only in the onboarding feature. Each step also writes incrementally to Firestore so progress survives restarts.

**Reverse like index.** The spec's data model (`likes/{uid}/liked/{targetUid}`) is efficient for "who have I liked?" but not for "who has liked me?". The plan adds a `likedBy/{toUid}/from/{fromUid}` collection written atomically (Firestore batch) alongside every like/unlike. This powers the Liked You screen without full-table scans.

**Edit Bio screen is shared.** `EditBioScreen` in `lib/features/onboarding/screens/edit_bio_screen.dart` accepts a `bool standalone` parameter. When `false` it shows the step bar (onboarding step 3). When `true` it shows a Save button in the app bar (routed at `/edit-bio`).

**Chat ID formula.** `chatId(uid1, uid2)` = `[uid1, uid2]..sort()` joined with `_`. Deterministic; same chat doc regardless of who initiates.

**Architecture.** Feature-first: `lib/features/{feature}/{screens,providers,repository}/`. Shared code in `lib/core/{theme,router,widgets,providers}/`. Screens talk only to providers; providers call repositories; repositories call Firebase.

**`LikedYouScreen` data source.** Reads `likedBy/{myUid}/from/*` (reverse index) then fetches each `UserProfile` via `FeedRepository.getUser`.

---

## 4. Key File Locations

| Artefact | Path |
|---|---|
| Design spec | `docs/superpowers/specs/2026-04-29-kindred-design.md` |
| Implementation plan | `docs/superpowers/plans/kindred_implementation_plan.md` |
| HTML prototype (reference) | `/tmp/design_extracted/app-onboarding/project/Kindred App.html` (temp — may not persist) |
| This handoff | `docs/superpowers/HANDOFF.md` |

---

## 5. The 7 Phases

| # | Phase | Deliverable |
|---|---|---|
| 1 | Scaffold, Models, Theme, Shared Widgets | Runnable app, tested models, Bold Playful theme, Btn/Chip/Heart/Photo/StepBar widgets |
| 2 | Auth + Router | Google sign-in works, router redirect guard active, `SignInScreen` |
| 3 | Onboarding Flow | 4-step flow → preview → publish; photo upload to Storage |
| 4 | Feed + Likes | Live Firestore feed, heart toggle, mutual match toast |
| 5 | Profile Tab | You screen, Settings, Liked You, standalone Edit Bio |
| 6 | Chat | Mutual-match threads, real-time bubbles, unread badges |
| 7 | Toast, Shell, Security Rules | Full app assembly, `firestore.rules` + `storage.rules` deployed |

Each phase ends with a git commit. Run `flutter test` before committing each phase.

---

## 6. Constraints and Warnings

- **No git repo yet.** Run `git init && git add . && git commit -m "chore: initial design artefacts"` before starting Phase 1 so commits are meaningful.
- **`flutter create --overwrite .`** is required because the directory is non-empty. It will overwrite `README.md` and create platform folders; the `docs/` tree is safe.
- **`flutterfire configure` must run before any Firebase code compiles.** Do this in Phase 2, not Phase 1. The user needs their Firebase project ID handy.
- **`google-services.json` is gitignored** by default by FlutterFire. Remind the user to keep their own copy.
- **Firestore indexes.** The `watchFeed` query (`published == true && profilePaused == false`) may require a composite index. Firestore will print a console link to create it on first run — follow it.
- **`fake_cloud_firestore` does not enforce security rules.** Repository tests are pure logic tests. Security rules are verified manually in Phase 7 via `firebase deploy`.
- **iOS is out of scope.** `GoogleService-Info.plist` and Podfile setup are not covered. The code is iOS-compatible but don't expect it to build on iOS without additional setup.

---

## 7. Recommended First Prompt for Next Session

Paste this verbatim to start implementation:

> Read `docs/superpowers/HANDOFF.md` and `docs/superpowers/plans/kindred_implementation_plan.md` to orient yourself. Then implement **Phase 1** of the plan exactly as written: scaffold the Flutter project, add all dependencies, create the theme, models, and shared widgets. Run `flutter test test/models/` and `flutter analyze` before committing. Do not start Phase 2.
