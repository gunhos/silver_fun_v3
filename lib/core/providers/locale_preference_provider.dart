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
