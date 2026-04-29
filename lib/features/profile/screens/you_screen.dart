import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/btn.dart';
import '../../../core/widgets/chip_tag.dart';
import '../../../core/widgets/photo_widget.dart';
import '../../../models/user_profile.dart';
import '../providers/my_profile_provider.dart';

class YouScreen extends ConsumerWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('You', style: Theme.of(context).textTheme.headlineSmall),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined, color: AppColors.ink),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load your profile.\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return const _EmptyState();
          }
          return _YouBody(profile: profile);
        },
      ),
    );
  }
}

class _YouBody extends StatelessWidget {
  final UserProfile profile;

  const _YouBody({required this.profile});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final paused = profile.profilePaused;
    final published = profile.published;

    final statusLabel = !published
        ? 'Not published'
        : (paused ? 'Profile paused' : 'Profile live');
    final statusColor = !published || paused
        ? AppColors.muted
        : AppColors.accent;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ClipOval(
              child: SizedBox(
                width: 84,
                height: 84,
                child: PhotoWidget(url: profile.photoUrl),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              profile.age > 0
                  ? '${profile.name}, ${profile.age}'
                  : profile.name,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  statusLabel,
                  style: text.bodyMedium?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          if (profile.bio.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                profile.bio,
                style: text.bodyLarge?.copyWith(height: 1.45),
              ),
            ),
          ],
          if (profile.interests.isNotEmpty) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in profile.interests) ChipTag(label: c),
              ],
            ),
          ],
          const SizedBox(height: 28),
          Btn(
            label: 'Preview profile',
            variant: BtnVariant.ghost,
            onPressed: published
                ? () => context.push('/profile/${profile.uid}')
                : null,
          ),
          const SizedBox(height: 12),
          Btn(
            label: 'Edit bio',
            onPressed: () => context.push('/edit-bio'),
          ),
        ],
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
        child: Text(
          'Your profile is not ready yet.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
              ),
        ),
      ),
    );
  }
}
