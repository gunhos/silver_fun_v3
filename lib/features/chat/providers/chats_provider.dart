import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/chat_message.dart';
import '../../auth/providers/auth_provider.dart';
import '../../feed/providers/feed_provider.dart';
import '../../feed/providers/likes_provider.dart';
import '../../profile/providers/my_profile_provider.dart';
import '../models/match_thread.dart';
import '../repository/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(firestoreProvider));
});

final matchesProvider = Provider<Set<String>>((ref) {
  final liked = ref.watch(likedByMeProvider).valueOrNull ?? const <String>{};
  final likers =
      ref.watch(likedByOthersProvider).valueOrNull ?? const <String>{};
  return liked.intersection(likers);
});

final matchThreadsProvider = StreamProvider<List<MatchThread>>((ref) {
  final auth = ref.watch(authProvider).valueOrNull;
  if (auth == null) return Stream.value(const <MatchThread>[]);
  final myUid = auth.uid;

  final matches = ref.watch(matchesProvider);
  if (matches.isEmpty) return Stream.value(const <MatchThread>[]);

  final chatRepo = ref.watch(chatRepositoryProvider);
  final feedRepo = ref.watch(feedRepositoryProvider);

  final controller = StreamController<List<MatchThread>>();
  final state = <String, MatchThread>{};
  final subs = <StreamSubscription<dynamic>>[];
  var disposed = false;

  void emit() {
    if (disposed || controller.isClosed) return;
    final list = state.values.toList()
      ..sort((a, b) {
        final at = a.lastMessage?.sentAt;
        final bt = b.lastMessage?.sentAt;
        if (at == null && bt == null) {
          return a.user.name.toLowerCase().compareTo(b.user.name.toLowerCase());
        }
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
    controller.add(list);
  }

  Future<void> initFor(String otherUid) async {
    final profile = await feedRepo.getUser(otherUid);
    if (profile == null || disposed) return;
    state[otherUid] = MatchThread(user: profile);
    emit();
    final cid = ChatRepository.chatId(myUid, otherUid);
    final sub = chatRepo.watchMessages(cid).listen((messages) {
      if (disposed) return;
      final last = messages.isEmpty ? null : messages.last;
      final unread =
          messages.where((m) => m.senderId != myUid && !m.read).length;
      state[otherUid] = MatchThread(
        user: profile,
        lastMessage: last,
        unreadCount: unread,
      );
      emit();
    });
    subs.add(sub);
  }

  for (final uid in matches) {
    initFor(uid);
  }

  ref.onDispose(() {
    disposed = true;
    for (final s in subs) {
      s.cancel();
    }
    controller.close();
  });

  return controller.stream;
});

final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).watchMessages(chatId);
});
