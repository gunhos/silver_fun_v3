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
