import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/photo_widget.dart';
import '../../../models/chat_message.dart';
import '../../../models/user_profile.dart';
import '../../auth/providers/auth_provider.dart';
import '../../feed/providers/feed_provider.dart';
import '../providers/chats_provider.dart';
import '../repository/chat_repository.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String userId;

  const ChatScreen({super.key, required this.userId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _markedRead = false;
  bool _sending = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? get _myUid => ref.read(authProvider).valueOrNull?.uid;

  String? _chatIdFor(String? me) {
    if (me == null) return null;
    return ChatRepository.chatId(me, widget.userId);
  }

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    if (_sending) return;
    final me = _myUid;
    final cid = _chatIdFor(me);
    if (me == null || cid == null) return;
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    setState(() => _sending = true);
    _textController.clear();
    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            chatId: cid,
            senderId: me,
            text: text,
          );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _maybeMarkRead(String chatId, String myUid) {
    if (_markedRead) return;
    _markedRead = true;
    Future.microtask(() {
      ref.read(chatRepositoryProvider).markRead(
            chatId: chatId,
            myUid: myUid,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = _myUid;
    final cid = _chatIdFor(me);

    if (me == null || cid == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final profileAsync = ref.watch(profileByIdProvider(widget.userId));
    final messagesAsync = ref.watch(chatMessagesProvider(cid));

    ref.listen<AsyncValue<List<ChatMessage>>>(
      chatMessagesProvider(cid),
      (prev, next) {
        if (next.hasValue && next.value!.isNotEmpty) {
          _scheduleScrollToBottom();
        }
        if (next.hasValue) {
          _maybeMarkRead(cid, me);
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(profileAsync: profileAsync),
            Expanded(
              child: messagesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load messages.\n$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                ),
                data: (messages) => _MessagesList(
                  scrollController: _scrollController,
                  messages: messages,
                  myUid: me,
                  matchProfile: profileAsync.valueOrNull,
                ),
              ),
            ),
            _SendBar(
              controller: _textController,
              onSend: _send,
              sending: _sending,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AsyncValue<UserProfile?> profileAsync;

  const _Header({required this.profileAsync});

  @override
  Widget build(BuildContext context) {
    final profile = profileAsync.valueOrNull;
    final name = profile?.name ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ink),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/app/chats');
              }
            },
          ),
          ClipOval(
            child: SizedBox(
              width: 36,
              height: 36,
              child: PhotoWidget(url: profile?.photoUrl),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name.isEmpty ? 'Friend' : name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Connected',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.favorite, color: AppColors.accent, size: 22),
        ],
      ),
    );
  }
}

class _MessagesList extends StatelessWidget {
  final ScrollController scrollController;
  final List<ChatMessage> messages;
  final String myUid;
  final UserProfile? matchProfile;

  const _MessagesList({
    required this.scrollController,
    required this.messages,
    required this.myUid,
    required this.matchProfile,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: messages.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _MatchCard(profile: matchProfile);
        }
        final i = index - 1;
        final msg = messages[i];
        final isMine = msg.senderId == myUid;
        final prev = i == 0 ? null : messages[i - 1];
        final showAvatar = !isMine && (prev == null || prev.senderId != msg.senderId);
        return _MessageBubble(
          message: msg,
          isMine: isMine,
          avatarUrl: showAvatar ? matchProfile?.photoUrl : null,
          showAvatar: showAvatar,
        );
      },
    );
  }
}

class _MatchCard extends StatelessWidget {
  final UserProfile? profile;

  const _MatchCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile?.name ?? '';
    final text = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 56,
              height: 56,
              child: PhotoWidget(url: profile?.photoUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "You're now connected! 🎉",
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name.isEmpty
                      ? 'Say hello to start chatting.'
                      : 'Say hello to $name to start chatting.',
                  style: text.bodySmall?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Stay safe — never share personal info, passwords, or money.',
                        style:
                            text.bodySmall?.copyWith(color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final String? avatarUrl;
  final bool showAvatar;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.avatarUrl,
    required this.showAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isMine ? AppColors.accent : AppColors.surface;
    final fg = isMine ? Colors.white : AppColors.ink;
    final border = isMine ? null : Border.all(color: AppColors.line);
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isMine ? 20 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 20),
    );

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.7,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: border,
      ),
      child: Text(
        message.text,
        style: TextStyle(color: fg, fontSize: 15, height: 1.35),
      ),
    );

    final avatarSlot = SizedBox(
      width: 32,
      child: showAvatar
          ? ClipOval(
              child: SizedBox(
                width: 28,
                height: 28,
                child: PhotoWidget(url: avatarUrl),
              ),
            )
          : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isMine
            ? [bubble]
            : [avatarSlot, const SizedBox(width: 8), Flexible(child: bubble)],
      ),
    );
  }
}

class _SendBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool sending;

  const _SendBar({
    required this.controller,
    required this.onSend,
    required this.sending,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: Border.all(color: AppColors.line),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: const InputDecoration(
                    hintText: 'Message',
                    hintStyle: TextStyle(color: AppColors.muted),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(500),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SendButton(onTap: sending ? null : onSend),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _SendButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: disabled ? AppColors.muted : AppColors.accent,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.send, color: Colors.white, size: 20),
      ),
    );
  }
}
