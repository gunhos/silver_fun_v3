import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/user_profile.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/my_profile_provider.dart';
import '../repository/feed_repository.dart';
import 'likes_provider.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(ref.watch(firestoreProvider));
});

final feedProvider = StreamProvider<List<UserProfile>>((ref) {
  final auth = ref.watch(authProvider).valueOrNull;
  if (auth == null) {
    return Stream<List<UserProfile>>.value(const <UserProfile>[]);
  }
  final repo = ref.watch(feedRepositoryProvider);
  final liked = ref.watch(likedByMeProvider).valueOrNull ?? const <String>{};
  return repo.watchFeed(auth.uid).map((profiles) {
    return profiles
        .map((p) => p.copyWith(liked: liked.contains(p.uid)))
        .toList();
  });
});

final profileByIdProvider =
    FutureProvider.family<UserProfile?, String>((ref, uid) async {
  return ref.watch(feedRepositoryProvider).getUser(uid);
});
