# Silvers Fun — Account Settings Polish Sprint

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add two account-settings features to Silvers Fun: an in-app language picker (System / English / 한국어) that persists across launches, and an "Edit interests" flow that lets users re-pick their interest tags after onboarding without going through the full onboarding form.

**Architecture:** Introduce `shared_preferences` to persist a single key (`pref_locale`) holding either `null` (system default), `"en"`, or `"ko"`. A `LocalePreferenceController` Riverpod `AsyncNotifier` wraps `SharedPreferences`, exposes the chosen `Locale?`, and is read by `MaterialApp.router` in `main.dart` to set the active `locale`. The Settings screen gains a "Language" row that opens a Material dialog with three radio options. For interest editing, we add a standalone `EditInterestsScreen` that reuses `ChipTag` and the same 3..6-selection rule but holds local selection state seeded from `myProfileProvider`, and writes back via the existing `ProfileRepository.updateField('interests', list)`. The onboarding form is left untouched. New routes `/edit-interests` are added; reachable both from the You screen and a new Settings row. ARB strings are added in both languages.

**Tech Stack:** Flutter 3.11.5+ · `shared_preferences: ^2.3.0` (new dep) · existing `flutter_riverpod`, `go_router`, `flutter_localizations`, `cloud_firestore`, `ChipTag`, `Btn`, `AppColors`, `showToast` — no other new third-party deps.

---

## Sprint goal

- Any signed-in user can change the app language from Settings → Language → choose `System default` / `English` / `한국어`. The choice is persisted locally via `shared_preferences` and restored on the next cold launch.
- When the user picks `System default`, the app follows the device locale (current behavior).
- When the user picks `English` or `한국어`, every localized string in the app renders in that language regardless of device locale.
- Any signed-in user can re-pick their interest tags after onboarding by tapping "Edit interests" on the You screen or in Settings, selecting 3..6 chips, and saving. The new list is persisted to `users/{uid}.interests` in Firestore. The chip palette and selection rules match onboarding.
- All new strings exist in both `app_en.arb` and `app_ko.arb` and the existing 65/65+ tests stay green.
- `flutter analyze` stays clean.

## Non-goals

- **No Firestore schema change.** `users/{uid}.interests` already stores English canonical strings (e.g. `'Coffee'`, `'Reading'`), and we keep doing exactly that. Display labels go through the existing `InterestLabel` extension.
- **No package rename.** `name: silver_fun` in `pubspec.yaml` stays.
- **No new onboarding requirements.** The onboarding flow keeps its current 3..6 rule, its `OnboardingFormState`, and its existing screens. We do not refactor `InterestsScreen` to share code with the new `EditInterestsScreen` — the two flows have different state ownership (Riverpod form notifier vs. local state seeded from Firestore) and a forced share would be a worse fit than duplication of ~30 lines of chip-rendering code.
- **No GPS, maps, or push notifications.** Out of scope for this sprint.
- **No redesign of Settings.** We add two rows. The existing sections (Profile / Notifications / Account) stay. The language row goes into a new "Display" section to keep the Account section semantically clean (account = sign-in/privacy/help). The "Edit interests" row goes under Profile right after "Edit profile photo".
- **No migration of existing prefs storage.** This is the first `shared_preferences` use in the app — no legacy keys to consider.
- **No server-side enforcement of the interest 3..6 cap.** Firestore rules already allow self-write to `users/{uid}` (per `firestore.rules`); the validation lives client-side in the screen, mirroring onboarding.
- **No A/B-able locale fallback chain.** If `pref_locale` is `"ko"` and we ever drop Korean from `supportedLocales`, Flutter's `Localizations` widget falls back to the first supported locale; we don't add custom fallback code.

## Recommended UX

### Language picker

- New section "Display" in Settings, placed between "Profile" and "Notifications", containing one row.
- Row: title `Language`, subtitle showing the current selection (`System default` / `English` / `한국어`), trailing `chevron_right`.
- Tap opens a Material `AlertDialog` with three `RadioListTile`s and a "Cancel" button. Selecting an option closes the dialog and persists immediately. A short toast (`toastLanguageSaved`, e.g. "Language updated" / "언어를 바꿨어요") confirms the change.
- The whole app immediately re-renders in the new language because `MaterialApp.locale` is rebuilt off the controller's state. No app restart needed.
- If the controller is still loading at first frame, we render with `locale: null` (device default) — this is identical to today's behavior, so there is no flash.

### Edit interests

- New row in Settings under Profile section: title `Edit interests`, trailing `chevron_right`. Goes between "Edit profile photo" and "Who can see me".
- New button on `YouScreen` body: `Edit interests`, style `BtnVariant.ghost`, placed just above the existing `Edit bio` button.
- Tapping either entry opens `/edit-interests`.
- Screen layout: `AppBar(title: 'Edit interests')` with a `Save` action button on the right (mirrors the standalone `EditBioScreen`'s pattern). Body shows the same chip wrap UI as onboarding, with a `{count} / 6 selected` counter that turns accent-colored at 3+. Save button is disabled while count is outside `[3, 6]` or while saving.
- Save writes to Firestore via `ProfileRepository.updateField(uid, 'interests', selection)`, then `context.pop()` and a toast: `Interests updated` / `관심사를 바꿨어요`.

## Files likely to edit

Scaffolding & wiring
- `pubspec.yaml` — add `shared_preferences: ^2.3.0`
- `lib/main.dart` — read `localePreferenceProvider`, set `MaterialApp.router(locale: ...)`
- `lib/core/router/router.dart` — add `/edit-interests` route
- `lib/core/providers/locale_preference_provider.dart` (new) — `LocalePreferenceController` + `localePreferenceProvider`

Localization
- `lib/l10n/app_en.arb` — new keys (see Localization section)
- `lib/l10n/app_ko.arb` — same keys, Korean values
- (Generated `lib/l10n/app_localizations*.dart` — regenerated by `flutter gen-l10n`; do not hand-edit but DO commit since this repo commits the generated file; see existing `lib/l10n/app_localizations_en.dart` already in `lib/`.)

Settings UI
- `lib/features/profile/screens/settings_screen.dart` — add `Display` section with Language row; add `Edit interests` row in Profile section

Edit interests
- `lib/features/profile/screens/edit_interests_screen.dart` (new)
- `lib/features/profile/screens/you_screen.dart` — add `Edit interests` button

Tests
- `test/core/providers/locale_preference_provider_test.dart` (new)
- `test/features/profile/edit_interests_screen_test.dart` (new)
- `test/features/profile/settings_language_row_test.dart` (new — focused widget test for the Settings language row + dialog)
- `test/features/profile/you_screen_test.dart` — extend to verify the new "Edit interests" button is present

> **Note:** the existing `lib/l10n/app_localizations*.dart` files are checked in (this repo committed the generated output). After editing the ARB files, run `flutter gen-l10n` (or `flutter pub get`, which regenerates) and commit the regenerated `.dart` files alongside the `.arb` change so the build stays self-contained. This matches what `korean_localization_sprint.md` shipped.

## Localization keys needed

Add to **both** `lib/l10n/app_en.arb` and `lib/l10n/app_ko.arb`. English first, Korean second:

| Key | English | Korean |
|---|---|---|
| `settingsSectionDisplay` | `Display` | `화면` |
| `settingsLanguage` | `Language` | `언어` |
| `settingsLanguageSystem` | `System default` | `시스템 기본` |
| `settingsLanguageEnglish` | `English` | `영어` |
| `settingsLanguageKorean` | `한국어` | `한국어` |
| `settingsLanguageDialogTitle` | `Choose language` | `언어를 선택하세요` |
| `settingsLanguageDialogCancel` | `Cancel` | `취소` |
| `settingsEditInterests` | `Edit interests` | `관심사 수정` |
| `editInterestsTitle` | `Edit interests` | `관심사 수정` |
| `editInterestsSubtitle` | `Choose 3 to 6 things you love.` | `좋아하시는 것 3가지에서 6가지를 골라 주세요.` |
| `toastLanguageSaved` | `Language updated` | `언어를 바꿨어요` |
| `toastInterestsUpdated` | `Interests updated` | `관심사를 바꿨어요` |
| `youEditInterests` | `Edit interests` | `관심사 수정` |

> Reuse the existing `actionSave`, `actionSaving`, `onbInterestsCounter` (`{count} / 6 selected`), and `interest*` keys for the chip labels. **Do not duplicate** the counter string under a new key — `onbInterestsCounter` already takes a `{count}` placeholder and is appropriate to reuse on the Edit Interests screen.

## Tests to add/update

1. **`LocalePreferenceController` unit test** — uses `SharedPreferences.setMockInitialValues({})` to drive the in-memory backend.
   - Initial state with no stored value is `null` (system default).
   - Calling `setLocale(const Locale('ko'))` updates state to `Locale('ko')` and writes `pref_locale: 'ko'` to `SharedPreferences`.
   - Calling `setLocale(null)` clears the stored value (or writes `null`) and state becomes `null`.
   - On rebuild with `SharedPreferences.setMockInitialValues({'pref_locale': 'en'})`, the controller hydrates to `Locale('en')`.

2. **Settings language row widget test** — pumps `SettingsScreen` inside a `ProviderScope` with `localePreferenceProvider` overridden, verifies the row label/subtitle for each of the three states, taps the row, asserts the dialog renders three radio options, taps "한국어", asserts `setLocale` is invoked and the toast text appears.

3. **`EditInterestsScreen` widget test** — pumps the screen with `myProfileProvider` overridden to a fixture profile with `interests: ['Coffee', 'Reading']`, verifies:
   - Initially shows 2/6, two chips selected, save disabled.
   - Tapping a third chip enables save.
   - Tapping save calls `ProfileRepository.updateField(uid, 'interests', [...])` (use `FakeFirebaseFirestore`-backed repo via override) and pops.
   - Tapping a 7th chip is a no-op (cap at 6).

4. **`you_screen_test.dart` update** — extend the existing render test to assert the new `Edit interests` button is present.

## Acceptance criteria

- [ ] On a fresh install with the device set to English, the app launches in English and the Settings → Language subtitle reads `System default`.
- [ ] On a fresh install with the device set to Korean, the app launches in Korean and Settings → Language subtitle reads `시스템 기본`.
- [ ] After picking `English` from a Korean-device install, the app immediately renders all visible strings in English; the chosen subtitle becomes `English`. Killing and relaunching the app keeps it in English.
- [ ] After picking `System default` again, the app reverts to the device locale on the spot.
- [ ] Tapping `Edit interests` from You screen opens the editor with the user's current interests pre-selected, and the chip count matches stored `users/{uid}.interests`.
- [ ] Save is disabled at 0/6, 1/6, 2/6, and 7/6; enabled at 3/6, 4/6, 5/6, 6/6.
- [ ] After saving, Firestore `users/{uid}.interests` reflects the new list (canonical English strings) and a toast confirms.
- [ ] `flutter test` passes (existing 65+ + new tests).
- [ ] `flutter analyze` is clean.

## Manual QA checklist

Run on iOS Simulator and Android Emulator with both locales.

- [ ] Cold launch: device EN → app EN. Device KO → app KO.
- [ ] Settings → Language → English on a KO-device install: every visible string flips to English without restart. Kill and relaunch: still English.
- [ ] Settings → Language → 한국어 on an EN-device install: every visible string flips to Korean without restart. Kill and relaunch: still Korean.
- [ ] Settings → Language → System default on a KO-device install where user previously picked English: app flips back to Korean immediately.
- [ ] Edit interests path 1: You screen → "Edit interests" → unselect one, select two new, save → returns to You screen, chips reflect new selection.
- [ ] Edit interests path 2: Settings → "Edit interests" → save with no changes → returns and toast confirms.
- [ ] Edit interests cap: try to tap a 7th chip → no-op, count stays at 6.
- [ ] Edit interests floor: deselect down to 2 → Save button is disabled and looks muted.
- [ ] Edit interests cancel via system back: no Firestore write happens (verify with logs or by checking the doc didn't change).
- [ ] Localized chip labels: with KO locale, chips render as `정원 가꾸기`, `커피`, etc.; the *stored* canonical value is still English (verify via Firestore console).
- [ ] No locale flash on launch: the first visible frame is in the chosen language, not in English-then-Korean.
- [ ] Sign out → Sign in: the language preference is preserved (it's per-device, not per-account).

## Risks / things to watch

1. **First-frame locale flash.** `SharedPreferences.getInstance()` is async, so the controller's initial state is `AsyncLoading`. If `MaterialApp.router` reads `valueOrNull` and gets `null` while loading, it'll render the device-default locale for one frame, then re-render in the chosen locale. For users whose pref differs from device, this looks like a flash. **Mitigation:** await `SharedPreferences.getInstance()` once in `main()` *before* `runApp`, store the synchronous result, and seed the Riverpod provider with the already-loaded prefs (override the provider on `ProviderScope`). This is the same pattern Flutter docs recommend for hydrated prefs.

2. **`shared_preferences` on web.** The package supports web via `localStorage`; no extra setup needed. The web build is QA-only per the handoff so this is low risk, but verify the locale persists across web reloads.

3. **Generated localization files.** Regenerate `app_localizations_*.dart` after every ARB edit. Forgetting to run `flutter gen-l10n` (or `flutter pub get`) before committing will cause CI failures. The repo currently commits the generated files (per `korean_localization_sprint.md`) — keep doing that.

4. **Interest pool drift.** If a user previously selected an interest that has since been removed from `kInterestPool`, the Edit Interests screen will not show that chip in the palette. Their stored value remains untouched until they save, at which point the dropped value is lost. This is acceptable for v1 (current pool is stable) but worth a `// TODO` if the pool ever changes.

5. **Save race with onboarding pre-publish.** The new screen reads from `myProfileProvider` via `valueOrNull`. If a user opens Edit Interests while their profile is still loading (immediately after sign-in), `valueOrNull` is `null` and we should bail to a loading state rather than crash. The screen handles `null` with a centered spinner, identical to `YouScreen.loading`.

6. **Dialog dismissal vs. apply.** Material `AlertDialog` with radio options can be applied either on selection or on a confirm button. We chose **apply on selection** (no confirm step) for senior UX — fewer taps. The "Cancel" button just dismisses without changing anything. If user research later shows seniors prefer an explicit Confirm, that's a one-line change.

## Step-by-step implementation tasks

> **TDD reminder:** for each task that ships behavior, write the failing test, prove it fails, then implement. Repository/controller tasks are pure unit tests; widget tasks pump a `MaterialApp` with overrides.

### Task 1: Add `shared_preferences` dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add the dep**

In `pubspec.yaml`, under `dependencies:` (after `google_fonts`), add:

```yaml
  shared_preferences: ^2.3.0
```

- [ ] **Step 2: Resolve**

Run: `flutter pub get`
Expected: `Got dependencies!` (or "Got 1 new dependency"), no resolver errors.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "deps: add shared_preferences for locale persistence"
```

---

### Task 2: Locale preference controller — write failing test

**Files:**
- Create: `test/core/providers/locale_preference_provider_test.dart`

- [ ] **Step 1: Create the test directory**

Run: `mkdir -p test/core/providers`

- [ ] **Step 2: Write the failing test**

Create `test/core/providers/locale_preference_provider_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silver_fun/core/providers/locale_preference_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalePreferenceController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('initial state is null when nothing is stored', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = await container.read(localePreferenceProvider.future);
      expect(value, isNull);
    });

    test('hydrates from stored pref_locale = "ko"', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'pref_locale': 'ko',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = await container.read(localePreferenceProvider.future);
      expect(value, const Locale('ko'));
    });

    test('setLocale("en") updates state and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(localePreferenceProvider.future);

      await container
          .read(localePreferenceProvider.notifier)
          .setLocale(const Locale('en'));

      expect(
        container.read(localePreferenceProvider).valueOrNull,
        const Locale('en'),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pref_locale'), 'en');
    });

    test('setLocale(null) clears state and storage', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'pref_locale': 'ko',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(localePreferenceProvider.future);

      await container
          .read(localePreferenceProvider.notifier)
          .setLocale(null);

      expect(
        container.read(localePreferenceProvider).valueOrNull,
        isNull,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pref_locale'), isNull);
    });
  });
}
```

- [ ] **Step 3: Run the test, prove it fails**

Run: `flutter test test/core/providers/locale_preference_provider_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '...locale_preference_provider.dart'`.

---

### Task 3: Locale preference controller — implement

**Files:**
- Create: `lib/core/providers/locale_preference_provider.dart`

- [ ] **Step 1: Implement**

Create `lib/core/providers/locale_preference_provider.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kPrefLocaleKey = 'pref_locale';

class LocalePreferenceController extends AsyncNotifier<Locale?> {
  @override
  Future<Locale?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefLocaleKey);
    if (raw == null || raw.isEmpty) return null;
    return Locale(raw);
  }

  Future<void> setLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_kPrefLocaleKey);
    } else {
      await prefs.setString(_kPrefLocaleKey, locale.languageCode);
    }
    state = AsyncData(locale);
  }
}

final localePreferenceProvider =
    AsyncNotifierProvider<LocalePreferenceController, Locale?>(
  LocalePreferenceController.new,
);
```

- [ ] **Step 2: Run the test, prove it passes**

Run: `flutter test test/core/providers/locale_preference_provider_test.dart`
Expected: PASS — 4 tests.

- [ ] **Step 3: Commit**

```bash
git add lib/core/providers/locale_preference_provider.dart \
        test/core/providers/locale_preference_provider_test.dart
git commit -m "feat(prefs): add LocalePreferenceController for in-app language toggle"
```

---

### Task 4: Wire the locale into MaterialApp

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Update `main.dart`**

Replace the body of `lib/main.dart` with:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/providers/locale_preference_provider.dart';
import 'core/router/router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Pre-load shared_preferences so the very first frame uses the user's
  // chosen locale (no English flash on a Korean-device install where the
  // user previously picked English, or vice versa).
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('pref_locale');
  final initial = (raw == null || raw.isEmpty) ? null : Locale(raw);

  runApp(
    ProviderScope(
      overrides: [
        localePreferenceProvider.overrideWith(
          () => _SeededLocalePreferenceController(initial),
        ),
      ],
      child: const SilversFunApp(),
    ),
  );
}

class _SeededLocalePreferenceController extends LocalePreferenceController {
  _SeededLocalePreferenceController(this._initial);

  final Locale? _initial;

  @override
  Future<Locale?> build() async => _initial;
}

class SilversFunApp extends ConsumerWidget {
  const SilversFunApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localePreferenceProvider).valueOrNull;
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
```

> Why the `_SeededLocalePreferenceController` override: it returns the pre-loaded value synchronously inside `build()` so the very first render reads the user's chosen locale, while `setLocale` (inherited from the base class) still hits `SharedPreferences` for persistence. Without this seed, the first frame would be `AsyncLoading → null` (device default) and we'd see a one-frame flash before the controller hydrated.

- [ ] **Step 2: Verify analyzer**

Run: `flutter analyze lib/main.dart lib/core/providers/locale_preference_provider.dart`
Expected: `No issues found!`

- [ ] **Step 3: Smoke-run on a simulator/emulator**

Run: `flutter run` (any device)
Expected: app launches normally in the device locale; no behavior change yet.

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "feat(app): wire LocalePreferenceController into MaterialApp.locale"
```

---

### Task 5: Add ARB strings for language picker + edit interests

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ko.arb`

- [ ] **Step 1: Add to `app_en.arb`**

Add these keys before the closing `}` of `lib/l10n/app_en.arb` (preserve trailing-comma style of neighbors, then add the new keys with no trailing comma on the very last one):

```json
  "settingsSectionDisplay": "Display",
  "settingsLanguage": "Language",
  "settingsLanguageSystem": "System default",
  "settingsLanguageEnglish": "English",
  "settingsLanguageKorean": "한국어",
  "settingsLanguageDialogTitle": "Choose language",
  "settingsLanguageDialogCancel": "Cancel",
  "settingsEditInterests": "Edit interests",
  "editInterestsTitle": "Edit interests",
  "editInterestsSubtitle": "Choose 3 to 6 things you love.",
  "youEditInterests": "Edit interests",
  "toastLanguageSaved": "Language updated",
  "toastInterestsUpdated": "Interests updated"
```

> If the ARB currently ends with `"toastMeetupCanceled": "Meetup canceled"` followed by `}`, add a trailing comma to that line and then insert the new block before the closing `}`.

- [ ] **Step 2: Add to `app_ko.arb` (same keys)**

```json
  "settingsSectionDisplay": "화면",
  "settingsLanguage": "언어",
  "settingsLanguageSystem": "시스템 기본",
  "settingsLanguageEnglish": "영어",
  "settingsLanguageKorean": "한국어",
  "settingsLanguageDialogTitle": "언어를 선택하세요",
  "settingsLanguageDialogCancel": "취소",
  "settingsEditInterests": "관심사 수정",
  "editInterestsTitle": "관심사 수정",
  "editInterestsSubtitle": "좋아하시는 것 3가지에서 6가지를 골라 주세요.",
  "youEditInterests": "관심사 수정",
  "toastLanguageSaved": "언어를 바꿨어요",
  "toastInterestsUpdated": "관심사를 바꿨어요"
```

- [ ] **Step 3: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: regenerates `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_ko.dart` with the new getters; no errors.

- [ ] **Step 4: Sanity check the generated getters exist**

Run: `grep -E "settingsLanguage|editInterestsTitle|toastInterestsUpdated" lib/l10n/app_localizations.dart`
Expected: shows several abstract getters for the new keys.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_ko.arb \
        lib/l10n/app_localizations.dart \
        lib/l10n/app_localizations_en.dart \
        lib/l10n/app_localizations_ko.dart
git commit -m "i18n: add strings for language picker and edit interests"
```

---

### Task 6: Edit interests screen — write failing test

**Files:**
- Create: `test/features/profile/edit_interests_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/profile/edit_interests_screen_test.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silver_fun/core/widgets/toast_overlay.dart';
import 'package:silver_fun/features/auth/providers/auth_provider.dart';
import 'package:silver_fun/features/profile/providers/my_profile_provider.dart';
import 'package:silver_fun/features/profile/screens/edit_interests_screen.dart';
import 'package:silver_fun/l10n/app_localizations.dart';
import 'package:silver_fun/models/user_profile.dart';

UserProfile _profile({List<String> interests = const ['Coffee', 'Reading']}) {
  return UserProfile(
    uid: 'u1',
    name: 'Maya',
    age: 31,
    bio: 'Reads in cafes.',
    photoUrl: '',
    interests: interests,
    city: '',
    published: true,
    profilePaused: false,
  );
}

Widget _harness({
  required FakeFirebaseFirestore firestore,
  required UserProfile profile,
}) {
  final mockUser = MockUser(uid: 'u1', email: 'u1@example.com');
  final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(
        (ref) => Stream<User?>.value(mockAuth.currentUser),
      ),
      firestoreProvider.overrideWithValue(firestore),
      myProfileProvider.overrideWith((ref) => Stream.value(profile)),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => ToastOverlay(child: child!),
      home: const EditInterestsScreen(),
    ),
  );
}

void main() {
  testWidgets('shows existing interests selected and disables save below 3',
      (tester) async {
    final firestore = FakeFirebaseFirestore();
    await tester.pumpWidget(_harness(firestore: firestore, profile: _profile()));
    await tester.pumpAndSettle();

    expect(find.text('2 / 6 selected'), findsOneWidget);
    final saveBtn = find.widgetWithText(TextButton, 'Save');
    expect(tester.widget<TextButton>(saveBtn).onPressed, isNull);
  });

  testWidgets('selecting a third chip enables save', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await tester.pumpWidget(_harness(firestore: firestore, profile: _profile()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yoga'));
    await tester.pumpAndSettle();
    expect(find.text('3 / 6 selected'), findsOneWidget);

    final saveBtn = find.widgetWithText(TextButton, 'Save');
    expect(tester.widget<TextButton>(saveBtn).onPressed, isNotNull);
  });

  testWidgets('save persists the new list to Firestore', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc('u1').set({
      'name': 'Maya',
      'age': 31,
      'bio': 'Reads in cafes.',
      'interests': ['Coffee', 'Reading'],
      'published': true,
      'profilePaused': false,
    });

    await tester.pumpWidget(_harness(firestore: firestore, profile: _profile()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yoga'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    final doc = await firestore.collection('users').doc('u1').get();
    final stored = (doc.data()!['interests'] as List).cast<String>();
    expect(stored, containsAll(['Coffee', 'Reading', 'Yoga']));
    expect(stored.length, 3);
  });

  testWidgets('cap at 6: tapping a 7th chip is a no-op', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await tester.pumpWidget(_harness(
      firestore: firestore,
      profile: _profile(interests: const [
        'Coffee', 'Reading', 'Yoga', 'Travel', 'Walking', 'Cooking',
      ]),
    ));
    await tester.pumpAndSettle();

    expect(find.text('6 / 6 selected'), findsOneWidget);

    // Try to add a 7th — count stays at 6.
    await tester.tap(find.text('Baking'));
    await tester.pumpAndSettle();
    expect(find.text('6 / 6 selected'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test, prove it fails**

Run: `flutter test test/features/profile/edit_interests_screen_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '...edit_interests_screen.dart'`.

---

### Task 7: Edit interests screen — implement

**Files:**
- Create: `lib/features/profile/screens/edit_interests_screen.dart`

- [ ] **Step 1: Implement**

Create `lib/features/profile/screens/edit_interests_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/i18n/interest_label.dart';
import '../../../core/providers/toast_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chip_tag.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/my_profile_provider.dart';

class EditInterestsScreen extends ConsumerStatefulWidget {
  const EditInterestsScreen({super.key});

  @override
  ConsumerState<EditInterestsScreen> createState() =>
      _EditInterestsScreenState();
}

class _EditInterestsScreenState extends ConsumerState<EditInterestsScreen> {
  List<String>? _selection;
  bool _saving = false;

  void _ensureSeeded(List<String> initial) {
    _selection ??= List<String>.from(initial);
  }

  void _toggle(String tag) {
    final current = _selection!;
    setState(() {
      if (current.contains(tag)) {
        current.remove(tag);
      } else {
        if (current.length >= 6) return;
        current.add(tag);
      }
    });
  }

  bool get _valid =>
      _selection != null &&
      _selection!.length >= 3 &&
      _selection!.length <= 6;

  Future<void> _onSave() async {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null || !_valid || _saving) return;

    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateField(
            user.uid,
            'interests',
            List<String>.from(_selection!),
          );
      if (!mounted) return;
      showToast(ref, context.l10n.toastInterestsUpdated);
      context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
    _ensureSeeded(profile.interests);
    final count = _selection!.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l.editInterestsTitle),
        actions: [
          TextButton(
            onPressed: _valid && !_saving ? _onSave : null,
            child: Text(
              _saving ? l.actionSaving : l.actionSave,
              style: TextStyle(
                color: _valid ? AppColors.accent : AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.editInterestsSubtitle,
                style: text.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              Text(
                l.onbInterestsCounter(count),
                style: text.bodySmall?.copyWith(
                  color: _valid ? AppColors.accent : AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: kInterestPool.map((tag) {
                      final selected = _selection!.contains(tag);
                      return ChipTag(
                        label: l.localizedInterest(tag),
                        selected: selected,
                        onTap: () => _toggle(tag),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run the test, prove it passes**

Run: `flutter test test/features/profile/edit_interests_screen_test.dart`
Expected: PASS — 4 tests.

- [ ] **Step 3: Commit**

```bash
git add lib/features/profile/screens/edit_interests_screen.dart \
        test/features/profile/edit_interests_screen_test.dart
git commit -m "feat(profile): add EditInterestsScreen for post-onboarding interest editing"
```

---

### Task 8: Add `/edit-interests` route

**Files:**
- Modify: `lib/core/router/router.dart`

- [ ] **Step 1: Import and register the route**

In `lib/core/router/router.dart`, add the import near the other profile-screen imports:

```dart
import '../../features/profile/screens/edit_interests_screen.dart';
```

Then add the route inside the top-level `routes:` list (next to the existing `/edit-bio` route at the bottom):

```dart
      GoRoute(
        path: '/edit-interests',
        builder: (_, _) => const EditInterestsScreen(),
      ),
```

- [ ] **Step 2: Verify analyzer**

Run: `flutter analyze lib/core/router/router.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/core/router/router.dart
git commit -m "feat(router): add /edit-interests route"
```

---

### Task 9: You screen — add Edit Interests button + update test

**Files:**
- Modify: `lib/features/profile/screens/you_screen.dart`
- Modify: `test/features/profile/you_screen_test.dart`

- [ ] **Step 1: Update the existing widget test to assert the new button**

In `test/features/profile/you_screen_test.dart`, in the first `testWidgets` body (`'YouScreen renders name, status, bio, chips'`), add this after the existing `expect(find.text('Edit bio'), findsOneWidget);` line:

```dart
    expect(find.text('Edit interests'), findsOneWidget);
```

- [ ] **Step 2: Run the test, prove it fails**

Run: `flutter test test/features/profile/you_screen_test.dart`
Expected: FAIL — `Expected: exactly one matching candidate, Actual: _TextFinder:<zero widgets>`.

- [ ] **Step 3: Add the button to `you_screen.dart`**

In `lib/features/profile/screens/you_screen.dart`, locate the `Btn(label: l.youEditBio, ...)` block in `_YouBody.build`. Insert a new `Btn` immediately *above* it (with a `SizedBox(height: 12)` separator above that), so the order becomes Preview → Edit interests → Edit bio:

```dart
          const SizedBox(height: 12),
          Btn(
            label: l.youEditInterests,
            variant: BtnVariant.ghost,
            onPressed: () => context.push('/edit-interests'),
          ),
          const SizedBox(height: 12),
          Btn(
            label: l.youEditBio,
            onPressed: () => context.push('/edit-bio'),
          ),
```

(You'll be replacing the existing `const SizedBox(height: 12); Btn(...edit bio...)` pair with the three-line block above.)

- [ ] **Step 4: Run the test, prove it passes**

Run: `flutter test test/features/profile/you_screen_test.dart`
Expected: PASS — 2 tests (existing + extended).

- [ ] **Step 5: Commit**

```bash
git add lib/features/profile/screens/you_screen.dart \
        test/features/profile/you_screen_test.dart
git commit -m "feat(you): add Edit interests button on You screen"
```

---

### Task 10: Settings — add Edit Interests row + Display section with Language row

**Files:**
- Modify: `lib/features/profile/screens/settings_screen.dart`

- [ ] **Step 1: Add the Edit Interests row to the Profile section**

In `lib/features/profile/screens/settings_screen.dart`, inside the first `_SettingsCard` (Profile section), add a new `ListTile` + `_DividerRow` between the existing `settingsEditPhoto` row and `settingsWhoCanSeeMe` row:

```dart
                const _DividerRow(),
                ListTile(
                  title: Text(l.settingsEditInterests),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.muted,
                  ),
                  onTap: () => context.push('/edit-interests'),
                ),
```

(Place this so the row order in the Profile card becomes: pause toggle, Edit profile photo, **Edit interests**, Who can see me.)

- [ ] **Step 2: Add the Display section with the Language row**

Below the Profile section's closing `_SettingsCard(...)` and its trailing `SizedBox`, insert a new section between Profile and Notifications:

```dart
            const SizedBox(height: 20),
            _SectionTitle(l.settingsSectionDisplay),
            _SettingsCard(
              children: [
                _LanguageRow(),
              ],
            ),
```

- [ ] **Step 3: Implement `_LanguageRow`**

Add at the bottom of the same file (after `_SignOutButton`):

```dart
class _LanguageRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final selected = ref.watch(localePreferenceProvider).valueOrNull;
    final subtitle = switch (selected?.languageCode) {
      'en' => l.settingsLanguageEnglish,
      'ko' => l.settingsLanguageKorean,
      _ => l.settingsLanguageSystem,
    };
    return ListTile(
      title: Text(l.settingsLanguage),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.muted),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
      onTap: () => _showLanguageDialog(context, ref, selected),
    );
  }
}

Future<void> _showLanguageDialog(
  BuildContext context,
  WidgetRef ref,
  Locale? current,
) async {
  final l = context.l10n;
  await showDialog<void>(
    context: context,
    builder: (dialogCtx) {
      return AlertDialog(
        title: Text(l.settingsLanguageDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String?>(
              value: null,
              groupValue: current?.languageCode,
              onChanged: (_) {
                Navigator.of(dialogCtx).pop();
                ref
                    .read(localePreferenceProvider.notifier)
                    .setLocale(null);
                showToast(ref, l.toastLanguageSaved);
              },
              title: Text(l.settingsLanguageSystem),
            ),
            RadioListTile<String?>(
              value: 'en',
              groupValue: current?.languageCode,
              onChanged: (_) {
                Navigator.of(dialogCtx).pop();
                ref
                    .read(localePreferenceProvider.notifier)
                    .setLocale(const Locale('en'));
                showToast(ref, l.toastLanguageSaved);
              },
              title: Text(l.settingsLanguageEnglish),
            ),
            RadioListTile<String?>(
              value: 'ko',
              groupValue: current?.languageCode,
              onChanged: (_) {
                Navigator.of(dialogCtx).pop();
                ref
                    .read(localePreferenceProvider.notifier)
                    .setLocale(const Locale('ko'));
                showToast(ref, l.toastLanguageSaved);
              },
              title: Text(l.settingsLanguageKorean),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l.settingsLanguageDialogCancel),
          ),
        ],
      );
    },
  );
}
```

- [ ] **Step 4: Add the imports**

Near the top of `settings_screen.dart`, ensure these imports exist (add the missing ones):

```dart
import '../../../core/providers/locale_preference_provider.dart';
```

(`go_router` and `toast_provider` are already imported.)

- [ ] **Step 5: Verify analyzer**

Run: `flutter analyze lib/features/profile/screens/settings_screen.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/features/profile/screens/settings_screen.dart
git commit -m "feat(settings): add Display→Language picker and Edit interests row"
```

---

### Task 11: Settings language row — widget test

**Files:**
- Create: `test/features/profile/settings_language_row_test.dart`

- [ ] **Step 1: Write the test**

Create `test/features/profile/settings_language_row_test.dart`:

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silver_fun/core/providers/locale_preference_provider.dart';
import 'package:silver_fun/core/widgets/toast_overlay.dart';
import 'package:silver_fun/features/auth/providers/auth_provider.dart';
import 'package:silver_fun/features/profile/providers/my_profile_provider.dart';
import 'package:silver_fun/features/profile/screens/settings_screen.dart';
import 'package:silver_fun/l10n/app_localizations.dart';
import 'package:silver_fun/models/user_profile.dart';

UserProfile _profile() => UserProfile(
      uid: 'u1',
      name: 'Maya',
      age: 31,
      bio: 'Hi.',
      photoUrl: '',
      interests: const ['Coffee', 'Reading', 'Yoga'],
      city: '',
      published: true,
      profilePaused: false,
    );

Widget _harness() {
  final mockUser = MockUser(uid: 'u1');
  final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(
        (ref) => Stream.value(mockAuth.currentUser),
      ),
      firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
      myProfileProvider.overrideWith((ref) => Stream.value(_profile())),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => ToastOverlay(child: child!),
      home: const SettingsScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('language row shows System default when nothing stored',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('System default'), findsOneWidget);
  });

  testWidgets('opening dialog and picking 한국어 persists the choice',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();

    expect(find.text('Choose language'), findsOneWidget);

    await tester.tap(find.text('한국어'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('pref_locale'), 'ko');
  });
}
```

- [ ] **Step 2: Run the test**

Run: `flutter test test/features/profile/settings_language_row_test.dart`
Expected: PASS — 2 tests.

- [ ] **Step 3: Commit**

```bash
git add test/features/profile/settings_language_row_test.dart
git commit -m "test(settings): cover language row state and dialog selection"
```

---

### Task 12: Full sweep + manual verification

- [ ] **Step 1: Run the full test suite**

Run: `flutter test`
Expected: PASS — all tests, including the existing 65+ green and the four new tests added in this sprint.

- [ ] **Step 2: Analyzer sweep**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 3: Manual smoke on a simulator**

Run the app, walk through the manual QA checklist above. Pay particular attention to:

- Cold launch with the device set to Korean shows Korean.
- Picking English flips immediately and survives a kill/relaunch.
- Edit interests from You and Settings both work; the saved list is correct in Firestore (use `firebase_emulator` if running locally, or check the live Firestore console in dev project).

- [ ] **Step 4: Final commit (only if any docs changed)**

If you updated `docs/silvers_fun_handoff.md` or `docs/qa-checklist.md` to reflect the new flows, commit them now:

```bash
git add docs/silvers_fun_handoff.md docs/qa-checklist.md
git commit -m "docs: note language picker + edit interests in handoff/QA"
```

(If those files weren't touched, skip this step.)

## Suggested final commit message

If you squash-merge or use a single commit per sprint:

```
feat(account-settings): in-app language picker and edit interests

- Add shared_preferences-backed LocalePreferenceController with
  setLocale(Locale?) — null = system default. Pre-loaded in main()
  so the first frame uses the chosen locale.
- Wire MaterialApp.router(locale: ...) to the controller.
- Settings: new "Display → Language" section with a 3-option dialog
  (System / English / 한국어).
- Settings + You screen: new "Edit interests" entry routes to a
  standalone EditInterestsScreen that reuses kInterestPool, the
  3..6-selection rule, and writes to users/{uid}.interests via
  ProfileRepository.updateField — no schema change.
- Add EN/KO ARB strings; regenerate app_localizations*.dart.
- Tests: LocalePreferenceController unit tests, EditInterestsScreen
  widget tests (initial selection, cap, save), Settings language
  row + dialog widget test, You screen extension.
```
