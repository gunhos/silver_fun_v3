import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/providers/chats_provider.dart';
import '../../features/feed/providers/likes_provider.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'toast_overlay.dart';

typedef _LabelFn = String Function(AppLocalizations l);

class _TabSpec {
  final String location;
  final _LabelFn label;
  final IconData icon;
  final IconData selectedIcon;

  const _TabSpec({
    required this.location,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

String _labelDiscover(AppLocalizations l) => l.navDiscover;
String _labelLikedYou(AppLocalizations l) => l.navLikedYou;
String _labelMeetups(AppLocalizations l) => l.navMeetups;
String _labelChats(AppLocalizations l) => l.navChats;
String _labelYou(AppLocalizations l) => l.navYou;

const List<_TabSpec> _tabs = [
  _TabSpec(
    location: '/app/feed',
    label: _labelDiscover,
    icon: Icons.explore_outlined,
    selectedIcon: Icons.explore,
  ),
  _TabSpec(
    location: '/app/liked-you',
    label: _labelLikedYou,
    icon: Icons.favorite_outline,
    selectedIcon: Icons.favorite,
  ),
  _TabSpec(
    location: '/app/meetups',
    label: _labelMeetups,
    icon: Icons.event_outlined,
    selectedIcon: Icons.event,
  ),
  _TabSpec(
    location: '/app/chats',
    label: _labelChats,
    icon: Icons.chat_bubble_outline,
    selectedIcon: Icons.chat_bubble,
  ),
  _TabSpec(
    location: '/app/you',
    label: _labelYou,
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _selectedIndexFor(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location == _tabs[i].location ||
          location.startsWith('${_tabs[i].location}/')) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _selectedIndexFor(loc);
    final l = AppLocalizations.of(context);

    final threads =
        ref.watch(matchThreadsProvider).valueOrNull ?? const [];
    final unreadTotal =
        threads.fold<int>(0, (sum, t) => sum + t.unreadCount);

    final likers =
        ref.watch(likedByOthersProvider).valueOrNull ?? const <String>{};
    final likedCount = likers.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned.fill(child: child),
          const ToastOverlay(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) {
            final target = _tabs[i].location;
            if (target == loc) return;
            context.go(target);
          },
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.chipBg,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (var i = 0; i < _tabs.length; i++)
              _buildDestination(
                _tabs[i],
                badgeCount: i == 1
                    ? likedCount
                    : (i == 3 ? unreadTotal : 0),
                l: l,
              ),
          ],
        ),
      ),
    );
  }

  NavigationDestination _buildDestination(
    _TabSpec t, {
    required int badgeCount,
    required AppLocalizations l,
  }) {
    final label = t.label(l);
    if (badgeCount > 0) {
      return NavigationDestination(
        icon: Badge.count(count: badgeCount, child: Icon(t.icon)),
        selectedIcon:
            Badge.count(count: badgeCount, child: Icon(t.selectedIcon)),
        label: label,
      );
    }
    return NavigationDestination(
      icon: Icon(t.icon),
      selectedIcon: Icon(t.selectedIcon),
      label: label,
    );
  }
}
