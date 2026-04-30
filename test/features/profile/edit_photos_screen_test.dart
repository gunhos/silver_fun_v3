import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silver_fun/features/auth/providers/auth_provider.dart';
import 'package:silver_fun/features/profile/providers/my_profile_provider.dart';
import 'package:silver_fun/features/profile/screens/edit_photos_screen.dart';
import 'package:silver_fun/l10n/app_localizations.dart';
import 'package:silver_fun/models/user_profile.dart';

UserProfile _profile({List<String> urls = const ['https://x/1.jpg']}) {
  return UserProfile(
    uid: 'me',
    name: 'Maya',
    age: 30,
    bio: 'Hi.',
    photoUrl: urls.isEmpty ? '' : urls.first,
    photoUrls: urls,
    interests: const ['Coffee'],
    city: '',
    published: true,
    profilePaused: false,
  );
}

Widget _harness({
  required UserProfile profile,
  ProfilePhotoUploader? uploader,
  ProfilePhotoDeleter? deleter,
}) {
  final mockUser = MockUser(uid: 'me', email: 'me@example.com');
  final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(
        (ref) => Stream<User?>.value(mockAuth.currentUser),
      ),
      myProfileProvider.overrideWith((ref) => Stream.value(profile)),
      if (uploader != null)
        profilePhotoUploaderProvider.overrideWithValue(uploader),
      if (deleter != null)
        profilePhotoDeleterProvider.overrideWithValue(deleter),
    ],
    child: MaterialApp(
      home: const EditPhotosScreen(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  testWidgets('renders a tile per photo plus an Add tile when count < 6',
      (tester) async {
    await tester.pumpWidget(_harness(
      profile: _profile(urls: const ['https://x/1.jpg', 'https://x/2.jpg']),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('edit-photos-tile-https://x/1.jpg')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('edit-photos-tile-https://x/2.jpg')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('edit-photos-add-tile')), findsOneWidget);
  });

  testWidgets('hides the Add tile when at the 6-photo cap', (tester) async {
    final urls = List.generate(6, (i) => 'https://x/$i.jpg');
    await tester.pumpWidget(_harness(profile: _profile(urls: urls)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('edit-photos-add-tile')), findsNothing);
  });

  testWidgets('shows the MAIN badge on photoUrls[0] only', (tester) async {
    await tester.pumpWidget(_harness(
      profile: _profile(urls: const ['https://x/1.jpg', 'https://x/2.jpg']),
    ));
    await tester.pumpAndSettle();

    final mainBadges = find.text('MAIN');
    expect(mainBadges, findsOneWidget);
  });

  testWidgets('renders the localized counter', (tester) async {
    await tester.pumpWidget(_harness(
      profile: _profile(urls: const [
        'https://x/1.jpg',
        'https://x/2.jpg',
        'https://x/3.jpg',
      ]),
    ));
    await tester.pumpAndSettle();

    expect(find.text('3 of 6 photos'), findsOneWidget);
  });
}
