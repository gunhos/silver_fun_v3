# Silvers Fun — Korean Localization Sprint

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add proper English/Korean (`en`/`ko`) localization to Silvers Fun using Flutter's standard `flutter_localizations` + ARB-file pipeline, while preserving all existing English copy and not breaking any current behavior, schema, or test.

**Architecture:** Pure presentation-layer + scaffolding sprint. We add `flutter_localizations` and `intl`, enable Flutter's `gen-l10n` toolchain (`flutter.generate: true` + `l10n.yaml`), introduce `lib/l10n/app_en.arb` and `lib/l10n/app_ko.arb`, and replace hardcoded user-facing strings in screens/widgets with calls to the generated `AppLocalizations` class. The `MaterialApp.router` in `main.dart` is wired up with the localization delegates and `supportedLocales`. The device locale drives the active language automatically — no in-app toggle in this sprint. The `LikesController.toggleLike` is refactored to return a `LikeOutcome` so the toast text can be localized at the call site (which has `BuildContext`); the toast pipeline itself stays string-based and unchanged.

**Tech Stack:** Flutter 3.11.5+ · `flutter_localizations` (SDK) · `intl` (SDK transitive) · existing Riverpod/GoRouter/Firebase stack — no new third-party deps.

---

## Sprint goal

Make Silvers Fun usable end-to-end in Korean for adults 65+:

- A device set to Korean (`ko-KR`) shows Korean copy on every user-facing screen on first launch.
- A device set to English (or any other locale) keeps the current English copy unchanged.
- All user-visible strings — sign-in, onboarding, feed, profile detail, liked-you, chats list, chat thread, You, settings, edit bio, safety reminder, toasts, buttons, empty states, validation/helper messages — come from ARB files, not from `Text('…')` literals.
- Korean copy is friendly, clear, respectful for adults 65+; companionship/community language; no childish or dating-heavy wording; "Silvers Fun" stays in English; "connection" → 인연 (warm relational sense) or 친구 (peer/friend sense) depending on context.
- The existing test suite (`flutter test`, currently 65/65 green per the handoff) still passes after the migration; localization-aware widget tests are added for the screens with the most user-visible logic (`MainShell`, `YouScreen`, `ToastOverlay`).
- `flutter analyze` stays clean.

## Non-goals

- **No in-app language toggle.** The device-language path is the entirety of the language UX in this sprint. (See Risks for follow-up; reasoning: the toggle requires a persisted preference + a Riverpod-controlled `MaterialApp.locale` + a settings UI, which adds testing surface area we don't need to ship Korean.)
- **No package rename** (`name: silver_fun` in `pubspec.yaml` stays — many `package:silver_fun/...` imports depend on it).
- **No internal symbol rename.** `MatchThread`, `matchesProvider`, `matchThreadsProvider`, `_MatchCard`, `_MatchBubble`, `_MatchBubblesRow`, `LikesController`, `LikesRepository`, etc. stay. Only user-facing strings move.
- **No Firestore schema changes.** No new `locale`/`preferredLanguage` fields on user docs. Bios/names users typed remain whatever they typed.
- **No localization of the interest pool yet.** `kInterestPool` in `lib/core/constants.dart` is left as English-only strings. Localizing chips requires either (a) storing language-neutral keys in Firestore and translating on render (schema change, out of scope) or (b) showing English chip labels even in Korean UI (acceptable for v1). We pick (b). Logged in Risks.
- **No localized number/date formatting beyond what's already trivial.** The chat list's `_formatTime` ("now"/"5m"/"3h"/"2d"/"4/19") gets a Korean-aware version, but we do not add full `DateFormat` patterns or a calendar library.
- **No iOS-specific localized display name.** iOS `CFBundleDisplayName` stays "Silver Fun" (English). iOS isn't yet shipped per the handoff (`§7`); we don't take on `InfoPlist.strings` work.
- **No web manifest translation.** `web/manifest.json` and `web/index.html` stay English. The web build is QA-only per the handoff.
- **No localization of error strings appended from exceptions** (`'Could not load feed.\n$e'` — the `$e` part stays as whatever Firestore/Dart serializes; only the English prefix becomes a localized string).

## Localization approach

**Mechanism:** Flutter's official `gen-l10n` pipeline.

1. `pubspec.yaml` gets:
   - `flutter_localizations: { sdk: flutter }` under `dependencies`
   - `intl: any` under `dependencies` (transitive of `flutter_localizations` but pinning explicitly is the documented pattern)
   - `flutter.generate: true` enabling code generation on `flutter pub get`
2. A new `l10n.yaml` at the repo root tells the generator where ARB files live and what to name the generated class:
   ```yaml
   arb-dir: lib/l10n
   template-arb-file: app_en.arb
   output-localization-file: app_localizations.dart
   output-class: AppLocalizations
   ```
3. `lib/l10n/app_en.arb` is the source-of-truth template. `lib/l10n/app_ko.arb` is the Korean override.
4. Running `flutter pub get` (or `flutter gen-l10n`) produces `.dart_tool/flutter_gen/gen_l10n/app_localizations.dart`, importable via `package:flutter_gen/gen_l10n/app_localizations.dart`. **This file is generated, do not commit edits to it.** It's in `.dart_tool/` which is already gitignored.
5. `MaterialApp.router` in `lib/main.dart` is given `localizationsDelegates: AppLocalizations.localizationsDelegates` and `supportedLocales: AppLocalizations.supportedLocales`.
6. Each screen reads strings via `AppLocalizations.of(context)!` (extension `context.l10n` is added in a small helper for ergonomics).
7. The active locale is the device locale, falling back to `en` when the device locale is not `ko`.

**Why this approach over `easy_localization` or `slang`:** zero new third-party deps; matches the toolchain Flutter docs and Material guidance assume; `intl` plural/select syntax in ARB is exactly what we need for `"$count / 6 selected"`.

**Toast localization:** the only string-emitting non-widget code is `LikesController.toggleLike` in `lib/features/feed/providers/likes_provider.dart`, which calls `showToastFromRef` with a literal English string. Since providers don't have `BuildContext`, we refactor `toggleLike` to return a `LikeOutcome` enum/value, and the calling widgets (`FeedScreen._ProfileCard.onLike`, `ProfileViewScreen._ProfileBody.onToggleLike`) call `showToast(ref, ...)` with the localized string. This keeps the toast wire format unchanged.

**Stub screen:** `lib/core/widgets/stub_screen.dart` is only used at `path: '/'` with `title: 'Loading'` (a transient redirect target). We localize it with a single `loadingTitle` key.

## Files likely to edit

Scaffolding & wiring
- `pubspec.yaml` — deps + `flutter.generate: true`
- `l10n.yaml` (new)
- `lib/l10n/app_en.arb` (new)
- `lib/l10n/app_ko.arb` (new)
- `lib/main.dart` — delegates + supportedLocales on `MaterialApp.router`
- `lib/core/extensions/l10n_extension.dart` (new) — `context.l10n` getter

User-facing screens
- `lib/features/auth/screens/sign_in_screen.dart`
- `lib/features/onboarding/screens/name_age_screen.dart`
- `lib/features/onboarding/screens/add_photo_screen.dart`
- `lib/features/onboarding/screens/edit_bio_screen.dart`
- `lib/features/onboarding/screens/interests_screen.dart`
- `lib/features/onboarding/screens/preview_screen.dart`
- `lib/features/feed/screens/feed_screen.dart`
- `lib/features/feed/screens/profile_view_screen.dart`
- `lib/features/profile/screens/liked_you_screen.dart`
- `lib/features/profile/screens/you_screen.dart`
- `lib/features/profile/screens/settings_screen.dart`
- `lib/features/chat/screens/chat_list_screen.dart`
- `lib/features/chat/screens/chat_screen.dart`

Shared widgets
- `lib/core/widgets/main_shell.dart` — bottom nav labels
- `lib/core/widgets/stub_screen.dart` — "Loading" + "— coming soon"

Provider refactor
- `lib/features/feed/providers/likes_provider.dart` — `toggleLike` returns `LikeOutcome`; toast call moves to widget

Tests
- `test/core/widgets/main_shell_test.dart` — wrap harness in localizations delegates, expect localized labels under `Locale('en')`
- `test/features/profile/you_screen_test.dart` — same
- `test/core/widgets/toast_overlay_test.dart` — unaffected (it tests passthrough strings, not localization), but harness gets the delegate added defensively
- `test/features/feed/likes_controller_test.dart` (new, optional) — verify `toggleLike` returns the right `LikeOutcome` for liked vs mutual

> Out of scope (do **not** touch): `lib/core/constants.dart` (`kInterestPool`), `firestore.rules`, `storage.rules`, `lib/firebase_options.dart`, anything under `android/`, `ios/`, `linux/`, `macos/`, `windows/`, `web/manifest.json`, `web/index.html`.

---

## Step-by-step implementation tasks

### Task 1 — Add localization dependencies and toolchain config

**Files:**
- Modify: `pubspec.yaml`
- Create: `l10n.yaml`

- [ ] **1.1 — Edit `pubspec.yaml` `dependencies:` block**

Add `flutter_localizations` and `intl` immediately after the `flutter:` SDK dep. After the edit, the relevant section reads:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any
  cupertino_icons: ^1.0.8
  # ... rest unchanged
```

- [ ] **1.2 — Edit `pubspec.yaml` `flutter:` block**

Add `generate: true` so `flutter pub get` runs `gen-l10n`:

```yaml
flutter:
  uses-material-design: true
  generate: true
```

- [ ] **1.3 — Create `l10n.yaml` at the repo root**

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getter: false
```

- [ ] **1.4 — Run `flutter pub get` to verify the toolchain accepts the config**

Run: `flutter pub get`
Expected: completes without errors. (No ARB files exist yet, so the generator will warn or no-op — that's fine; we add ARB files in Task 2.)

- [ ] **1.5 — Commit**

```bash
git add pubspec.yaml pubspec.lock l10n.yaml
git commit -m "chore(l10n): add flutter_localizations toolchain and l10n.yaml"
```

---

### Task 2 — Author `app_en.arb` and `app_ko.arb` with the full string catalog

**Files:**
- Create: `lib/l10n/app_en.arb`
- Create: `lib/l10n/app_ko.arb`

This task ships the entire string catalog in one go. Later tasks reference these keys; doing it as one file each avoids merge churn.

- [ ] **2.1 — Create `lib/l10n/app_en.arb`**

```json
{
  "@@locale": "en",

  "appTitle": "Silvers Fun",
  "@appTitle": { "description": "Brand name. Always English." },

  "loadingTitle": "Loading",
  "stubComingSoon": "{title} — coming soon",
  "@stubComingSoon": {
    "placeholders": { "title": { "type": "String" } }
  },

  "navDiscover": "Discover",
  "navLikedYou": "Liked you",
  "navChats": "Chats",
  "navYou": "You",

  "signInTagline": "Friendly company for the next chapter.",
  "signInButton": "Continue with Google",
  "signInButtonBusy": "Signing in…",
  "signInError": "Sign-in failed. Please try again.",
  "signInTermsNote": "By continuing you agree to our Terms.",

  "onbNameTitle": "What's your name?",
  "onbNameSubtitle": "This is what people will see on your profile.",
  "onbFirstNameLabel": "First name",
  "onbAgeLabel": "Age",
  "onbAgeHelper": "Designed for adults 65+. You must be 18 or older to create an account.",

  "onbPhotoTitle": "Add a photo",
  "onbPhotoSubtitle": "Pick a clear, recent photo of you.",
  "onbPhotoChoose": "Choose from gallery",
  "onbPhotoReplace": "Replace photo",
  "onbPhotoUploading": "Uploading…",
  "onbPhotoErrorOpen": "Could not open gallery.",
  "onbPhotoErrorUpload": "Upload failed. Please try again.",

  "onbBioTitle": "Write a short bio",
  "onbBioSubtitle": "A sentence or two about you. Keep it light.",
  "onbBioHint": "I love early morning coffee, hiking on weekends…",

  "onbInterestsTitle": "Pick your interests",
  "onbInterestsSubtitle": "Choose 3 to 6 things you love.",
  "onbInterestsCounter": "{count} / 6 selected",
  "@onbInterestsCounter": {
    "placeholders": { "count": { "type": "int" } }
  },

  "onbPreviewTitle": "Preview your profile",
  "onbPreviewSubtitle": "This is how others will see you.",
  "onbPreviewPublishError": "Publish failed. Please try again.",
  "onbPreviewPublishing": "Publishing…",
  "onbPreviewPublish": "Publish",

  "actionContinue": "Continue",
  "actionSave": "Save",
  "actionSaving": "Saving…",
  "actionEdit": "Edit",
  "actionBack": "Back",

  "feedEmptyTitle": "No one to discover yet.",
  "feedEmptySubtitle": "Check back soon — new profiles are on the way.",
  "feedErrorPrefix": "Could not load feed.",

  "profileViewNotFound": "Profile not found.",
  "profileViewLike": "Like",
  "profileViewLiked": "Liked",

  "likedYouTitle": "Liked you",
  "likedYouEmptyTitle": "No one yet.",
  "likedYouEmptySubtitle": "When someone likes you, they will show up here.",
  "likedYouErrorPrefix": "Could not load likes.",

  "chatsTitle": "Chats",
  "chatsErrorPrefix": "Could not load chats.",
  "chatsHintTitle": "Say hello to a new connection",
  "chatsHintSubtitle": "Tap a friend above to start a conversation.",
  "chatsEmptyTitle": "No connections yet.",
  "chatsEmptySubtitle": "When you and someone like each other, you can chat here.",
  "chatsTimeNow": "now",
  "chatsTimeMinutes": "{n}m",
  "@chatsTimeMinutes": { "placeholders": { "n": { "type": "int" } } },
  "chatsTimeHours": "{n}h",
  "@chatsTimeHours": { "placeholders": { "n": { "type": "int" } } },
  "chatsTimeDays": "{n}d",
  "@chatsTimeDays": { "placeholders": { "n": { "type": "int" } } },

  "chatHeaderFallbackName": "Friend",
  "chatHeaderConnected": "Connected",
  "chatMessagesErrorPrefix": "Could not load messages.",
  "chatComposerHint": "Message",
  "chatMatchCardTitle": "You're now connected! 🎉",
  "chatMatchCardHelloGeneric": "Say hello to start chatting.",
  "chatMatchCardHelloNamed": "Say hello to {name} to start chatting.",
  "@chatMatchCardHelloNamed": {
    "placeholders": { "name": { "type": "String" } }
  },
  "chatSafetyReminder": "Stay safe — never share personal info, passwords, or money.",

  "youTitle": "You",
  "youSettingsTooltip": "Settings",
  "youErrorPrefix": "Could not load your profile.",
  "youStatusNotPublished": "Not published",
  "youStatusPaused": "Profile paused",
  "youStatusLive": "Profile live",
  "youPreviewProfile": "Preview profile",
  "youEditBio": "Edit bio",
  "youEmptyMessage": "Your profile is not ready yet.",

  "settingsTitle": "Settings",
  "settingsSectionProfile": "Profile",
  "settingsPauseProfile": "Pause profile",
  "settingsPauseSubtitlePaused": "Hidden from the discover feed.",
  "settingsPauseSubtitleLive": "Visible in the discover feed.",
  "settingsEditPhoto": "Edit profile photo",
  "settingsWhoCanSeeMe": "Who can see me",
  "settingsWhoCanSeeMeValue": "Everyone",
  "settingsSectionNotifications": "Notifications",
  "settingsNotifLikes": "New likes",
  "settingsNotifDigest": "Weekly digest",
  "settingsSectionAccount": "Account",
  "settingsAccountGoogle": "Connected with Google",
  "settingsAccountPrivacy": "Privacy",
  "settingsAccountHelp": "Help",
  "settingsSignOut": "Sign out",

  "editBioTitle": "Edit bio",

  "toastProfilePaused": "Profile paused",
  "toastProfileLive": "Profile live",
  "toastLikedGeneric": "Liked",
  "toastLikedNamed": "Liked {name}",
  "@toastLikedNamed": {
    "placeholders": { "name": { "type": "String" } }
  },
  "toastConnectedGeneric": "You're now connected! 🎉",
  "toastConnectedNamed": "You and {name} are now connected! 🎉",
  "@toastConnectedNamed": {
    "placeholders": { "name": { "type": "String" } }
  },

  "profileNameAge": "{name}, {age}",
  "@profileNameAge": {
    "placeholders": {
      "name": { "type": "String" },
      "age": { "type": "int" }
    }
  }
}
```

- [ ] **2.2 — Create `lib/l10n/app_ko.arb`**

```json
{
  "@@locale": "ko",

  "appTitle": "Silvers Fun",

  "loadingTitle": "불러오는 중",
  "stubComingSoon": "{title} — 준비 중이에요",

  "navDiscover": "둘러보기",
  "navLikedYou": "좋아요",
  "navChats": "대화",
  "navYou": "내 정보",

  "signInTagline": "인생의 다음 장을 함께할 친구를 만나보세요.",
  "signInButton": "Google로 계속하기",
  "signInButtonBusy": "로그인 중…",
  "signInError": "로그인에 실패했어요. 다시 시도해 주세요.",
  "signInTermsNote": "계속하시면 이용약관에 동의하시는 것입니다.",

  "onbNameTitle": "성함이 어떻게 되세요?",
  "onbNameSubtitle": "프로필에 표시되는 이름이에요.",
  "onbFirstNameLabel": "이름",
  "onbAgeLabel": "나이",
  "onbAgeHelper": "65세 이상 어르신을 위한 앱이에요. 만 18세부터 가입하실 수 있습니다.",

  "onbPhotoTitle": "사진을 올려 주세요",
  "onbPhotoSubtitle": "본인이 잘 나온 최근 사진을 골라 주세요.",
  "onbPhotoChoose": "사진첩에서 고르기",
  "onbPhotoReplace": "사진 바꾸기",
  "onbPhotoUploading": "올리는 중…",
  "onbPhotoErrorOpen": "사진첩을 열 수 없어요.",
  "onbPhotoErrorUpload": "사진을 올리지 못했어요. 다시 시도해 주세요.",

  "onbBioTitle": "자기소개를 짧게 적어 주세요",
  "onbBioSubtitle": "한두 문장이면 충분해요. 편하게 적어 주세요.",
  "onbBioHint": "아침 커피와 주말 산책을 좋아해요…",

  "onbInterestsTitle": "관심사를 골라 주세요",
  "onbInterestsSubtitle": "좋아하시는 것 3가지에서 6가지를 골라 주세요.",
  "onbInterestsCounter": "{count} / 6개 선택됨",

  "onbPreviewTitle": "프로필 미리 보기",
  "onbPreviewSubtitle": "다른 분들에게 이렇게 보여요.",
  "onbPreviewPublishError": "프로필을 올리지 못했어요. 다시 시도해 주세요.",
  "onbPreviewPublishing": "올리는 중…",
  "onbPreviewPublish": "프로필 올리기",

  "actionContinue": "계속하기",
  "actionSave": "저장",
  "actionSaving": "저장 중…",
  "actionEdit": "수정",
  "actionBack": "뒤로",

  "feedEmptyTitle": "아직 둘러볼 분이 없어요.",
  "feedEmptySubtitle": "곧 새로운 프로필이 올라올 거예요. 잠시 후 다시 와 주세요.",
  "feedErrorPrefix": "둘러보기를 불러오지 못했어요.",

  "profileViewNotFound": "프로필을 찾을 수 없어요.",
  "profileViewLike": "좋아요",
  "profileViewLiked": "좋아요 보냄",

  "likedYouTitle": "나를 좋아한 분",
  "likedYouEmptyTitle": "아직 아무도 없어요.",
  "likedYouEmptySubtitle": "누군가 좋아요를 보내면 여기에 표시돼요.",
  "likedYouErrorPrefix": "좋아요를 불러오지 못했어요.",

  "chatsTitle": "대화",
  "chatsErrorPrefix": "대화를 불러오지 못했어요.",
  "chatsHintTitle": "새로 맺어진 친구에게 인사를 건네 보세요",
  "chatsHintSubtitle": "위에 있는 친구를 눌러 대화를 시작해 보세요.",
  "chatsEmptyTitle": "아직 친구가 없어요.",
  "chatsEmptySubtitle": "서로 좋아요를 보낸 분과 여기에서 대화할 수 있어요.",
  "chatsTimeNow": "방금",
  "chatsTimeMinutes": "{n}분 전",
  "chatsTimeHours": "{n}시간 전",
  "chatsTimeDays": "{n}일 전",

  "chatHeaderFallbackName": "친구",
  "chatHeaderConnected": "친구",
  "chatMessagesErrorPrefix": "메시지를 불러오지 못했어요.",
  "chatComposerHint": "메시지 입력",
  "chatMatchCardTitle": "이제 친구가 되었어요! 🎉",
  "chatMatchCardHelloGeneric": "인사를 건네 대화를 시작해 보세요.",
  "chatMatchCardHelloNamed": "{name}님께 인사를 건네 대화를 시작해 보세요.",
  "chatSafetyReminder": "안전을 위해 개인정보, 비밀번호, 금전 거래는 절대 공유하지 마세요.",

  "youTitle": "내 프로필",
  "youSettingsTooltip": "설정",
  "youErrorPrefix": "내 프로필을 불러오지 못했어요.",
  "youStatusNotPublished": "아직 공개 전",
  "youStatusPaused": "프로필 잠시 숨김",
  "youStatusLive": "프로필 공개 중",
  "youPreviewProfile": "프로필 미리 보기",
  "youEditBio": "자기소개 수정",
  "youEmptyMessage": "프로필이 아직 준비되지 않았어요.",

  "settingsTitle": "설정",
  "settingsSectionProfile": "프로필",
  "settingsPauseProfile": "프로필 잠시 숨기기",
  "settingsPauseSubtitlePaused": "둘러보기에서 보이지 않아요.",
  "settingsPauseSubtitleLive": "둘러보기에 보여요.",
  "settingsEditPhoto": "프로필 사진 바꾸기",
  "settingsWhoCanSeeMe": "공개 범위",
  "settingsWhoCanSeeMeValue": "전체 공개",
  "settingsSectionNotifications": "알림",
  "settingsNotifLikes": "새로운 좋아요",
  "settingsNotifDigest": "주간 소식",
  "settingsSectionAccount": "계정",
  "settingsAccountGoogle": "Google 계정 연결됨",
  "settingsAccountPrivacy": "개인정보",
  "settingsAccountHelp": "도움말",
  "settingsSignOut": "로그아웃",

  "editBioTitle": "자기소개 수정",

  "toastProfilePaused": "프로필을 잠시 숨겼어요",
  "toastProfileLive": "프로필을 공개했어요",
  "toastLikedGeneric": "좋아요를 보냈어요",
  "toastLikedNamed": "{name}님께 좋아요를 보냈어요",
  "toastConnectedGeneric": "이제 친구가 되었어요! 🎉",
  "toastConnectedNamed": "{name}님과 친구가 되었어요! 🎉",

  "profileNameAge": "{name}, {age}세"
}
```

- [ ] **2.3 — Run `flutter pub get` to trigger generation**

Run: `flutter pub get`
Expected: succeeds; `.dart_tool/flutter_gen/gen_l10n/app_localizations.dart` is now generated. Verify with:

```bash
ls .dart_tool/flutter_gen/gen_l10n/app_localizations.dart
```

Expected: file exists.

- [ ] **2.4 — Run `flutter analyze`**

Run: `flutter analyze`
Expected: clean (no use-sites yet, so nothing to break).

- [ ] **2.5 — Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_ko.arb
git commit -m "feat(l10n): add English/Korean ARB string catalogs"
```

---

### Task 3 — Wire delegates into `MaterialApp` and add `context.l10n` helper

**Files:**
- Modify: `lib/main.dart`
- Create: `lib/core/extensions/l10n_extension.dart`

- [ ] **3.1 — Create `lib/core/extensions/l10n_extension.dart`**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
```

- [ ] **3.2 — Edit `lib/main.dart`**

Replace the file with:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: SilversFunApp()));
}

class SilversFunApp extends ConsumerWidget {
  const SilversFunApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
```

Notes:
- `title:` is replaced with `onGenerateTitle:` so the OS task-switcher label localizes too.
- The brand string in `app_en.arb` / `app_ko.arb` is `"Silvers Fun"` in both locales — the Korean copy intentionally keeps the English brand.

- [ ] **3.3 — Run `flutter analyze`**

Run: `flutter analyze`
Expected: clean. (`AppLocalizations` is imported but not yet used in screens — that's fine.)

- [ ] **3.4 — Run `flutter test`**

Run: `flutter test`
Expected: 65/65 still pass. (No screen has been migrated yet; tests check English literals.)

- [ ] **3.5 — Commit**

```bash
git add lib/main.dart lib/core/extensions/l10n_extension.dart
git commit -m "feat(l10n): wire AppLocalizations delegates into MaterialApp"
```

---

### Task 4 — Migrate sign-in screen

**Files:**
- Modify: `lib/features/auth/screens/sign_in_screen.dart`

- [ ] **4.1 — Edit `lib/features/auth/screens/sign_in_screen.dart`**

Add the import at the top:

```dart
import '../../../core/extensions/l10n_extension.dart';
```

Replace the literal strings as follows:

| Old | New |
|---|---|
| `_error = 'Sign-in failed. Please try again.'` (line 29) | `_error = context.l10n.signInError` (and store the localized text — but `context` isn't available in `_signIn`; resolve `final l = context.l10n;` before the `try` and use `l.signInError`) |
| `'Silvers Fun'` (line 50) | `context.l10n.appTitle` |
| `'Friendly company for the next chapter.'` (line 58) | `context.l10n.signInTagline` |
| `_busy ? 'Signing in…' : 'Continue with Google'` (line 71) | `_busy ? context.l10n.signInButtonBusy : context.l10n.signInButton` |
| `'By continuing you agree to our Terms.'` (line 77) | `context.l10n.signInTermsNote` |

Concrete `_signIn` rewrite (because the function uses `setState` not `context`):

```dart
Future<void> _signIn() async {
  final errorText = AppLocalizations.of(context).signInError;
  setState(() {
    _busy = true;
    _error = null;
  });
  try {
    await ref.read(googleAuthServiceProvider).signIn();
  } catch (e) {
    if (!mounted) return;
    setState(() => _error = errorText);
  } finally {
    if (mounted) setState(() => _busy = false);
  }
}
```

…and add `import 'package:flutter_gen/gen_l10n/app_localizations.dart';` at top (or just use `context.l10n.signInError` resolved into a local before `setState`, your call — pick one and stay consistent).

- [ ] **4.2 — Run `flutter analyze`**

Expected: clean.

- [ ] **4.3 — Run the app on an English-locale device/sim**

Run: `flutter run -d chrome` (or any device)
Expected: sign-in screen unchanged visually.

- [ ] **4.4 — Run the app with Korean locale forced**

For a one-shot dev test, temporarily force the locale by adding `locale: const Locale('ko')` to `MaterialApp.router` in `lib/main.dart`, run, verify Korean text on sign-in, then revert.
Expected:
- Tagline: 인생의 다음 장을 함께할 친구를 만나보세요.
- Button: Google로 계속하기
- Terms note: 계속하시면 이용약관에 동의하시는 것입니다.

After verifying, **revert the `locale:` override**.

- [ ] **4.5 — Commit**

```bash
git add lib/features/auth/screens/sign_in_screen.dart
git commit -m "feat(l10n): localize sign-in screen"
```

---

### Task 5 — Migrate onboarding name+age screen

**Files:**
- Modify: `lib/features/onboarding/screens/name_age_screen.dart`

- [ ] **5.1 — Edit the file**

Add import:

```dart
import '../../../core/extensions/l10n_extension.dart';
```

In the `build` method, after `final text = Theme.of(context).textTheme;` add:

```dart
final l = context.l10n;
```

Replace literals:

| Old | New |
|---|---|
| `"What's your name?"` (line 84) | `l.onbNameTitle` |
| `'This is what people will see on your profile.'` (line 91) | `l.onbNameSubtitle` |
| `labelText: 'First name'` (line 101) | `labelText: l.onbFirstNameLabel` (remove `const` from the `InputDecoration`) |
| `labelText: 'Age'` (line 116) | `labelText: l.onbAgeLabel` (remove `const` from the `InputDecoration`) |
| `'Designed for adults 65+. You must be 18 or older to create an account.'` (line 122) | `l.onbAgeHelper` |
| `_saving ? 'Saving…' : 'Continue'` (line 129) | `_saving ? l.actionSaving : l.actionContinue` |

- [ ] **5.2 — `flutter analyze`** — Expected: clean.

- [ ] **5.3 — Commit**

```bash
git add lib/features/onboarding/screens/name_age_screen.dart
git commit -m "feat(l10n): localize onboarding name+age screen"
```

---

### Task 6 — Migrate onboarding photo screen

**Files:**
- Modify: `lib/features/onboarding/screens/add_photo_screen.dart`

- [ ] **6.1 — Edit the file**

Add the l10n extension import.

`_pickAndUpload` uses `setState(() => _error = '...')` — resolve the strings before the async work:

```dart
Future<void> _pickAndUpload() async {
  final l = AppLocalizations.of(context);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || _uploading) return;

  XFile? file;
  try {
    file = await _picker.pickImage(source: ImageSource.gallery);
  } catch (e) {
    if (!mounted) return;
    setState(() => _error = l.onbPhotoErrorOpen);
    return;
  }
  if (file == null) return;

  setState(() {
    _uploading = true;
    _error = null;
  });
  try {
    final repo = ref.read(onboardingRepositoryProvider);
    final url = await repo.uploadPhoto(uid: user.uid, file: file);
    await repo.savePhotoUrl(uid: user.uid, url: url);
    if (!mounted) return;
    ref.read(onboardingFormProvider.notifier).updatePhotoUrl(url);
  } catch (e) {
    if (!mounted) return;
    setState(() => _error = l.onbPhotoErrorUpload);
  } finally {
    if (mounted) setState(() => _uploading = false);
  }
}
```

(Add `import 'package:flutter_gen/gen_l10n/app_localizations.dart';` at top.)

In `build`, replace:

| Old | New |
|---|---|
| `'Add a photo'` (line 73) | `l.onbPhotoTitle` |
| `'Pick a clear, recent photo of you.'` (line 80) | `l.onbPhotoSubtitle` |
| `_uploading ? 'Uploading…' : (form.photoUrl.isEmpty ? 'Choose from gallery' : 'Replace photo')` (lines 105–109) | `_uploading ? l.onbPhotoUploading : (form.photoUrl.isEmpty ? l.onbPhotoChoose : l.onbPhotoReplace)` |
| `label: 'Continue'` (line 128) | `label: l.actionContinue` |

(Add `final l = context.l10n;` near the top of `build`.)

- [ ] **6.2 — `flutter analyze`** — clean.

- [ ] **6.3 — Commit**

```bash
git add lib/features/onboarding/screens/add_photo_screen.dart
git commit -m "feat(l10n): localize onboarding photo screen"
```

---

### Task 7 — Migrate onboarding bio screen (both onboarding & standalone modes)

**Files:**
- Modify: `lib/features/onboarding/screens/edit_bio_screen.dart`

- [ ] **7.1 — Edit the file**

Add `final l = context.l10n;` at the top of `build` (and import the extension).

Replacements:

| Old | New |
|---|---|
| `const Text('Edit bio')` (line 88, AppBar) | `Text(l.editBioTitle)` (drop `const`) |
| `_saving ? 'Saving…' : 'Save'` (line 93) | `_saving ? l.actionSaving : l.actionSave` |
| `'Write a short bio'` (line 134) | `l.onbBioTitle` |
| `'A sentence or two about you. Keep it light.'` (line 141) | `l.onbBioSubtitle` |
| `_saving ? 'Saving…' : 'Continue'` (line 153) | `_saving ? l.actionSaving : l.actionContinue` |

In `_BioEditor.build`, add `final l = context.l10n;`, then replace:

| Old | New |
|---|---|
| `hintText: 'I love early morning coffee, hiking on weekends…'` (line 198) | `hintText: l.onbBioHint` (drop `const` from `InputDecoration`) |

The `'$length / $_bioLimit'` counter at line 211 stays as-is — it's pure formatting, language-neutral.

- [ ] **7.2 — `flutter analyze`** — clean.

- [ ] **7.3 — Commit**

```bash
git add lib/features/onboarding/screens/edit_bio_screen.dart
git commit -m "feat(l10n): localize bio editor (onboarding + standalone)"
```

---

### Task 8 — Migrate onboarding interests screen

**Files:**
- Modify: `lib/features/onboarding/screens/interests_screen.dart`

- [ ] **8.1 — Edit the file**

Add the l10n extension import + `final l = context.l10n;` in `build`.

| Old | New |
|---|---|
| `'Pick your interests'` (line 60) | `l.onbInterestsTitle` |
| `'Choose 3 to 6 things you love.'` (line 67) | `l.onbInterestsSubtitle` |
| `'$count / 6 selected'` (line 72) | `l.onbInterestsCounter(count)` |
| `_saving ? 'Saving…' : 'Continue'` (line 99) | `_saving ? l.actionSaving : l.actionContinue` |

> Note: chip labels (`kInterestPool`) stay English in this sprint — see Non-goals.

- [ ] **8.2 — `flutter analyze`** — clean.

- [ ] **8.3 — Commit**

```bash
git add lib/features/onboarding/screens/interests_screen.dart
git commit -m "feat(l10n): localize onboarding interests screen"
```

---

### Task 9 — Migrate onboarding preview screen

**Files:**
- Modify: `lib/features/onboarding/screens/preview_screen.dart`

- [ ] **9.1 — Edit the file**

Resolve strings before async in `_onPublish`:

```dart
Future<void> _onPublish() async {
  final l = AppLocalizations.of(context);
  // ...existing setState...
  } catch (e) {
    if (!mounted) return;
    setState(() => _error = l.onbPreviewPublishError);
  }
  // ...
}
```

In `build`, add `final l = context.l10n;`:

| Old | New |
|---|---|
| `'Preview your profile'` (line 65) | `l.onbPreviewTitle` |
| `"This is how others will see you."` (line 72) | `l.onbPreviewSubtitle` |
| `label: 'Edit'` (line 100) | `label: l.actionEdit` |
| `_publishing ? 'Publishing…' : 'Publish'` (line 110) | `_publishing ? l.onbPreviewPublishing : l.onbPreviewPublish` |

In `_ProfileCardPreview.build`, the line `age == null ? name : '$name, $age'` (line 166) becomes:

```dart
age == null ? name : context.l10n.profileNameAge(name, age!),
```

This handles Korean's "name, 나이세" formatting via the ARB placeholder.

- [ ] **9.2 — `flutter analyze`** — clean.

- [ ] **9.3 — Commit**

```bash
git add lib/features/onboarding/screens/preview_screen.dart
git commit -m "feat(l10n): localize onboarding preview screen"
```

---

### Task 10 — Migrate feed screen + main shell tabs

**Files:**
- Modify: `lib/features/feed/screens/feed_screen.dart`
- Modify: `lib/core/widgets/main_shell.dart`

#### 10A — Feed screen

- [ ] **10.1 — Edit `feed_screen.dart`**

Add l10n extension import + `final l = context.l10n;` in `FeedScreen.build`.

| Old | New |
|---|---|
| `'Discover'` (line 25, AppBar title) | `l.navDiscover` |
| `'Could not load feed.\n$e'` (line 35) | `'${l.feedErrorPrefix}\n$e'` |

In `_ProfileCard.build`, replace name/age formatting (line 124):

```dart
profile.age > 0
    ? context.l10n.profileNameAge(profile.name, profile.age)
    : profile.name,
```

In `_EmptyState.build` (line 187 onward), add `final l = context.l10n;`, then:

| Old | New |
|---|---|
| `'No one to discover yet.'` | `l.feedEmptyTitle` |
| `'Check back soon — new profiles are on the way.'` | `l.feedEmptySubtitle` (drop `const Text(...)` — use `Text(l.feedEmptySubtitle, ...)`) |

#### 10B — Main shell tab labels

- [ ] **10.2 — Edit `lib/core/widgets/main_shell.dart`**

The current `_TabSpec` has hard-coded labels in a `const` list. We change to a function that returns labels at build time.

Replace the `_TabSpec` and `_tabs` definitions with:

```dart
class _TabSpec {
  final String location;
  final String Function(AppLocalizations l) label;
  final IconData icon;
  final IconData selectedIcon;

  const _TabSpec({
    required this.location,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

const List<_TabSpec> _tabs = [
  _TabSpec(
    location: '/app/feed',
    label: _labelDiscover,
    icon: Icons.explore_outlined,
    selectedIcon: Icons.explore,
  ),
  _TabSpec(
    location: '/app/liked-you',
    label: _labelLikedYou,
    icon: Icons.favorite_outline,
    selectedIcon: Icons.favorite,
  ),
  _TabSpec(
    location: '/app/chats',
    label: _labelChats,
    icon: Icons.chat_bubble_outline,
    selectedIcon: Icons.chat_bubble,
  ),
  _TabSpec(
    location: '/app/you',
    label: _labelYou,
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];

String _labelDiscover(AppLocalizations l) => l.navDiscover;
String _labelLikedYou(AppLocalizations l) => l.navLikedYou;
String _labelChats(AppLocalizations l) => l.navChats;
String _labelYou(AppLocalizations l) => l.navYou;
```

(Tear-off references like `_labelDiscover` work as `const` initializers in Dart 3.)

In `MainShell.build`, after `final loc = ...`:

```dart
final l = AppLocalizations.of(context);
```

In `_buildDestination`, change `label: t.label` to `label: t.label(l)`. Update the method signature to take `AppLocalizations l`:

```dart
NavigationDestination _buildDestination(
  _TabSpec t, {
  required int badgeCount,
  required AppLocalizations l,
}) { ... label: t.label(l) ... }
```

And pass `l: l` from the `for` loop in `build`.

Add `import 'package:flutter_gen/gen_l10n/app_localizations.dart';` at the top.

- [ ] **10.3 — `flutter analyze`** — clean.

- [ ] **10.4 — Commit**

```bash
git add lib/features/feed/screens/feed_screen.dart lib/core/widgets/main_shell.dart
git commit -m "feat(l10n): localize discover feed and main bottom-nav labels"
```

---

### Task 11 — Migrate profile-view screen

**Files:**
- Modify: `lib/features/feed/screens/profile_view_screen.dart`

- [ ] **11.1 — Edit the file**

Add l10n extension import. In `ProfileViewScreen.build`, after `final isLiked = ...`, add `final l = context.l10n;`.

| Old | New |
|---|---|
| `'Profile not found.'` (line 32, passed as `error: '...'`) | `l.profileViewNotFound` |

In `_ProfileBody.build`, add `final l = AppLocalizations.of(context);` after `final theme = Theme.of(context);`.

| Old | New |
|---|---|
| `profile.age > 0 ? '${profile.name}, ${profile.age}' : profile.name` (line 86) | `profile.age > 0 ? l.profileNameAge(profile.name, profile.age) : profile.name` |
| `label: 'Back'` (line 140) | `label: l.actionBack` |
| `isLiked ? 'Liked' : 'Like'` (line 149) | `isLiked ? l.profileViewLiked : l.profileViewLike` |

`_ErrorBody` renders `error.toString()` — leave alone (the literal `'Profile not found.'` is now the localized string we passed in).

Add `import 'package:flutter_gen/gen_l10n/app_localizations.dart';`.

- [ ] **11.2 — `flutter analyze`** — clean.

- [ ] **11.3 — Commit**

```bash
git add lib/features/feed/screens/profile_view_screen.dart
git commit -m "feat(l10n): localize profile detail view"
```

---

### Task 12 — Migrate liked-you screen

**Files:**
- Modify: `lib/features/profile/screens/liked_you_screen.dart`

- [ ] **12.1 — Edit the file**

Add l10n extension import. In `LikedYouScreen.build`, add `final l = context.l10n;`.

| Old | New |
|---|---|
| `'Liked you'` (line 22, AppBar title) | `l.likedYouTitle` |
| `'Could not load likes.\n$e'` (line 32) | `'${l.likedYouErrorPrefix}\n$e'` |

In `_LikerCard.build`, add `final l = context.l10n;`:

| Old | New |
|---|---|
| `profile.age > 0 ? '${profile.name}, ${profile.age}' : profile.name` (line 90) | `profile.age > 0 ? l.profileNameAge(profile.name, profile.age) : profile.name` |

In `_EmptyState.build`, add `final l = context.l10n;`:

| Old | New |
|---|---|
| `'No one yet.'` (line 180) | `l.likedYouEmptyTitle` |
| `'When someone likes you, they will show up here.'` (line 185) | `l.likedYouEmptySubtitle` (drop `const Text(...)`) |

- [ ] **12.2 — `flutter analyze`** — clean.

- [ ] **12.3 — Commit**

```bash
git add lib/features/profile/screens/liked_you_screen.dart
git commit -m "feat(l10n): localize liked-you screen"
```

---

### Task 13 — Migrate chat list screen + time formatter

**Files:**
- Modify: `lib/features/chat/screens/chat_list_screen.dart`

- [ ] **13.1 — Edit `chat_list_screen.dart`**

Add l10n extension import + `final l = context.l10n;` in `ChatListScreen.build`.

Top-level `_formatTime(DateTime)` becomes `_formatTime(BuildContext context, DateTime sentAt)` so it has access to `l10n`:

```dart
String _formatTime(BuildContext context, DateTime sentAt) {
  final l = AppLocalizations.of(context);
  final now = DateTime.now();
  final diff = now.difference(sentAt);
  if (diff.inMinutes < 1) return l.chatsTimeNow;
  if (diff.inMinutes < 60) return l.chatsTimeMinutes(diff.inMinutes);
  if (diff.inHours < 24) return l.chatsTimeHours(diff.inHours);
  if (diff.inDays < 7) return l.chatsTimeDays(diff.inDays);
  return '${sentAt.month}/${sentAt.day}';
}
```

In `_ThreadRow.build`, change `_formatTime(last!.sentAt!)` (line 195) to `_formatTime(context, last!.sentAt!)`.

| Old | New |
|---|---|
| `'Chats'` (line 21, AppBar title) | `l.chatsTitle` |
| `'Could not load chats.\n$e'` (line 31) | `'${l.chatsErrorPrefix}\n$e'` |

In `_NoConversationsHint.build`, add `final l = context.l10n;`:

| Old | New |
|---|---|
| `'Say hello to a new connection'` (line 267) | `l.chatsHintTitle` |
| `'Tap a friend above to start a conversation.'` (line 272) | `l.chatsHintSubtitle` (drop `const Text(...)`) |

In `_EmptyState.build`, add `final l = context.l10n;`:

| Old | New |
|---|---|
| `'No connections yet.'` (line 294) | `l.chatsEmptyTitle` |
| `'When you and someone like each other, you can chat here.'` (line 299) | `l.chatsEmptySubtitle` |

- [ ] **13.2 — `flutter analyze`** — clean.

- [ ] **13.3 — Commit**

```bash
git add lib/features/chat/screens/chat_list_screen.dart
git commit -m "feat(l10n): localize chat list and relative time formatter"
```

---

### Task 14 — Migrate chat thread screen (incl. safety reminder)

**Files:**
- Modify: `lib/features/chat/screens/chat_screen.dart`

- [ ] **14.1 — Edit the file**

Add l10n extension import.

In `_Header.build`, add `final l = AppLocalizations.of(context);`:

| Old | New |
|---|---|
| `name.isEmpty ? 'Friend' : name` (line 192) | `name.isEmpty ? l.chatHeaderFallbackName : name` |
| `const Text('Connected', ...)` (line 199) | `Text(l.chatHeaderConnected, ...)` (drop `const` on the wrapping `Text` and on the surrounding `Column`'s constants where needed) |

In `_MatchCard.build`, add `final l = AppLocalizations.of(context);`:

| Old | New |
|---|---|
| `"You're now connected! 🎉"` (line 286) | `l.chatMatchCardTitle` |
| `name.isEmpty ? 'Say hello to start chatting.' : 'Say hello to $name to start chatting.'` (lines 293–295) | `name.isEmpty ? l.chatMatchCardHelloGeneric : l.chatMatchCardHelloNamed(name)` |
| `'Stay safe — never share personal info, passwords, or money.'` (line 310) | `l.chatSafetyReminder` |

In `_ChatScreenState.build`, in the error branch:

| Old | New |
|---|---|
| `'Could not load messages.\n$e'` (line 128) | `'${context.l10n.chatMessagesErrorPrefix}\n$e'` |

In `_SendBar.build` (or directly in the `TextField` `InputDecoration`):

```dart
decoration: InputDecoration(
  hintText: AppLocalizations.of(context).chatComposerHint,
  hintStyle: const TextStyle(color: AppColors.muted),
  // ... rest unchanged, but drop the outer `const InputDecoration(`
),
```

Add `import 'package:flutter_gen/gen_l10n/app_localizations.dart';`.

- [ ] **14.2 — `flutter analyze`** — clean.

- [ ] **14.3 — Commit**

```bash
git add lib/features/chat/screens/chat_screen.dart
git commit -m "feat(l10n): localize chat thread + safety reminder + composer"
```

---

### Task 15 — Migrate You screen

**Files:**
- Modify: `lib/features/profile/screens/you_screen.dart`

- [ ] **15.1 — Edit the file**

Add l10n extension import + `final l = context.l10n;` in `YouScreen.build`.

| Old | New |
|---|---|
| `'You'` (line 22, AppBar title) | `l.youTitle` |
| `tooltip: 'Settings'` (line 25) | `tooltip: l.youSettingsTooltip` |
| `'Could not load your profile.\n$e'` (line 37) | `'${l.youErrorPrefix}\n$e'` |

In `_YouBody.build`, add `final l = AppLocalizations.of(context);`:

| Old | New |
|---|---|
| `!published ? 'Not published' : (paused ? 'Profile paused' : 'Profile live')` (lines 65–67) | `!published ? l.youStatusNotPublished : (paused ? l.youStatusPaused : l.youStatusLive)` |
| `profile.age > 0 ? '${profile.name}, ${profile.age}' : profile.name` (line 89) | `profile.age > 0 ? l.profileNameAge(profile.name, profile.age) : profile.name` |
| `label: 'Preview profile'` (line 143) | `label: l.youPreviewProfile` |
| `label: 'Edit bio'` (line 151) | `label: l.youEditBio` |

In `_EmptyState.build`, add `final l = context.l10n;`:

| Old | New |
|---|---|
| `'Your profile is not ready yet.'` (line 169) | `l.youEmptyMessage` |

Add `import 'package:flutter_gen/gen_l10n/app_localizations.dart';`.

- [ ] **15.2 — `flutter analyze`** — clean.

- [ ] **15.3 — Commit**

```bash
git add lib/features/profile/screens/you_screen.dart
git commit -m "feat(l10n): localize You screen"
```

---

### Task 16 — Migrate settings screen + paused/live toast

**Files:**
- Modify: `lib/features/profile/screens/settings_screen.dart`

- [ ] **16.1 — Edit the file**

In `_onTogglePause`, resolve strings before async work:

```dart
Future<void> _onTogglePause(bool nextValue) async {
  final l = AppLocalizations.of(context);
  // ...
  showToast(ref, nextValue ? l.toastProfilePaused : l.toastProfileLive);
  // ...
}
```

In `build`, add `final l = context.l10n;`:

| Old | New |
|---|---|
| `'Settings'` (line 57) | `l.settingsTitle` |
| `_SectionTitle('Profile')` (line 66) | `_SectionTitle(l.settingsSectionProfile)` |
| `'Pause profile'` (line 72) | `l.settingsPauseProfile` |
| `paused ? 'Hidden from the discover feed.' : 'Visible in the discover feed.'` (lines 74–76) | `paused ? l.settingsPauseSubtitlePaused : l.settingsPauseSubtitleLive` |
| `'Edit profile photo'` (line 83) | `l.settingsEditPhoto` |
| `'Who can see me'` (line 88) | `l.settingsWhoCanSeeMe` |
| `'Everyone'` (line 90) | `l.settingsWhoCanSeeMeValue` |
| `_SectionTitle('Notifications')` (line 98) | `_SectionTitle(l.settingsSectionNotifications)` |
| `_UiOnlyToggleRow(label: 'New likes')` (line 101) | `_UiOnlyToggleRow(label: l.settingsNotifLikes)` |
| `_UiOnlyToggleRow(label: 'Weekly digest', initial: false)` (line 103) | `_UiOnlyToggleRow(label: l.settingsNotifDigest, initial: false)` |
| `_SectionTitle('Account')` (line 107) | `_SectionTitle(l.settingsSectionAccount)` |
| `'Connected with Google'` (line 111) | `l.settingsAccountGoogle` |
| `'Privacy'` (line 116) | `l.settingsAccountPrivacy` |
| `'Help'` (line 121) | `l.settingsAccountHelp` |

(Many of these are inside `const ListTile(...)` blocks. Drop the `const` on those ListTiles since their `Text` children become non-const.)

In `_SignOutButton.build`, add `final l = AppLocalizations.of(context);`:

| Old | New |
|---|---|
| `'Sign out'` (line 232) | `l.settingsSignOut` |

Also drop the `const` constructors on the `_UiOnlyToggleRow` initializers (or keep them; `_UiOnlyToggleRow` already accepts a non-const `String`, so the issue is the wrapping list which is fine to keep `const` if its members allow).

Add `import 'package:flutter_gen/gen_l10n/app_localizations.dart';` and the extension import.

- [ ] **16.2 — `flutter analyze`** — clean.

- [ ] **16.3 — Commit**

```bash
git add lib/features/profile/screens/settings_screen.dart
git commit -m "feat(l10n): localize settings screen and pause/live toast"
```

---

### Task 17 — Refactor `LikesController.toggleLike` to return `LikeOutcome`, localize toast at call sites

**Files:**
- Modify: `lib/features/feed/providers/likes_provider.dart`
- Modify: `lib/features/feed/screens/feed_screen.dart`
- Modify: `lib/features/feed/screens/profile_view_screen.dart`

The current toggle calls `showToastFromRef` from inside a provider with hard-coded English strings. Providers don't have `BuildContext`, so we move the toast to call sites.

- [ ] **17.1 — Edit `lib/features/feed/providers/likes_provider.dart`**

Replace the controller. After:

```dart
class LikesController {
  final Ref _ref;

  LikesController(this._ref);

  // ...
}
```

…with:

```dart
enum LikeOutcomeKind { unliked, liked, connected }

class LikeOutcome {
  final LikeOutcomeKind kind;
  final String partnerName;

  const LikeOutcome(this.kind, this.partnerName);
}

class LikesController {
  final Ref _ref;

  LikesController(this._ref);

  Future<LikeOutcome> toggleLike(String targetUid) async {
    final user = _ref.read(authProvider).valueOrNull;
    if (user == null || user.uid == targetUid) {
      return const LikeOutcome(LikeOutcomeKind.unliked, '');
    }

    final repo = _ref.read(likesRepositoryProvider);
    final liked =
        _ref.read(likedByMeProvider).valueOrNull ?? const <String>{};
    final isLiked = liked.contains(targetUid);

    if (isLiked) {
      await repo.unlike(user.uid, targetUid);
      return const LikeOutcome(LikeOutcomeKind.unliked, '');
    }

    await repo.like(user.uid, targetUid);

    final mutual = await repo.isMutual(
      fromUid: user.uid,
      toUid: targetUid,
    );

    final profile =
        await _ref.read(feedRepositoryProvider).getUser(targetUid);
    final name = profile?.name ?? '';

    return LikeOutcome(
      mutual ? LikeOutcomeKind.connected : LikeOutcomeKind.liked,
      name,
    );
  }
}
```

Remove the `import '../../../core/providers/toast_provider.dart';` and the `showToastFromRef(...)` calls — the controller no longer touches the toast pipeline.

- [ ] **17.2 — Edit `lib/features/feed/screens/feed_screen.dart`**

In `_ProfileCard`, the `onLike` callback is currently a `VoidCallback`. Change the field/constructor + the call site:

```dart
class _ProfileCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onTap;
  final Future<void> Function() onLike;
  // ...
}
```

In `FeedScreen.build`, replace:

```dart
onLike: () =>
    ref.read(likesControllerProvider).toggleLike(profile.uid),
```

…with:

```dart
onLike: () async {
  final l = context.l10n;
  final outcome = await ref
      .read(likesControllerProvider)
      .toggleLike(profile.uid);
  if (!context.mounted) return;
  switch (outcome.kind) {
    case LikeOutcomeKind.connected:
      showToast(
        ref,
        outcome.partnerName.isEmpty
            ? l.toastConnectedGeneric
            : l.toastConnectedNamed(outcome.partnerName),
      );
      break;
    case LikeOutcomeKind.liked:
      showToast(
        ref,
        outcome.partnerName.isEmpty
            ? l.toastLikedGeneric
            : l.toastLikedNamed(outcome.partnerName),
      );
      break;
    case LikeOutcomeKind.unliked:
      break;
  }
},
```

Add at top:

```dart
import '../../../core/providers/toast_provider.dart';
import '../providers/likes_provider.dart' show LikeOutcomeKind;
```

(`likesControllerProvider` is already imported.)

In `HeartButton`'s `onTap` (still a `VoidCallback`), wrap if needed; otherwise leave the existing tap-bridge in `_ProfileCard.build` lines 109–112 as-is, since `HeartButton.onTap` accepts `VoidCallback` — call `() => onLike()` from a sync wrapper:

```dart
HeartButton(
  liked: profile.liked,
  onTap: onLike,
),
```

`HeartButton.onTap` accepting `Future<void> Function()` works because Dart treats it as a `VoidCallback`-compatible (returns Future are fine). If it doesn't compile, change `_ProfileCard.onLike` back to `VoidCallback` and have the closure `() { _doLike(); }` invoke an internal async helper.

- [ ] **17.3 — Edit `lib/features/feed/screens/profile_view_screen.dart`**

`_ProfileBody.onToggleLike` is `VoidCallback`. Same treatment — change to `Future<void> Function()` (or wrap in a sync closure that fires-and-forgets). Where the screen builds it:

```dart
onToggleLike: () async {
  final l = context.l10n;
  final outcome = await ref
      .read(likesControllerProvider)
      .toggleLike(profile.uid);
  if (!context.mounted) return;
  switch (outcome.kind) {
    case LikeOutcomeKind.connected:
      showToast(
        ref,
        outcome.partnerName.isEmpty
            ? l.toastConnectedGeneric
            : l.toastConnectedNamed(outcome.partnerName),
      );
      break;
    case LikeOutcomeKind.liked:
      showToast(
        ref,
        outcome.partnerName.isEmpty
            ? l.toastLikedGeneric
            : l.toastLikedNamed(outcome.partnerName),
      );
      break;
    case LikeOutcomeKind.unliked:
      break;
  }
},
```

Add the same imports as in `feed_screen.dart`.

- [ ] **17.4 — `flutter analyze`** — clean.

- [ ] **17.5 — `flutter test` to make sure nothing in `likes_repository_test.dart` regresses** — Expected: same green count. The tests target `LikesRepository`, not the controller, so they should be unaffected.

- [ ] **17.6 — Commit**

```bash
git add lib/features/feed/providers/likes_provider.dart \
        lib/features/feed/screens/feed_screen.dart \
        lib/features/feed/screens/profile_view_screen.dart
git commit -m "refactor(likes): return LikeOutcome so toast text can localize at call site"
```

---

### Task 18 — Migrate stub screen

**Files:**
- Modify: `lib/core/widgets/stub_screen.dart`

- [ ] **18.1 — Edit the file**

The current `StubScreen` takes a hardcoded `title` (`'Loading'` is the only call site, in `router.dart`). Make it accept either a localized title resolved by the caller or fall back to a localization key. Simplest: keep `title` but resolve it from `context.l10n.loadingTitle` at the only call site.

Edit the call site `lib/core/router/router.dart` line 70:

```dart
GoRoute(
  path: '/',
  builder: (context, _) => StubScreen(title: AppLocalizations.of(context).loadingTitle),
),
```

Add `import 'package:flutter_gen/gen_l10n/app_localizations.dart';` to `router.dart`.

In `lib/core/widgets/stub_screen.dart`, the body becomes:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../theme/app_colors.dart';

class StubScreen extends StatelessWidget {
  final String title;

  const StubScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          l.stubComingSoon(title),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.muted,
              ),
        ),
      ),
    );
  }
}
```

- [ ] **18.2 — `flutter analyze`** — clean.

- [ ] **18.3 — Commit**

```bash
git add lib/core/widgets/stub_screen.dart lib/core/router/router.dart
git commit -m "feat(l10n): localize stub screen and loading route title"
```

---

### Task 19 — Update widget tests for localization

**Files:**
- Modify: `test/core/widgets/main_shell_test.dart`
- Modify: `test/features/profile/you_screen_test.dart`
- Modify: `test/core/widgets/toast_overlay_test.dart`

The MainShell test currently checks for `'Discover'`, `'Liked you'`, `'Chats'`, `'You'` literals. After Task 10, those labels come from `AppLocalizations`, which means the `MaterialApp.router` in the test harness needs the localizations delegates registered. We pin the test locale to `en` so the assertions stay textually unchanged.

- [ ] **19.1 — Edit `test/core/widgets/main_shell_test.dart`**

Add imports:

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
```

In `_harness`, change the `MaterialApp.router(...)` call to:

```dart
return ProviderScope(
  overrides: [
    matchThreadsProvider.overrideWith((ref) => Stream.value(threads)),
    likedByOthersProvider.overrideWith((ref) => Stream.value(likers)),
  ],
  child: MaterialApp.router(
    routerConfig: router,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  ),
);
```

The existing `find.text('Discover')`, `find.text('Liked you')`, `find.text('Chats')`, `find.text('You')` assertions remain valid because `Locale('en')` resolves them to the same strings.

- [ ] **19.2 — Edit `test/features/profile/you_screen_test.dart`**

Same delegate wiring. Replace the `MaterialApp(home: YouScreen())` with:

```dart
MaterialApp(
  home: const YouScreen(),
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
),
```

The asserted strings `'Profile live'`, `'Profile paused'`, `'Reads in cafes.'`, `'Coffee'`, `'Reading'`, `'Edit bio'`, `'Maya, 31'` continue to match the English ARB content. (Note: `'Maya, 31'` comes from `profileNameAge(name, age)` whose English template is `"{name}, {age}"` — produces `"Maya, 31"` exactly. Korean is `"{name}, {age}세"` — would produce `"Maya, 31세"`.)

Add the imports.

- [ ] **19.3 — Edit `test/core/widgets/toast_overlay_test.dart`**

The toast overlay test passes raw strings like `'Liked Maya'` as toast state; nothing in the toast pipeline calls `AppLocalizations`. Strictly speaking no change is required, but for consistency add the same delegate wiring + `locale: const Locale('en')`. Otherwise leave untouched.

(Optional. If the test passes without changes, you can skip 19.3.)

- [ ] **19.4 — Run `flutter test`**

Run: `flutter test`
Expected: 65/65 still pass (or 65 + any new tests from Task 20).

- [ ] **19.5 — Commit**

```bash
git add test/core/widgets/main_shell_test.dart \
        test/features/profile/you_screen_test.dart \
        test/core/widgets/toast_overlay_test.dart
git commit -m "test(l10n): wire AppLocalizations delegates into widget test harnesses"
```

---

### Task 20 — Add `LikesController` outcome test

**Files:**
- Create: `test/features/feed/likes_controller_test.dart`

This test verifies the new `toggleLike` contract introduced in Task 17.

- [ ] **20.1 — Create the test file**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silver_fun/features/auth/providers/auth_provider.dart';
import 'package:silver_fun/features/feed/providers/feed_provider.dart';
import 'package:silver_fun/features/feed/providers/likes_provider.dart';
import 'package:silver_fun/features/feed/repository/feed_repository.dart';
import 'package:silver_fun/features/feed/repository/likes_repository.dart';
import 'package:silver_fun/models/user_profile.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late ProviderContainer container;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'me', email: 'me@example.com'),
    );

    // Seed the partner profile so feedRepository.getUser returns a name.
    await firestore.collection('users').doc('partner').set({
      'name': 'Sora',
      'age': 70,
      'bio': '',
      'photoUrl': '',
      'interests': <String>[],
      'city': '',
      'published': true,
      'profilePaused': false,
    });

    container = ProviderContainer(overrides: [
      firestoreProvider.overrideWithValue(firestore),
      authProvider.overrideWith(
        (ref) => Stream<User?>.value(auth.currentUser),
      ),
      likedByMeProvider.overrideWith(
        (ref) => Stream<Set<String>>.value(const <String>{}),
      ),
    ]);
  });

  tearDown(() => container.dispose());

  test('toggleLike on a non-mutual like returns LikeOutcomeKind.liked + name',
      () async {
    final controller = container.read(likesControllerProvider);
    final outcome = await controller.toggleLike('partner');
    expect(outcome.kind, LikeOutcomeKind.liked);
    expect(outcome.partnerName, 'Sora');
  });

  test('toggleLike on a mutual like returns LikeOutcomeKind.connected',
      () async {
    // Pre-write the reverse like so partner→me already exists.
    await firestore
        .collection('likes')
        .doc('partner')
        .collection('liked')
        .doc('me')
        .set({'createdAt': FieldValue.serverTimestamp()});
    await firestore
        .collection('likedBy')
        .doc('me')
        .collection('from')
        .doc('partner')
        .set({'createdAt': FieldValue.serverTimestamp()});

    final controller = container.read(likesControllerProvider);
    final outcome = await controller.toggleLike('partner');
    expect(outcome.kind, LikeOutcomeKind.connected);
    expect(outcome.partnerName, 'Sora');
  });
}
```

> If the actual `firestoreProvider` has a different exposed name than `firestoreProvider`, look it up in `lib/features/feed/providers/feed_provider.dart` and use that exact symbol. (At time of plan writing, `feed_provider.dart` exposes `firestoreProvider` — confirm before coding.)

- [ ] **20.2 — Run the new test**

Run: `flutter test test/features/feed/likes_controller_test.dart`
Expected: 2/2 pass.

- [ ] **20.3 — Run the full suite**

Run: `flutter test`
Expected: full suite green (≥ 67 tests counting the 2 new ones).

- [ ] **20.4 — Commit**

```bash
git add test/features/feed/likes_controller_test.dart
git commit -m "test(likes): cover new LikeOutcome contract for liked + connected"
```

---

### Task 21 — Manual QA on device(s)

**Files:** none (verification step).

- [ ] **21.1 — Run on Android with system language English**

Run: `flutter run -d <android-device>`
Verify visually: every screen shows the same English copy as before this sprint. Spot-check sign-in tagline, onboarding helper line, settings rows, toast on like, chat safety reminder.

- [ ] **21.2 — Switch the device system language to Korean (한국어) and reopen the app**

Verify visually using the Korean strings in the **English/Korean copy table** below.

- [ ] **21.3 — Run on Chrome (web QA target) with browser locale switched to `ko-KR`**

Run: `flutter run -d chrome`
In Chrome devtools → "Sensors" or `chrome://settings/languages`, prefer `ko-KR`. Reload the app and verify Korean copy on sign-in / onboarding.

- [ ] **21.4 — Final verification commands**

Run: `flutter analyze && flutter test`
Expected: clean analyze, full suite green.

- [ ] **21.5 — Final commit (only if anything fell out of QA)**

If QA surfaced typos or wording fixes, edit the ARB files and:

```bash
git add lib/l10n/app_en.arb lib/l10n/app_ko.arb
git commit -m "fix(l10n): polish copy after manual QA"
```

---

## English/Korean copy table for key strings

| Key | English | Korean |
|---|---|---|
| `appTitle` | Silvers Fun | Silvers Fun |
| `loadingTitle` | Loading | 불러오는 중 |
| `navDiscover` | Discover | 둘러보기 |
| `navLikedYou` | Liked you | 좋아요 |
| `navChats` | Chats | 대화 |
| `navYou` | You | 내 정보 |
| `signInTagline` | Friendly company for the next chapter. | 인생의 다음 장을 함께할 친구를 만나보세요. |
| `signInButton` | Continue with Google | Google로 계속하기 |
| `signInButtonBusy` | Signing in… | 로그인 중… |
| `signInError` | Sign-in failed. Please try again. | 로그인에 실패했어요. 다시 시도해 주세요. |
| `signInTermsNote` | By continuing you agree to our Terms. | 계속하시면 이용약관에 동의하시는 것입니다. |
| `onbNameTitle` | What's your name? | 성함이 어떻게 되세요? |
| `onbNameSubtitle` | This is what people will see on your profile. | 프로필에 표시되는 이름이에요. |
| `onbFirstNameLabel` | First name | 이름 |
| `onbAgeLabel` | Age | 나이 |
| `onbAgeHelper` | Designed for adults 65+. You must be 18 or older to create an account. | 65세 이상 어르신을 위한 앱이에요. 만 18세부터 가입하실 수 있습니다. |
| `onbPhotoTitle` | Add a photo | 사진을 올려 주세요 |
| `onbPhotoSubtitle` | Pick a clear, recent photo of you. | 본인이 잘 나온 최근 사진을 골라 주세요. |
| `onbPhotoChoose` | Choose from gallery | 사진첩에서 고르기 |
| `onbPhotoReplace` | Replace photo | 사진 바꾸기 |
| `onbPhotoUploading` | Uploading… | 올리는 중… |
| `onbPhotoErrorOpen` | Could not open gallery. | 사진첩을 열 수 없어요. |
| `onbPhotoErrorUpload` | Upload failed. Please try again. | 사진을 올리지 못했어요. 다시 시도해 주세요. |
| `onbBioTitle` | Write a short bio | 자기소개를 짧게 적어 주세요 |
| `onbBioSubtitle` | A sentence or two about you. Keep it light. | 한두 문장이면 충분해요. 편하게 적어 주세요. |
| `onbBioHint` | I love early morning coffee, hiking on weekends… | 아침 커피와 주말 산책을 좋아해요… |
| `onbInterestsTitle` | Pick your interests | 관심사를 골라 주세요 |
| `onbInterestsSubtitle` | Choose 3 to 6 things you love. | 좋아하시는 것 3가지에서 6가지를 골라 주세요. |
| `onbInterestsCounter` | {count} / 6 selected | {count} / 6개 선택됨 |
| `onbPreviewTitle` | Preview your profile | 프로필 미리 보기 |
| `onbPreviewSubtitle` | This is how others will see you. | 다른 분들에게 이렇게 보여요. |
| `onbPreviewPublishError` | Publish failed. Please try again. | 프로필을 올리지 못했어요. 다시 시도해 주세요. |
| `onbPreviewPublishing` | Publishing… | 올리는 중… |
| `onbPreviewPublish` | Publish | 프로필 올리기 |
| `actionContinue` | Continue | 계속하기 |
| `actionSave` | Save | 저장 |
| `actionSaving` | Saving… | 저장 중… |
| `actionEdit` | Edit | 수정 |
| `actionBack` | Back | 뒤로 |
| `feedEmptyTitle` | No one to discover yet. | 아직 둘러볼 분이 없어요. |
| `feedEmptySubtitle` | Check back soon — new profiles are on the way. | 곧 새로운 프로필이 올라올 거예요. 잠시 후 다시 와 주세요. |
| `feedErrorPrefix` | Could not load feed. | 둘러보기를 불러오지 못했어요. |
| `profileViewNotFound` | Profile not found. | 프로필을 찾을 수 없어요. |
| `profileViewLike` | Like | 좋아요 |
| `profileViewLiked` | Liked | 좋아요 보냄 |
| `likedYouTitle` | Liked you | 나를 좋아한 분 |
| `likedYouEmptyTitle` | No one yet. | 아직 아무도 없어요. |
| `likedYouEmptySubtitle` | When someone likes you, they will show up here. | 누군가 좋아요를 보내면 여기에 표시돼요. |
| `likedYouErrorPrefix` | Could not load likes. | 좋아요를 불러오지 못했어요. |
| `chatsTitle` | Chats | 대화 |
| `chatsErrorPrefix` | Could not load chats. | 대화를 불러오지 못했어요. |
| `chatsHintTitle` | Say hello to a new connection | 새로 맺어진 친구에게 인사를 건네 보세요 |
| `chatsHintSubtitle` | Tap a friend above to start a conversation. | 위에 있는 친구를 눌러 대화를 시작해 보세요. |
| `chatsEmptyTitle` | No connections yet. | 아직 친구가 없어요. |
| `chatsEmptySubtitle` | When you and someone like each other, you can chat here. | 서로 좋아요를 보낸 분과 여기에서 대화할 수 있어요. |
| `chatsTimeNow` | now | 방금 |
| `chatsTimeMinutes` | {n}m | {n}분 전 |
| `chatsTimeHours` | {n}h | {n}시간 전 |
| `chatsTimeDays` | {n}d | {n}일 전 |
| `chatHeaderFallbackName` | Friend | 친구 |
| `chatHeaderConnected` | Connected | 친구 |
| `chatMessagesErrorPrefix` | Could not load messages. | 메시지를 불러오지 못했어요. |
| `chatComposerHint` | Message | 메시지 입력 |
| `chatMatchCardTitle` | You're now connected! 🎉 | 이제 친구가 되었어요! 🎉 |
| `chatMatchCardHelloGeneric` | Say hello to start chatting. | 인사를 건네 대화를 시작해 보세요. |
| `chatMatchCardHelloNamed` | Say hello to {name} to start chatting. | {name}님께 인사를 건네 대화를 시작해 보세요. |
| `chatSafetyReminder` | Stay safe — never share personal info, passwords, or money. | 안전을 위해 개인정보, 비밀번호, 금전 거래는 절대 공유하지 마세요. |
| `youTitle` | You | 내 프로필 |
| `youSettingsTooltip` | Settings | 설정 |
| `youErrorPrefix` | Could not load your profile. | 내 프로필을 불러오지 못했어요. |
| `youStatusNotPublished` | Not published | 아직 공개 전 |
| `youStatusPaused` | Profile paused | 프로필 잠시 숨김 |
| `youStatusLive` | Profile live | 프로필 공개 중 |
| `youPreviewProfile` | Preview profile | 프로필 미리 보기 |
| `youEditBio` | Edit bio | 자기소개 수정 |
| `youEmptyMessage` | Your profile is not ready yet. | 프로필이 아직 준비되지 않았어요. |
| `settingsTitle` | Settings | 설정 |
| `settingsSectionProfile` | Profile | 프로필 |
| `settingsPauseProfile` | Pause profile | 프로필 잠시 숨기기 |
| `settingsPauseSubtitlePaused` | Hidden from the discover feed. | 둘러보기에서 보이지 않아요. |
| `settingsPauseSubtitleLive` | Visible in the discover feed. | 둘러보기에 보여요. |
| `settingsEditPhoto` | Edit profile photo | 프로필 사진 바꾸기 |
| `settingsWhoCanSeeMe` | Who can see me | 공개 범위 |
| `settingsWhoCanSeeMeValue` | Everyone | 전체 공개 |
| `settingsSectionNotifications` | Notifications | 알림 |
| `settingsNotifLikes` | New likes | 새로운 좋아요 |
| `settingsNotifDigest` | Weekly digest | 주간 소식 |
| `settingsSectionAccount` | Account | 계정 |
| `settingsAccountGoogle` | Connected with Google | Google 계정 연결됨 |
| `settingsAccountPrivacy` | Privacy | 개인정보 |
| `settingsAccountHelp` | Help | 도움말 |
| `settingsSignOut` | Sign out | 로그아웃 |
| `editBioTitle` | Edit bio | 자기소개 수정 |
| `toastProfilePaused` | Profile paused | 프로필을 잠시 숨겼어요 |
| `toastProfileLive` | Profile live | 프로필을 공개했어요 |
| `toastLikedGeneric` | Liked | 좋아요를 보냈어요 |
| `toastLikedNamed` | Liked {name} | {name}님께 좋아요를 보냈어요 |
| `toastConnectedGeneric` | You're now connected! 🎉 | 이제 친구가 되었어요! 🎉 |
| `toastConnectedNamed` | You and {name} are now connected! 🎉 | {name}님과 친구가 되었어요! 🎉 |
| `profileNameAge` | {name}, {age} | {name}, {age}세 |

Notes for translators / reviewers:
- Korean uses 친구 ("friend") for `chatHeaderConnected` and the toast wording — warmer for 65+ than 인연 in everyday UI. We reserve 인연 (deeper, fated relationship) for marketing surfaces, not for the chat header.
- Korean tone leans on the polite "-아요/어요/세요" style throughout; no banmal (반말). No "어머나" / "와우" exclamations.
- `Google` and `Silvers Fun` stay Latin script — the user instructions explicitly want the brand kept in English; Korean speakers recognize "Google" in Latin script.
- Time suffixes (`{n}분 전`, `{n}시간 전`, `{n}일 전`) include "전" ("ago") which reads naturally; the English version is the compact `5m`/`3h`/`2d` form because those are what the design space allows.

---

## Acceptance criteria

- [ ] `flutter analyze` is clean.
- [ ] `flutter test` passes 100% (≥ 65 tests; +2 if Task 20 lands).
- [ ] On a device set to **English (or any non-Korean locale)**, every screen reads exactly as it does on the current `korean-localization` branch's parent (`main` after the senior-polish sprint). No copy drift.
- [ ] On a device set to **Korean (`ko-KR`)**, every user-visible string on the following surfaces appears in Korean:
  - Sign-in screen (tagline, button, terms note)
  - All onboarding screens (name, photo, bio, interests, preview)
  - Discover feed (header, empty state, error)
  - Profile detail (back, like/liked button, "not found")
  - Liked-you screen (title, empty state, error)
  - Chats list (title, empty/hint state, time formatter)
  - Chat thread (header subtitle, match card, safety reminder, composer hint, error)
  - You screen (title, status pill, buttons, empty state, error)
  - Settings (title, section headers, all rows, sign-out)
  - Edit bio (standalone) (AppBar, save button, hint)
  - Bottom-nav tab labels
  - Toasts: like / connected / profile paused / profile live
- [ ] No string is missing from `app_ko.arb` that exists in `app_en.arb` (the generator will warn on missing keys; the build must produce no `MissingStringForKeyException` at runtime).
- [ ] Brand "Silvers Fun" displays in Latin script in both locales.
- [ ] No layout overflows in Korean — the "Continue" button (계속하기) and "Sign out" (로그아웃) fit at 18pt; the safety-reminder line wraps gracefully.
- [ ] Chip labels (interest pool) intentionally remain English in both locales.
- [ ] No Firestore field, document path, or rules file changed.

---

## Manual QA checklist

Run these flows on Android (primary) and Chrome (web). Repeat once with system language English and once with system language Korean.

**Cold-launch**
- [ ] App icon name still reads "Silver Fun" (Android launcher) — unchanged this sprint.
- [ ] Splash → sign-in screen loads. Tagline matches the active locale.

**Sign-in**
- [ ] "Continue with Google" / "Google로 계속하기" button enabled. Tap; Google sheet opens.
- [ ] After successful Google sign-in, redirect lands on `/onboarding/name` (if profile not yet published).
- [ ] Force a sign-in failure (e.g., cancel the Google sheet); error text shows in the active locale.

**Onboarding**
- [ ] Name screen: enter "민수" / "Bob"; helper line localized; Continue advances to photo.
- [ ] Photo screen: tap, pick from gallery; "Uploading…" / "올리는 중…" appears; success → "Replace photo" / "사진 바꾸기".
- [ ] Bio screen: typing updates `n / 180`; Korean shows correctly with multi-byte characters.
- [ ] Interests screen: counter "3 / 6 selected" or "3 / 6개 선택됨" updates as chips toggle.
- [ ] Preview screen: title + subtitle localized; "Edit" and "Publish" buttons.
- [ ] Publish → land on `/app/feed`.

**Discover feed**
- [ ] Empty state copy matches active locale.
- [ ] Tap a profile card; profile detail opens; "Like" / "좋아요" or "Liked" / "좋아요 보냄" toggles correctly.
- [ ] Heart-tap from feed shows toast "Liked {name}" / "{name}님께 좋아요를 보냈어요".
- [ ] Force a mutual like (two-account QA): toast reads "You and {name} are now connected! 🎉" / "{name}님과 친구가 되었어요! 🎉".

**Liked you**
- [ ] Empty state localized; with at least one liker, list renders. Tap row → profile detail.

**Chats**
- [ ] Empty state localized; no connections message.
- [ ] With ≥ 1 mutual: bubble row + "Say hello to a new connection" / "새로 맺어진 친구에게 인사를 건네 보세요" hint.
- [ ] Open thread: header subtitle "Connected" / "친구"; match card "You're now connected!" + safety reminder localized.
- [ ] Send a message; it appears immediately. Receive: time stamp shows "now"/"방금" → "1m"/"1분 전" after a minute.
- [ ] Composer hint "Message" / "메시지 입력".

**You / Settings / Edit bio**
- [ ] You: status pill ("Profile live" / "프로필 공개 중"); Edit bio + Preview profile buttons localized.
- [ ] Settings: every section header + row is localized; toggle Pause profile shows the correct toast in active locale; Sign out localized.
- [ ] Edit bio (standalone, from /edit-bio): AppBar title "Edit bio" / "자기소개 수정"; Save state.

**Locale boundary**
- [ ] Sign in with locale=English; force-quit; switch device to Korean; relaunch — all UI now Korean. (This is the primary value of this sprint.)
- [ ] Switch back to English — UI is English again. No Korean residue.

**Safety / regression**
- [ ] No console errors mentioning `LocalizationsDelegate` / `MissingStringForKey`.
- [ ] `flutter analyze` clean on the final commit.
- [ ] `flutter test` 100% green on the final commit.

---

## Risks / things to watch

1. **`flutter pub get` failing on `flutter.generate: true`.** If the local Flutter SDK is older than 3.10 the `gen-l10n` integration may behave oddly. Mitigation: `flutter --version` should show 3.11+ (pubspec already requires `sdk: ^3.11.5`); if a contributor is on an older SDK, `flutter upgrade` first.
2. **`const` constructors broken by string substitution.** Many existing widgets are `const Text('…')`, `const InputDecoration(…)`, `const ListTile(…)`. Switching the strings to `context.l10n.x` makes them non-const. The plan calls out where to drop `const`. If you miss one, the analyzer flags it immediately.
3. **`HeartButton.onTap` signature.** Currently typed `VoidCallback`. The Task 17 refactor converts the like callback to `Future<void> Function()`. Dart accepts a `() async {}` for `VoidCallback` if you don't `await` it, but if `HeartButton` *typed* it as `VoidCallback?`, returning a Future works only because Dart silently discards it. If the analyzer complains, wrap in a sync closure: `onTap: () { onLike(); }` and accept the fire-and-forget.
4. **Korean text overflow on small phones.** "프로필 잠시 숨기기" is longer than "Pause profile". The settings row uses `SwitchListTile` which truncates with ellipsis at end — fine. The primary buttons (60px @ 18pt) are wide and won't overflow with "계속하기" or "로그아웃". The bottom nav labels in Korean are short ("둘러보기", "좋아요", "대화", "내 정보") and fit; "둘러보기" is the longest at 4 characters. Spot-check on smallest target device (≤ 360dp width).
5. **Interest chips remain English.** A Korean user sees "Gardening" / "Knitting" / etc. on cards. This is a deliberate v1 trade-off; raise as follow-up if QA flags it. The cleanest future fix is to store interests as language-neutral keys (`interest.gardening`) and translate on render — that's a schema migration, hence deferred.
6. **`profileNameAge` formatter.** Korean adds "세" suffix to age. For users who already have profiles published *before* localization lands, their cards now read "Maya, 31세" in Korean — that's intended (it reads naturally in Korean), but it's a visible-to-user change for legacy data. No DB migration needed.
7. **Web manifest / iOS `Info.plist`.** Out of scope; the web title bar and iOS home-screen label stay English. Track as polish.
8. **`flutter_gen` import path stability.** Imports use `package:flutter_gen/gen_l10n/app_localizations.dart`. Some Flutter versions prefer a project-relative path. If the import doesn't resolve in CI, fall back to:
   ```dart
   import 'package:silver_fun/l10n/app_localizations.dart';
   ```
   …and set `synthetic-package: false` in `l10n.yaml` to write the file under `lib/l10n/` directly. Decide once during Task 2 and apply consistently.
9. **No language toggle.** Some seniors set their phone to English but prefer reading Korean (e.g., immigrant grandparents). Without an in-app override they're stuck with the device locale. Logged for a follow-up sprint; would require: `Locale?` provider in Riverpod backed by `shared_preferences`, a settings row that opens a chooser (English / 한국어 / Use device language), and `MaterialApp.router(locale: ref.watch(localePrefProvider))`. Estimated 2–3 hours including a basic test, but not in this sprint.
10. **Tests asserting English literals.** If a future test asserts a string we just localized without setting `locale: const Locale('en')` and the delegates, the assertion will compare against whatever the test environment's default locale is. Always set the locale explicitly in widget tests touching localized text.

---

## Suggested final commit message

If you squash, use:

```
feat(l10n): add Korean localization (ko) alongside English

- Add flutter_localizations + intl, enable gen-l10n via l10n.yaml
- New ARB catalogs: lib/l10n/app_en.arb, lib/l10n/app_ko.arb
- Wire AppLocalizations delegates into MaterialApp.router; follow device locale
- Migrate every user-facing screen and the bottom-nav shell to context.l10n
- Refactor LikesController.toggleLike to return LikeOutcome so toast text
  can localize at the call site (which has BuildContext)
- Update widget tests to register delegates and pin locale to en
- Add LikesController outcome test for liked vs connected paths
- Korean copy uses friendly "-요/세요" tone for adults 65+, keeps "Silvers Fun"
  brand in Latin script, uses 친구 for "connection" in everyday UI

No Firestore schema changes. No package or symbol renames. No new third-party deps.
```

If you keep per-task commits as the plan suggests, the final commit on the branch will already convey intent — the suggested message above is a fallback for a single-PR review path.
