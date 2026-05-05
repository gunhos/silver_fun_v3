# Silvers Fun

Silvers Fun is a Flutter mobile app that helps seniors connect with people, discover shared interests, and join or create small meetups.

The app is designed for adults 65+ who want a warm, simple, and low-pressure way to meet friends, companions, and activity partners.

## What the app does

Silvers Fun helps users:

- Create a personal profile with photos, bio, age, and interests

- Discover other members with shared interests

- Like profiles and form mutual connections

- Chat after a mutual connection

- Browse, create, join, and leave meetups

- Manage profile photos and choose a main profile photo

- Re-pick interest tags after onboarding

- Switch between English and Korean in account settings

## Why it exists

Many seniors want companionship, conversation, and shared activities, but existing social or dating apps can feel too fast, too confusing, or too focused on younger users.

Silvers Fun is built around:

- Companionship, not swipe pressure

- Shared interests and activities

- Simple profile controls

- Mutual connections before chat

- Large, readable, senior-friendly UI

- Korean and English accessibility

## Tech stack

- Flutter

- Firebase Authentication

- Cloud Firestore

- Firebase Storage

- Riverpod

- go_router

- Google Sign-In

- Android / Google Play internal testing

## Google Sign-In configuration

`google_sign_in` 6.x on Android can no longer return a Firebase-compatible
`idToken` from a release build that is signed by **Play App Signing** unless
the client passes a `serverClientId` — the Firebase project's **Web OAuth
client** (the entry with `client_type: 3` in `android/app/google-services.json`).
Without it, sign-in succeeds locally on debug builds but fails on Play Store
internal testing tracks because the upload key Google verifies against does
not match the Play-signed binary.

### How the Web client ID is sourced

We do **not** hard-code the Web client ID. Instead it is generated from the
authoritative source — `google-services.json` — into a git-ignored Dart file:

```
android/app/google-services.json
        │   client_type: 3 → client_id
        ▼
scripts/generate_google_auth_config.py
        ▼
lib/core/config/google_auth_config.dart   (git-ignored)
        │   const String googleWebClientId = '...';
        ▼
lib/features/auth/providers/auth_provider.dart
        │   GoogleAuthService(serverClientId: googleWebClientId)
        ▼
lib/features/auth/services/google_auth_service.dart
        │   GoogleSignIn(serverClientId: ...)
```

Because the value is sourced from `google-services.json` at build time, it
automatically tracks whichever Firebase project FlutterFire most recently
configured.

### First-time setup (and after every clone)

```sh
python3 scripts/generate_google_auth_config.py
```

The repo will not compile until this file exists; that is intentional, so a
missing/stale Web client ID is caught at build time rather than at runtime
on a tester's device.

### Switching to a different Firebase project

```sh
flutterfire configure                     # rewrites google-services.json + firebase_options.dart
scripts/build_release_aab.sh              # regenerates google_auth_config.dart, then builds AAB
```

No environment variables, no copy-pasting OAuth client IDs by hand.

### Releasing to Play Store internal testing

```sh
scripts/build_release_aab.sh
# AAB lands at build/app/outputs/bundle/release/app-release.aab
# Then: Play Console → Internal testing → Create new release → upload that AAB.
```

