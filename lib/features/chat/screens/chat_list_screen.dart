import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/photo_widget.dart';
import '../../../l10n/app_localizations.dart';
import '../models/match_thread.dart';
import '../providers/chats_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(matchThreadsProvider);
    final l = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          l.chatsTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: threadsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '${l.chatsErrorPrefix}\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        ),
        data: (threads) {
          if (threads.isEmpty) return const _EmptyState();

          final withMessages =
              threads.where((t) => t.lastMessage != null).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
            children: [
              _MatchBubblesRow(threads: threads),
              const SizedBox(height: 8),
              if (withMessages.isEmpty)
                const _NoConversationsHint()
              else
                ...withMessages.map((t) => _ThreadRow(thread: t)),
            ],
          );
        },
      ),
    );
  }
}

class _MatchBubblesRow extends StatelessWidget {
  final List<MatchThread> threads;

  const _MatchBubblesRow({required this.threads});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: threads.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final t = threads[index];
          return _MatchBubble(thread: t);
        },
      ),
    );
  }
}

class _MatchBubble extends StatelessWidget {
  final MatchThread thread;

  const _MatchBubble({required this.thread});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/chat/${thread.user.uid}'),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: PhotoWidget(url: thread.user.photoUrl),
                    ),
                  ),
                ),
                if (thread.unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: _UnreadDot(count: thread.unreadCount),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              thread.user.name,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadRow extends StatelessWidget {
  final MatchThread thread;

  const _ThreadRow({required this.thread});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final last = thread.lastMessage;
    final preview = last?.text ?? '';
    final isUnread = thread.unreadCount > 0;

    return GestureDetector(
      onTap: () => context.push('/chat/${thread.user.uid}'),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
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
                  child: PhotoWidget(url: thread.user.photoUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.user.name,
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (last?.sentAt != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(context, last!.sentAt!),
                            style: text.bodySmall
                                ?.copyWith(color: AppColors.muted),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preview,
                      style: text.bodySmall?.copyWith(
                        color: isUnread ? AppColors.ink : AppColors.muted,
                        fontWeight:
                            isUnread ? FontWeight.w600 : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isUnread) ...[
                const SizedBox(width: 8),
                _UnreadDot(count: thread.unreadCount),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  final int count;

  const _UnreadDot({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count > 9 ? '9+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NoConversationsHint extends StatelessWidget {
  const _NoConversationsHint();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          Text(
            l.chatsHintTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l.chatsHintSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
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
    final l = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.chatsEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l.chatsEmptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(BuildContext context, DateTime sentAt) {
  final l = AppLocalizations.of(context);
  final now = DateTime.now();
  final diff = now.difference(sentAt);
  if (diff.inMinutes < 1) return l.chatsTimeNow;
  if (diff.inMinutes < 60) return l.chatsTimeMinutes(diff.inMinutes);
  if (diff.inHours < 24) return l.chatsTimeHours(diff.inHours);
  if (diff.inDays < 7) return l.chatsTimeDays(diff.inDays);
  return '${sentAt.month}/${sentAt.day}';
}
