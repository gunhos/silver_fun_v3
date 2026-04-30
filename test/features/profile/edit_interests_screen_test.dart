import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

class _Harness {
  _Harness({required this.firestore, required this.profile});

  final FakeFirebaseFirestore firestore;
  final UserProfile profile;
  late final GoRouter router;
  late final Widget app;

  Widget build() {
    final mockUser = MockUser(uid: 'u1', email: 'u1@example.com');
    final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
        ),
        GoRoute(
          path: '/edit-interests',
          builder: (_, _) => const EditInterestsScreen(),
        ),
      ],
    );
    app = ProviderScope(
      overrides: [
        authProvider.overrideWith(
          (ref) => Stream<User?>.value(mockAuth.currentUser),
        ),
        firestoreProvider.overrideWithValue(firestore),
        myProfileProvider.overrideWith((ref) => Stream.value(profile)),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    return app;
  }

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    router.push('/edit-interests');
    await tester.pumpAndSettle();
  }

  Future<void> warmAuth(WidgetTester tester) async {
    final ctx = tester.element(find.byType(EditInterestsScreen));
    await ProviderScope.containerOf(ctx).read(authProvider.future);
  }
}

void main() {
  testWidgets('shows existing interests and disables save below 3',
      (tester) async {
    final h = _Harness(
      firestore: FakeFirebaseFirestore(),
      profile: _profile(),
    );
    await h.open(tester);

    expect(find.text('2 / 6 selected'), findsOneWidget);
    final saveBtn = find.widgetWithText(TextButton, 'Save');
    expect(tester.widget<TextButton>(saveBtn).onPressed, isNull);
  });

  testWidgets('selecting a third chip enables save', (tester) async {
    final h = _Harness(
      firestore: FakeFirebaseFirestore(),
      profile: _profile(),
    );
    await h.open(tester);

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
    final h = _Harness(firestore: firestore, profile: _profile());
    await h.open(tester);
    await h.warmAuth(tester);

    await tester.tap(find.text('Yoga'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    final doc = await firestore.collection('users').doc('u1').get();
    final stored = (doc.data()!['interests'] as List).cast<String>();
    expect(stored, containsAll(['Coffee', 'Reading', 'Yoga']));
    expect(stored.length, 3);

    // Drain the toast timer (2.2s).
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('cap at 6: tapping a 7th chip is a no-op', (tester) async {
    final h = _Harness(
      firestore: FakeFirebaseFirestore(),
      profile: _profile(interests: const [
        'Coffee',
        'Reading',
        'Yoga',
        'Travel',
        'Walking',
        'Cooking',
      ]),
    );
    await h.open(tester);

    expect(find.text('6 / 6 selected'), findsOneWidget);

    await tester.tap(find.text('Baking'));
    await tester.pumpAndSettle();
    expect(find.text('6 / 6 selected'), findsOneWidget);
  });
}
