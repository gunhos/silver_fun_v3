import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silver_fun/features/feed/repository/feed_repository.dart';

Map<String, dynamic> _userDoc({
  required String name,
  bool published = true,
  bool paused = false,
  String city = 'Brooklyn',
  int age = 30,
}) {
  return {
    'name': name,
    'age': age,
    'bio': 'Hi.',
    'photoUrl': '',
    'interests': const ['Coffee'],
    'city': city,
    'published': published,
    'profilePaused': paused,
  };
}

void main() {
  group('FeedRepository', () {
    late FakeFirebaseFirestore firestore;
    late FeedRepository repo;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repo = FeedRepository(firestore);
    });

    Future<void> seed(String uid, Map<String, dynamic> data) async {
      await firestore.collection('users').doc(uid).set(data);
    }

    test('watchFeed includes published, non-paused profiles', () async {
      await seed('me', _userDoc(name: 'Me'));
      await seed('a', _userDoc(name: 'Alice'));
      await seed('b', _userDoc(name: 'Bob'));

      final list = await repo.watchFeed('me').first;

      expect(list.map((p) => p.uid), unorderedEquals(['a', 'b']));
      expect(list.map((p) => p.name), unorderedEquals(['Alice', 'Bob']));
    });

    test('watchFeed excludes unpublished profiles', () async {
      await seed('me', _userDoc(name: 'Me'));
      await seed('a', _userDoc(name: 'Alice', published: false));
      await seed('b', _userDoc(name: 'Bob'));

      final list = await repo.watchFeed('me').first;

      expect(list.map((p) => p.uid), equals(['b']));
    });

    test('watchFeed excludes profilePaused profiles', () async {
      await seed('me', _userDoc(name: 'Me'));
      await seed('a', _userDoc(name: 'Alice', paused: true));
      await seed('b', _userDoc(name: 'Bob'));

      final list = await repo.watchFeed('me').first;

      expect(list.map((p) => p.uid), equals(['b']));
    });

    test('watchFeed excludes the current user', () async {
      await seed('me', _userDoc(name: 'Me'));
      await seed('a', _userDoc(name: 'Alice'));

      final list = await repo.watchFeed('me').first;

      expect(list.map((p) => p.uid), equals(['a']));
      expect(list.any((p) => p.uid == 'me'), isFalse);
    });

    test('watchFeed emits an empty list when no published profiles exist',
        () async {
      await seed('me', _userDoc(name: 'Me'));
      await seed('a', _userDoc(name: 'Alice', published: false));

      final list = await repo.watchFeed('me').first;

      expect(list, isEmpty);
    });

    test('getUser returns null for missing uid', () async {
      final result = await repo.getUser('nope');
      expect(result, isNull);
    });

    test('getUser returns a parsed UserProfile when present', () async {
      await seed('a', _userDoc(name: 'Alice', city: 'NYC', age: 28));

      final loaded = await repo.getUser('a');
      expect(loaded, isNotNull);
      expect(loaded!.uid, 'a');
      expect(loaded.name, 'Alice');
      expect(loaded.city, 'NYC');
      expect(loaded.age, 28);
    });

    test('watchUser emits null when the doc does not exist', () async {
      final first = await repo.watchUser('ghost').first;
      expect(first, isNull);
    });

    test('watchUser emits the latest doc snapshot', () async {
      await seed('a', _userDoc(name: 'Alice'));

      final loaded = await repo.watchUser('a').first;
      expect(loaded, isNotNull);
      expect(loaded!.uid, 'a');
      expect(loaded.name, 'Alice');
      expect(loaded.bio, 'Hi.');
    });

    test('watchUser re-emits when the doc updates', () async {
      await seed('a', _userDoc(name: 'Alice'));

      final emissions = <String?>[];
      final sub = repo.watchUser('a').listen((p) => emissions.add(p?.bio));

      await Future<void>.delayed(Duration.zero);
      await firestore
          .collection('users')
          .doc('a')
          .set({'bio': 'New bio.'}, SetOptions(merge: true));
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(emissions, contains('Hi.'));
      expect(emissions.last, 'New bio.');
    });
  });
}
