import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        (ref) => Stream<User?>.value(mockAuth.currentUser),
      ),
      firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
      myProfileProvider.overrideWith((ref) => Stream.value(_profile())),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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

    // Drain the toast timer (2.2s).
    await tester.pump(const Duration(seconds: 3));
  });
}
