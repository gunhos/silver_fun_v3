import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/meetup.dart';
import '../providers/meetups_provider.dart';

class UpcomingMeetupsScreen extends ConsumerWidget {
  const UpcomingMeetupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final meetupsAsync = ref.watch(upcomingMeetupsProvider);
    final myUid = ref.watch(authProvider).valueOrNull?.uid;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          l.meetupsTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        actions: [
          IconButton(
            tooltip: l.meetupsCreateButton,
            icon: const Icon(Icons.add, color: AppColors.ink),
            onPressed: () => context.push('/meetups/new'),
          ),
        ],
      ),
      body: meetupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '${l.meetupsErrorPrefix}\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        ),
        data: (meetups) {
          if (meetups.isEmpty) return const _EmptyState();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: meetups.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final m = meetups[index];
              return _MeetupCard(
                meetup: m,
                myUid: myUid,
                onTap: () => context.push('/meetups/${m.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class _MeetupCard extends StatelessWidget {
  final Meetup meetup;
  final String? myUid;
  final VoidCallback onTap;

  const _MeetupCard({
    required this.meetup,
    required this.myUid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final isOrganizer = myUid != null && meetup.isOrganizer(myUid!);
    final isJoined = myUid != null && meetup.hasJoined(myUid!);
    final whenLine = _formatWhen(meetup.startsAt);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    meetup.title,
                    style: text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isOrganizer)
                  _Pill(label: l.meetupListHostingBadge, accent: true)
                else if (isJoined)
                  _Pill(label: l.meetupListJoinedBadge, accent: false),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event, size: 16, color: AppColors.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    whenLine,
                    style: text.bodySmall?.copyWith(color: AppColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.place_outlined,
                    size: 16, color: AppColors.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    meetup.location,
                    style: text.bodySmall?.copyWith(color: AppColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _attendeeLine(l, meetup),
              style: text.bodySmall?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _attendeeLine(AppLocalizations l, Meetup meetup) {
  if (meetup.maxAttendees != null) {
    return l.meetupDetailJoinedWithCapacity(
        meetup.attendeeCount, meetup.maxAttendees!);
  }
  return l.meetupDetailJoined(meetup.attendeeCount);
}

String _formatWhen(DateTime startsAt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${startsAt.year}-${two(startsAt.month)}-${two(startsAt.day)} '
      '${two(startsAt.hour)}:${two(startsAt.minute)}';
}

class _Pill extends StatelessWidget {
  final String label;
  final bool accent;

  const _Pill({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent ? AppColors.accent : AppColors.chipBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent ? Colors.white : AppColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
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
              l.meetupsEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l.meetupsEmptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
