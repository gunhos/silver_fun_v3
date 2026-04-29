import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/feed/screens/profile_view_screen.dart';
import '../../features/onboarding/screens/add_photo_screen.dart';
import '../../features/onboarding/screens/edit_bio_screen.dart';
import '../../features/onboarding/screens/interests_screen.dart';
import '../../features/onboarding/screens/name_age_screen.dart';
import '../../features/onboarding/screens/preview_screen.dart';
import '../../features/profile/providers/my_profile_provider.dart';
import '../../features/profile/screens/liked_you_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/profile/screens/you_screen.dart';
import '../widgets/stub_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, _) => notifyListeners());
    _ref.listen(myProfileProvider, (_, _) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = _ref.read(authProvider);
    if (auth.isLoading) return null;

    final user = auth.valueOrNull;
    final loc = state.matchedLocation;
    final atSignIn = loc == '/signin';

    if (user == null) {
      return atSignIn ? null : '/signin';
    }

    final profileAsync = _ref.read(myProfileProvider);
    if (profileAsync.isLoading) return null;
    final profile = profileAsync.valueOrNull;
    final published = profile?.published ?? false;

    final atOnboarding = loc.startsWith('/onboarding');

    if (!published) {
      if (atOnboarding) return null;
      return '/onboarding/name';
    }

    if (atSignIn || atOnboarding || loc == '/') {
      return '/app/feed';
    }
    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(path: '/', builder: (_, _) => const StubScreen(title: 'Loading')),
      GoRoute(path: '/signin', builder: (_, _) => const SignInScreen()),
      GoRoute(
        path: '/onboarding/name',
        builder: (_, _) => const NameAgeScreen(),
      ),
      GoRoute(
        path: '/onboarding/photo',
        builder: (_, _) => const AddPhotoScreen(),
      ),
      GoRoute(
        path: '/onboarding/bio',
        builder: (_, _) => const EditBioScreen(),
      ),
      GoRoute(
        path: '/onboarding/interests',
        builder: (_, _) => const InterestsScreen(),
      ),
      GoRoute(
        path: '/onboarding/preview',
        builder: (_, _) => const PreviewScreen(),
      ),
      GoRoute(
        path: '/app/feed',
        builder: (_, _) => const FeedScreen(),
      ),
      GoRoute(
        path: '/app/chats',
        builder: (_, _) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/app/liked-you',
        builder: (_, _) => const LikedYouScreen(),
      ),
      GoRoute(
        path: '/app/you',
        builder: (_, _) => const YouScreen(),
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (_, state) =>
            ProfileViewScreen(userId: state.pathParameters['userId']!),
      ),
      GoRoute(
        path: '/chat/:userId',
        builder: (_, state) =>
            ChatScreen(userId: state.pathParameters['userId']!),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/edit-bio',
        builder: (_, _) => const EditBioScreen(standalone: true),
      ),
    ],
    debugLogDiagnostics: kDebugMode,
  );
});
