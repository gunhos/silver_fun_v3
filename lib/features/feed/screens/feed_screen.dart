import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chip_tag.dart';
import '../../../core/widgets/heart_button.dart';
import '../../../core/widgets/photo_widget.dart';
import '../../../models/user_profile.dart';
import '../providers/feed_provider.dart';
import '../providers/likes_provider.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Discover',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: feed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load feed.\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        ),
        data: (profiles) {
          if (profiles.isEmpty) {
            return const _EmptyState();
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.62,
            ),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return _ProfileCard(
                key: ValueKey(profile.uid),
                profile: profile,
                onTap: () => context.push('/profile/${profile.uid}'),
                onLike: () =>
                    ref.read(likesControllerProvider).toggleLike(profile.uid),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onTap;
  final VoidCallback onLike;

  const _ProfileCard({
    super.key,
    required this.profile,
    required this.onTap,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final chips = profile.interests.take(2).toList();
    final radius = BorderRadius.circular(AppTheme.radiusCard);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: radius,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PhotoWidget(url: profile.photoUrl),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: HeartButton(
                      liked: profile.liked,
                      onTap: onLike,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    profile.age > 0
                        ? '${profile.name}, ${profile.age}'
                        : profile.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (profile.city.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      profile.city,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 34,
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.centerLeft,
                          maxWidth: double.infinity,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < chips.length; i++) ...[
                                if (i > 0) const SizedBox(width: 6),
                                ChipTag(label: chips[i], size: ChipSize.sm),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No one to discover yet.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back soon — new profiles are on the way.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
