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
