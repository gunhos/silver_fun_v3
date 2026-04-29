import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/btn.dart';
import '../../../core/widgets/chip_tag.dart';
import '../../../core/widgets/photo_widget.dart';
import '../../../models/user_profile.dart';
import '../providers/feed_provider.dart';
import '../providers/likes_provider.dart';

class ProfileViewScreen extends ConsumerWidget {
  final String userId;

  const ProfileViewScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileByIdProvider(userId));
    final likedSet = ref.watch(likedByMeProvider).valueOrNull ?? const <String>{};
    final isLiked = likedSet.contains(userId);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(error: e),
        data: (profile) {
          if (profile == null) {
            return const _ErrorBody(error: 'Profile not found.');
          }
          return _ProfileBody(
            profile: profile,
            isLiked: isLiked,
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/app/feed');
              }
            },
            onToggleLike: () =>
                ref.read(likesControllerProvider).toggleLike(profile.uid),
          );
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final UserProfile profile;
  final bool isLiked;
  final VoidCallback onBack;
  final VoidCallback onToggleLike;

  const _ProfileBody({
    required this.profile,
    required this.isLiked,
    required this.onBack,
    required this.onToggleLike,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: PhotoWidget(url: profile.photoUrl),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.age > 0
                          ? '${profile.name}, ${profile.age}'
                          : profile.name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (profile.city.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile.city,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (profile.bio.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        profile.bio,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.45,
                        ),
                      ),
                    ],
                    if (profile.interests.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in profile.interests)
                            ChipTag(label: c),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            child: _BackPill(onTap: onBack),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Row(
              children: [
                Expanded(
                  child: Btn(
                    label: 'Back',
                    variant: BtnVariant.ghost,
                    onPressed: onBack,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Btn(
                    label: isLiked ? 'Liked' : 'Like',
                    variant:
                        isLiked ? BtnVariant.dark : BtnVariant.primary,
                    onPressed: onToggleLike,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackPill extends StatelessWidget {
  final VoidCallback onTap;

  const _BackPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.arrow_back, color: AppColors.ink, size: 20),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final Object error;

  const _ErrorBody({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          error.toString(),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
      ),
    );
  }
}
