import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:silver_fun/core/widgets/main_shell.dart';
import 'package:silver_fun/features/chat/models/match_thread.dart';
import 'package:silver_fun/features/chat/providers/chats_provider.dart';
import 'package:silver_fun/features/feed/providers/likes_provider.dart';
import 'package:silver_fun/l10n/app_localizations.dart';
import 'package:silver_fun/models/chat_message.dart';
import 'package:silver_fun/models/user_profile.dart';

UserProfile _user(String uid, String name) => UserProfile(
      uid: uid,
      name: name,
      age: 30,
      bio: '',
      photoUrl: '',
      interests: const [],
      city: '',
      published: true,
      profilePaused: false,
    );

Widget _harness({
  String initialLocation = '/app/feed',
  List<MatchThread> threads = const [],
  Set<String> likers = const {},
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (_, _, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/app/feed',
            builder: (_, _) => const Scaffold(body: Text('feed-body')),
          ),
          GoRoute(
            path: '/app/liked-you',
            builder: (_, _) => const Scaffold(body: Text('liked-body')),
          ),
          GoRoute(
            path: '/app/meetups',
            builder: (_, _) => const Scaffold(body: Text('meetups-body')),
          ),
          GoRoute(
            path: '/app/chats',
            builder: (_, _) => const Scaffold(body: Text('chats-body')),
          ),
          GoRoute(
            path: '/app/you',
            builder: (_, _) => const Scaffold(body: Text('you-body')),
          ),
        ],
      ),
    ],
  );

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
}

void main() {
  testWidgets('MainShell renders five navigation destinations',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Liked you'), findsOneWidget);
    expect(find.text('Meetups'), findsOneWidget);
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.text('feed-body'), findsOneWidget);
  });

  testWidgets('MainShell selectedIndex tracks current location',
      (tester) async {
    await tester.pumpWidget(_harness(initialLocation: '/app/chats'));
    await tester.pumpAndSettle();

    final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(nav.selectedIndex, 3);
    expect(find.text('chats-body'), findsOneWidget);
  });

  testWidgets('MainShell selects Meetups tab when on /app/meetups',
      (tester) async {
    await tester.pumpWidget(_harness(initialLocation: '/app/meetups'));
    await tester.pumpAndSettle();

    final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(nav.selectedIndex, 2);
    expect(find.text('meetups-body'), findsOneWidget);
  });

  testWidgets('MainShell shows Liked You badge when likers present',
      (tester) async {
    await tester.pumpWidget(_harness(likers: const {'a', 'b', 'c'}));
    await tester.pumpAndSettle();

    expect(find.byType(Badge), findsWidgets);
    expect(find.text('3'), findsWidgets);
  });

  testWidgets('MainShell shows Chats badge from total unread', (tester) async {
    final threads = [
      MatchThread(
        user: _user('u1', 'A'),
        lastMessage: ChatMessage(
          id: 'm1',
          senderId: 'u1',
          text: 'hi',
          sentAt: DateTime.utc(2026, 4, 28),
          read: false,
        ),
        unreadCount: 2,
      ),
      MatchThread(
        user: _user('u2', 'B'),
        lastMessage: ChatMessage(
          id: 'm2',
          senderId: 'u2',
          text: 'yo',
          sentAt: DateTime.utc(2026, 4, 28),
          read: false,
        ),
        unreadCount: 3,
      ),
    ];

    await tester.pumpWidget(_harness(threads: threads));
    await tester.pumpAndSettle();

    expect(find.text('5'), findsWidgets);
  });

  testWidgets('MainShell ToastOverlay sits above navigation bar',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    // ToastOverlay always exists as part of MainShell, even when hidden.
    expect(find.byType(AnimatedOpacity), findsOneWidget);
  });
}
