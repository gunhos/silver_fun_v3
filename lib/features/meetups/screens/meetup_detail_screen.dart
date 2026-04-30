import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/l10n_extension.dart';
import '../../../core/providers/toast_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/btn.dart';
import '../../auth/providers/auth_provider.dart';
import '../../feed/providers/feed_provider.dart';
import '../models/meetup.dart';
import '../providers/meetups_provider.dart';

class MeetupDetailScreen extends ConsumerWidget {
  final String meetupId;

  const MeetupDetailScreen({super.key, required this.meetupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final meetupAsync = ref.watch(meetupByIdProvider(meetupId));
    final myUid = ref.watch(authProvider).valueOrNull?.uid;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          l.meetupDetailTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: meetupAsync.when(
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
        data: (m) {
          if (m == null) {
            return _Centered(text: l.meetupDetailNotFound);
          }
          return _DetailBody(meetup: m, myUid: myUid);
        },
      ),
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  final Meetup meetup;
  final String? myUid;

  const _DetailBody({required this.meetup, required this.myUid});

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  bool _busy = false;

  Future<void> _onJoin() async {
    final myUid = widget.myUid;
    if (myUid == null || _busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(meetupsRepositoryProvider)
          .join(meetupId: widget.meetup.id, uid: myUid);
      if (!mounted) return;
      showToast(ref, context.l10n.toastMeetupJoined);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onLeave() async {
    final myUid = widget.myUid;
    if (myUid == null || _busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(meetupsRepositoryProvider)
          .leave(meetupId: widget.meetup.id, uid: myUid);
      if (!mounted) return;
      showToast(ref, context.l10n.toastMeetupLeft);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onCancel() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(meetupsRepositoryProvider).cancel(widget.meetup.id);
      if (!mounted) return;
      showToast(ref, context.l10n.toastMeetupCanceled);
      context.pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final m = widget.meetup;
    final myUid = widget.myUid;
    final isOrganizer = myUid != null && m.isOrganizer(myUid);
    final isJoined = myUid != null && m.hasJoined(myUid);
    final hostProfileAsync =
        ref.watch(profileByIdProvider(m.organizerUid));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (m.canceled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.chipBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l.meetupDetailCanceledLabel,
                textAlign: TextAlign.center,
                style: text.titleSmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Text(
            m.title,
            style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _Row(icon: Icons.event, label: _formatDateTime(m.startsAt)),
          const SizedBox(height: 6),
          _Row(icon: Icons.place_outlined, label: m.location),
          const SizedBox(height: 6),
          hostProfileAsync.when(
            loading: () => _Row(
              icon: Icons.person_outline,
              label: l.meetupDetailHostedBy(' …'),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (host) {
              final label = isOrganizer
                  ? l.meetupDetailHostedByYou
                  : l.meetupDetailHostedBy(host?.name ?? '');
              return _Row(icon: Icons.person_outline, label: label);
            },
          ),
          const SizedBox(height: 6),
          _Row(
            icon: Icons.group_outlined,
            label: m.maxAttendees != null
                ? l.meetupDetailJoinedWithCapacity(
                    m.attendeeCount, m.maxAttendees!)
                : l.meetupDetailJoined(m.attendeeCount),
          ),
          if (m.description.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(m.description, style: text.bodyLarge),
            ),
          ],
          const SizedBox(height: 28),
          _ActionButton(
            meetup: m,
            isOrganizer: isOrganizer,
            isJoined: isJoined,
            busy: _busy,
            onJoin: _onJoin,
            onLeave: _onLeave,
            onCancel: _onCancel,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final Meetup meetup;
  final bool isOrganizer;
  final bool isJoined;
  final bool busy;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final VoidCallback onCancel;

  const _ActionButton({
    required this.meetup,
    required this.isOrganizer,
    required this.isJoined,
    required this.busy,
    required this.onJoin,
    required this.onLeave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (meetup.canceled) {
      return const SizedBox.shrink();
    }
    if (isOrganizer) {
      return Btn(
        label: l.meetupDetailCancelButton,
        variant: BtnVariant.dark,
        onPressed: busy ? null : onCancel,
      );
    }
    if (isJoined) {
      return Btn(
        label: l.meetupDetailLeaveButton,
        variant: BtnVariant.ghost,
        onPressed: busy ? null : onLeave,
      );
    }
    if (meetup.isFull) {
      return Btn(
        label: l.meetupDetailFullLabel,
        onPressed: null,
      );
    }
    return Btn(
      label: l.meetupDetailJoinButton,
      onPressed: busy ? null : onJoin,
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Row({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.ink, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class _Centered extends StatelessWidget {
  final String text;
  const _Centered({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
      '${two(dt.hour)}:${two(dt.minute)}';
}
