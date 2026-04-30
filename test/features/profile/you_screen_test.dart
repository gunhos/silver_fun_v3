import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silver_fun/features/profile/providers/my_profile_provider.dart';
import 'package:silver_fun/features/profile/screens/you_screen.dart';
import 'package:silver_fun/l10n/app_localizations.dart';
import 'package:silver_fun/models/user_profile.dart';

UserProfile _profile({bool paused = false, bool published = true}) {
  return UserProfile(
    uid: 'u1',
    name: 'Maya',
    age: 31,
    bio: 'Reads in cafes.',
    photoUrl: '',
    interests: const ['Coffee', 'Reading'],
    city: '',
    published: published,
    profilePaused: paused,
  );
}

void main() {
  testWidgets('YouScreen renders name, status, bio, chips', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myProfileProvider.overrideWith((ref) => Stream.value(_profile())),
        ],
        child: MaterialApp(
          home: const YouScreen(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Maya, 31'), findsOneWidget);
    expect(find.text('Profile live'), findsOneWidget);
    expect(find.text('Reads in cafes.'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Reading'), findsOneWidget);
    expect(find.text('Edit bio'), findsOneWidget);
    expect(find.text('Edit photos'), findsOneWidget);
    expect(find.text('Edit interests'), findsOneWidget);
  });

  testWidgets('YouScreen shows paused status when profile is paused',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myProfileProvider
              .overrideWith((ref) => Stream.value(_profile(paused: true))),
        ],
        child: MaterialApp(
          home: const YouScreen(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profile paused'), findsOneWidget);
  });
}
