import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/l10n_extension.dart';
import '../../../core/i18n/interest_label.dart';
import '../../../core/providers/toast_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/btn.dart';
import '../../../core/widgets/chip_tag.dart';
import '../../../core/widgets/photo_widget.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/user_profile.dart';
import '../providers/feed_provider.dart';
import '../providers/likes_provider.dart';

class ProfileViewScreen extends ConsumerWidget {
  final String userId;

  const ProfileViewScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userStreamProvider(userId));
    final likedSet = ref.watch(likedByMeProvider).valueOrNull ?? const <String>{};
    final isLiked = likedSet.contains(userId);
    final l = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(error: e),
        data: (profile) {
          if (profile == null) {
            return _ErrorBody(error: l.profileViewNotFound);
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
            onToggleLike: () {
              final l10n = l;
              ref
                  .read(likesControllerProvider)
                  .toggleLike(profile.uid)
                  .then((outcome) {
                if (!context.mounted) return;
                switch (outcome.kind) {
                  case LikeOutcomeKind.connected:
                    showToast(
                      ref,
                      outcome.partnerName.isEmpty
                          ? l10n.toastConnectedGeneric
                          : l10n.toastConnectedNamed(outcome.partnerName),
                    );
                    break;
                  case LikeOutcomeKind.liked:
                    showToast(
                      ref,
                      outcome.partnerName.isEmpty
                          ? l10n.toastLikedGeneric
                          : l10n.toastLikedNamed(outcome.partnerName),
                    );
                    break;
                  case LikeOutcomeKind.unliked:
                    break;
                }
              });
            },
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
    final l = AppLocalizations.of(context);

    return SafeArea(
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
                          ? l.profileNameAge(profile.name, profile.age)
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
                            ChipTag(label: l.localizedInterest(c)),
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
                    label: l.actionBack,
                    variant: BtnVariant.ghost,
                    onPressed: onBack,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Btn(
                    label: isLiked ? l.profileViewLiked : l.profileViewLike,
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
