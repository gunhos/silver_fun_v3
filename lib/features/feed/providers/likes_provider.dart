import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/my_profile_provider.dart';
import '../repository/likes_repository.dart';
import 'feed_provider.dart';

final likesRepositoryProvider = Provider<LikesRepository>((ref) {
  return LikesRepository(ref.watch(firestoreProvider));
});

final likedByMeProvider = StreamProvider<Set<String>>((ref) {
  final auth = ref.watch(authProvider).valueOrNull;
  if (auth == null) {
    return Stream<Set<String>>.value(const <String>{});
  }
  return ref.watch(likesRepositoryProvider).watchLikedByMe(auth.uid);
});

final likedByOthersProvider = StreamProvider<Set<String>>((ref) {
  final auth = ref.watch(authProvider).valueOrNull;
  if (auth == null) {
    return Stream<Set<String>>.value(const <String>{});
  }
  return ref.watch(likesRepositoryProvider).watchLikedByOthers(auth.uid);
});

enum LikeOutcomeKind { unliked, liked, connected }

class LikeOutcome {
  final LikeOutcomeKind kind;
  final String partnerName;

  const LikeOutcome(this.kind, this.partnerName);
}

class LikesController {
  final Ref _ref;

  LikesController(this._ref);

  Future<LikeOutcome> toggleLike(String targetUid) async {
    final user = _ref.read(authProvider).valueOrNull;
    if (user == null || user.uid == targetUid) {
      return const LikeOutcome(LikeOutcomeKind.unliked, '');
    }

    final repo = _ref.read(likesRepositoryProvider);
    final liked =
        _ref.read(likedByMeProvider).valueOrNull ?? const <String>{};
    final isLiked = liked.contains(targetUid);

    if (isLiked) {
      await repo.unlike(user.uid, targetUid);
      return const LikeOutcome(LikeOutcomeKind.unliked, '');
    }

    await repo.like(user.uid, targetUid);

    final mutual = await repo.isMutual(
      fromUid: user.uid,
      toUid: targetUid,
    );

    final profile =
        await _ref.read(feedRepositoryProvider).getUser(targetUid);
    final name = profile?.name ?? '';

    return LikeOutcome(
      mutual ? LikeOutcomeKind.connected : LikeOutcomeKind.liked,
      name,
    );
  }
}

final likesControllerProvider = Provider<LikesController>((ref) {
  return LikesController(ref);
});
