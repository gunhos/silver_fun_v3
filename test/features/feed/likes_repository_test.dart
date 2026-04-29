import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silver_fun/features/feed/repository/likes_repository.dart';

void main() {
  group('LikesRepository', () {
    late FakeFirebaseFirestore firestore;
    late LikesRepository repo;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repo = LikesRepository(firestore);
    });

    Future<bool> forwardExists(String from, String to) async {
      final doc = await firestore
          .collection('likes')
          .doc(from)
          .collection('liked')
          .doc(to)
          .get();
      return doc.exists;
    }

    Future<bool> reverseExists(String from, String to) async {
      final doc = await firestore
          .collection('likedBy')
          .doc(to)
          .collection('from')
          .doc(from)
          .get();
      return doc.exists;
    }

    test('like writes both forward and reverse index docs', () async {
      await repo.like('me', 'maya');

      expect(await forwardExists('me', 'maya'), isTrue);
      expect(await reverseExists('me', 'maya'), isTrue);
    });

    test('unlike deletes both forward and reverse index docs', () async {
      await repo.like('me', 'maya');
      expect(await forwardExists('me', 'maya'), isTrue);
      expect(await reverseExists('me', 'maya'), isTrue);

      await repo.unlike('me', 'maya');

      expect(await forwardExists('me', 'maya'), isFalse);
      expect(await reverseExists('me', 'maya'), isFalse);
    });

    test('unlike on a non-existent like is idempotent', () async {
      await repo.unlike('me', 'maya');

      expect(await forwardExists('me', 'maya'), isFalse);
      expect(await reverseExists('me', 'maya'), isFalse);
    });

    test('isMutual returns true only when reciprocal like exists', () async {
      await repo.like('me', 'maya');
      expect(
        await repo.isMutual(fromUid: 'me', toUid: 'maya'),
        isFalse,
      );

      await repo.like('maya', 'me');
      expect(
        await repo.isMutual(fromUid: 'me', toUid: 'maya'),
        isTrue,
      );
    });

    test('watchLikedByMe emits the set of liked uids', () async {
      await repo.like('me', 'a');
      await repo.like('me', 'b');

      final liked = await repo.watchLikedByMe('me').first;

      expect(liked, equals({'a', 'b'}));
    });

    test('watchLikedByMe emits an empty set when nothing is liked', () async {
      final liked = await repo.watchLikedByMe('me').first;
      expect(liked, isEmpty);
    });

    test('watchLikedByOthers emits the set of liker uids', () async {
      await repo.like('alice', 'me');
      await repo.like('bob', 'me');

      final likers = await repo.watchLikedByOthers('me').first;

      expect(likers, equals({'alice', 'bob'}));
    });

    test('watchLikedByOthers excludes likes targeting other users', () async {
      await repo.like('alice', 'me');
      await repo.like('alice', 'someone-else');

      final likers = await repo.watchLikedByOthers('me').first;

      expect(likers, equals({'alice'}));
    });
  });
}
