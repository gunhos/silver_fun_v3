# Kindred — Design Spec

_Date: 2026-04-29_

## Overview

Kindred is an Android-primary social/friends app. Users sign in with Google, complete a profile, publish to a discover feed, like other users, and chat with mutual matches. The implementation is Flutter + Firebase (Auth, Firestore, Storage) using Riverpod for state management and go_router for navigation.

**Visual theme:** Bold Playful — Fraunces display font, Plus Jakarta Sans body, lavender background (`#f2eeff`), coral accent (`#ff5a6e`), large corner radii (26px cards, 16px small, 999px pills).

---

## Project Structure

```
lib/
  core/
    firebase/        # Firebase initialization
    router/          # go_router config + auth redirect guard
    theme/           # Bold Playful ThemeData
    widgets/         # Btn, Chip, Heart, PhotoWidget, Icons (shared across features)
  features/
    auth/
      screens/       # SignInScreen
      services/      # GoogleAuthService (wraps google_sign_in + firebase_auth)
    onboarding/
      screens/       # NameAgeScreen, AddPhotoScreen, EditBioScreen, InterestsScreen, PreviewScreen
      notifiers/     # OnboardingFormNotifier — local StateNotifier for in-progress form state (not global)
      repository/    # OnboardingRepository (Firestore + Storage writes)
    feed/
      screens/       # FeedScreen, ProfileViewScreen
      providers/     # feedProvider, likesProvider
      repository/    # FeedRepository, LikesRepository
    chat/
      screens/       # ChatListScreen, ChatScreen
      providers/     # chatsProvider, matchesProvider
      repository/    # ChatRepository
    profile/
      screens/       # YouScreen, EditBioScreen (standalone), SettingsScreen
      providers/     # myProfileProvider
      repository/    # ProfileRepository
```

Each feature folder contains `screens/`, `providers/`, and `repository/`. Screens only interact with providers; providers call repositories; repositories call Firebase directly.

---

## Firebase Setup

### Prerequisites (user-provided)

- Firebase project with **Authentication** (Google sign-in method enabled) and **Firestore** enabled
- `google-services.json` placed at `android/app/google-services.json`
- `GoogleService-Info.plist` placed at `ios/Runner/GoogleService-Info.plist` (for future iOS support)
- Firebase Storage bucket enabled

### Flutter dependencies

```yaml
firebase_core
firebase_auth
cloud_firestore
firebase_storage
google_sign_in
riverpod / flutter_riverpod / riverpod_annotation
go_router
image_picker
flutter_image_compress
cached_network_image
google_fonts
```

---

## Data Model

### `users/{uid}`

| Field | Type | Notes |
|---|---|---|
| name | String | First name |
| age | int | Must be ≥ 18 |
| bio | String | Max 180 chars |
| photoUrl | String | Firebase Storage download URL |
| interests | List\<String\> | 3–6 items from interest pool |
| published | bool | false until user completes onboarding and taps "Publish" |
| profilePaused | bool | Hides from feed when true |
| createdAt | Timestamp | Set on first write |

Readable by any authenticated user when `published == true`. Writable by owner only.

### `likes/{uid}/liked/{targetUid}`

| Field | Type | Notes |
|---|---|---|
| likedAt | Timestamp | When the like was given |

A mutual match exists when both `likes/{uid}/liked/{targetUid}` and `likes/{targetUid}/liked/{uid}` exist.

Writable by `uid` only. Readable by any authenticated user.

### `chats/{chatId}/messages/{msgId}`

`chatId` = `[uid1, uid2].sorted().join('_')`

| Field | Type | Notes |
|---|---|---|
| text | String | Message body |
| senderId | String | UID of sender |
| sentAt | Timestamp | Server timestamp |
| read | bool | false until recipient opens thread |

Readable and writable only by the two participants. Access requires a mutual like to exist (enforced in Security Rules).

### Firebase Storage

`profile-photos/{uid}.jpg` — writable by owner, readable by any authenticated user. Max 5 MB (enforced in Storage rules). Client compresses to 800×800 JPEG before upload.

### Security Rules (summary)

```
users/{uid}       read: published==true OR owner; write: owner only
likes/{uid}/...   write: request.auth.uid == uid; read: authenticated
chats/{chatId}/.. read+write: sender is one of two participants AND mutual like exists
```

---

## State Management (Riverpod)

| Provider | Type | Responsibility |
|---|---|---|
| `authProvider` | `StreamProvider<User?>` | Firebase Auth state stream; drives router guard |
| `myProfileProvider` | `AsyncNotifier<UserProfile?>` | Current user's Firestore doc (read/write) |
| `feedProvider` | `StreamProvider<List<UserProfile>>` | Published profiles excluding self and paused; merges like state |
| `likesProvider` | `AsyncNotifier` | Like/unlike writes; exposes mutual match list |
| `chatsProvider` | `StreamProvider<Map<...>>` | Matches + message threads; only for mutual matches |
| `toastProvider` | `StateProvider<String?>` | Transient toast messages; auto-clears after 2.2s |

---

## Navigation (go_router)

```
/                   → redirect (auth guard)
/signin             → SignInScreen
/onboarding/name    → NameAgeScreen
/onboarding/photo   → AddPhotoScreen
/onboarding/bio     → EditBioScreen (onboarding mode)
/onboarding/interests → InterestsScreen
/onboarding/preview → PreviewScreen
/app                → ShellRoute (bottom nav: Discover, Chats, Liked You, You)
  /app/feed         → FeedScreen
  /app/chats        → ChatListScreen
  /app/liked-you    → LikedYouScreen
  /app/you          → YouScreen
/profile/:userId    → ProfileViewScreen
/chat/:userId       → ChatScreen
/settings           → SettingsScreen
/edit-bio           → EditBioScreen (standalone mode)
```

**Auth redirect logic:**
1. Unauthenticated → `/signin`
2. Authenticated + `published == false` → `/onboarding/name`
3. Authenticated + `published == true` → `/app/feed`

---

## Screens

### Auth

**SignInScreen** — Logo, tagline, "Continue with Google" button. Calls `GoogleAuthService.signIn()`. On success, router redirect handles destination.

### Onboarding (4 steps + preview)

Each step writes incrementally to Firestore so progress survives app restarts.

- **NameAgeScreen** — First name + age fields. Validates name ≥ 2 chars, age ≥ 18.
- **AddPhotoScreen** — `image_picker` for camera or gallery. Shows circular preview. Compresses and uploads on selection; saves `photoUrl` to Firestore.
- **EditBioScreen (onboarding)** — Textarea with 180-char counter. Validates ≥ 10 chars to enable Continue.
- **InterestsScreen** — 24-item chip grid. Select 3–6. Counter shows `n/6 selected`.
- **PreviewScreen** — Renders `ProfileCard` as others will see it. Edit button goes back to bio. Publish button sets `published = true` and navigates to `/app/feed`.

### Main App (ShellRoute)

**FeedScreen** — 2-column grid. Streams `feedProvider`. Each card shows photo (3:4 ratio), first name, age, city, 2 interest chips, and a heart button. Tapping a card navigates to `/profile/:userId`. Heart toggles like; fires match toast if mutual.

**ChatListScreen** — Horizontal avatar row of matches at top. Conversation list below with last message preview, relative timestamp, and unread badge. Empty state if no matches.

**LikedYouScreen** — List rows of users who liked the current user. Each row: avatar, name, age, bio snippet, heart icon. Tap → `/profile/:userId`.

**YouScreen** — Avatar + name/age/city, bio block, interests chips. Preview and Edit Bio buttons. Settings gear in app bar.

### Fullscreen Screens

**ProfileViewScreen** — Square hero photo fills top half. Back button overlaid top-left. Scrollable content: name + age, city, bio, interest chips. Fixed bottom bar: Back (ghost button) + Like/Liked button (primary). Like fires toast; match toast if mutual.

**ChatScreen** — Full-screen bubble UI. Header: back, avatar, name, match subtitle, heart icon. Match card at top of message list. Outgoing bubbles: coral (`#ff5a6e`). Incoming: white with border. Avatar shown for first message in each incoming group. Auto-scrolls to newest. Textarea + send button; send on tap or Enter. Marks all incoming messages read on open. Messages stream from Firestore in real time.

**SettingsScreen** — Grouped list sections:
- Profile: Pause profile toggle (writes `profilePaused` to Firestore), Edit profile photo, Who can see me (UI only)
- Notifications: New likes, Weekly digest (UI only)
- Account: Connected with Google, Privacy, Help (UI only)
- Sign out button (clears auth, redirects to sign-in)

**EditBioScreen (standalone)** — Same editor as onboarding step but with Save button in app bar. Save writes bio to Firestore, pops back, shows toast.

### Shared Widgets

| Widget | Description |
|---|---|
| `Btn` | Primary, ghost, dark variants. Full-width or auto. Scale-on-press animation. |
| `Chip` | Interest tag pill. Selected = filled with `ink` color. md/sm sizes. |
| `Heart` | Circular button. Filled coral when liked. Scale-on-press. |
| `PhotoWidget` | `CachedNetworkImage` with striped fallback placeholder. |
| `Toast` | Floating pill overlaid above bottom nav. `toastProvider` drives visibility. |
| `StepBar` | 4-segment progress bar for onboarding. |

---

## Cross-cutting Concerns

**Photo upload flow:**
1. User picks image via `image_picker`
2. Compress to 800×800 JPEG with `flutter_image_compress`
3. Upload to `profile-photos/{uid}.jpg` via Firebase Storage
4. Get download URL → write to `users/{uid}.photoUrl`

**Match detection:**
When the current user likes someone, check if `likes/{targetUid}/liked/{currentUid}` exists. If yes: mutual match, show "It's a match! 🎉" toast, chat is now accessible.

**Toast system:**
`toastProvider` holds a nullable string. Any provider or screen can set it. An `OverlayEntry` (or `Stack` in the root scaffold) watches the provider and shows/hides the pill. Auto-clears via `Future.delayed(2.2s)`.

**Platform target:**
Android primary. Package name: `dev.mathminds.silver_fun`. `minSdkVersion 21`. The app is structurally iOS-compatible; iOS setup (GoogleService-Info.plist, Podfile) is out of scope but noted in setup instructions.

---

## Out of Scope

- Push notifications
- Location/distance filtering
- Block/report
- Multiple profile photos
- iOS App Store submission
- Notification settings (UI present, no backend wiring)
- "Who can see me" setting (UI present, no backend wiring)
