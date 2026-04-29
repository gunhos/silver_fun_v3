import '../../../models/chat_message.dart';
import '../../../models/user_profile.dart';

class MatchThread {
  final UserProfile user;
  final ChatMessage? lastMessage;
  final int unreadCount;

  const MatchThread({
    required this.user,
    this.lastMessage,
    this.unreadCount = 0,
  });

  MatchThread copyWith({
    UserProfile? user,
    ChatMessage? lastMessage,
    int? unreadCount,
  }) {
    return MatchThread(
      user: user ?? this.user,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
