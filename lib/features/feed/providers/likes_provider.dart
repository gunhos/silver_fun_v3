import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/toast_provider.dart';
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

class LikesController {
  final Ref _ref;

  LikesController(this._ref);

  Future<void> toggleLike(String targetUid) async {
    final user = _ref.read(authProvider).valueOrNull;
    if (user == null || user.uid == targetUid) return;

    final repo = _ref.read(likesRepositoryProvider);
    final liked =
        _ref.read(likedByMeProvider).valueOrNull ?? const <String>{};
    final isLiked = liked.contains(targetUid);

    if (isLiked) {
      await repo.unlike(user.uid, targetUid);
      return;
    }

    await repo.like(user.uid, targetUid);

    final mutual = await repo.isMutual(
      fromUid: user.uid,
      toUid: targetUid,
    );

    final profile =
        await _ref.read(feedRepositoryProvider).getUser(targetUid);
    final name = profile?.name ?? '';

    if (mutual) {
      showToastFromRef(
        _ref,
        name.isEmpty
            ? "You're now connected! 🎉"
            : "You and $name are now connected! 🎉",
      );
    } else {
      showToastFromRef(_ref, name.isEmpty ? 'Liked' : 'Liked $name');
    }
  }
}

final likesControllerProvider = Provider<LikesController>((ref) {
  return LikesController(ref);
});
