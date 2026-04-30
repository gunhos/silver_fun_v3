import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/photo_widget.dart';
import '../../../models/user_profile.dart';
import '../../feed/providers/feed_provider.dart';
import '../../feed/providers/likes_provider.dart';

class LikedYouScreen extends ConsumerWidget {
  const LikedYouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likersAsync = ref.watch(likedByOthersProvider);
    final l = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          l.likedYouTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: likersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '${l.likedYouErrorPrefix}\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        ),
        data: (likers) {
          if (likers.isEmpty) {
            return const _EmptyState();
          }
          final ids = likers.toList();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: ids.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final uid = ids[index];
              return _LikerRow(uid: uid);
            },
          );
        },
      ),
    );
  }
}

class _LikerRow extends ConsumerWidget {
  final String uid;

  const _LikerRow({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userStreamProvider(uid));

    return profileAsync.when(
      loading: () => const _RowSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        return _LikerCard(
          profile: profile,
          onTap: () => context.push('/profile/${profile.uid}'),
        );
      },
    );
  }
}

class _LikerCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onTap;

  const _LikerCard({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final title = profile.age > 0
        ? context.l10n.profileNameAge(profile.name, profile.age)
        : profile.name;
    final snippet = profile.bio.isEmpty
        ? (profile.city.isEmpty ? '' : profile.city)
        : profile.bio;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipOval(
              child: SizedBox(
                width: 56,
                height: 56,
                child: PhotoWidget(url: profile.photoUrl),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (snippet.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      snippet,
                      style: text.bodySmall?.copyWith(color: AppColors.muted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.favorite, color: AppColors.accent, size: 22),
          ],
        ),
      ),
    );
  }
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.likedYouEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l.likedYouEmptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
