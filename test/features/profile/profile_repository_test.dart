import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silver_fun/features/profile/repository/profile_repository.dart';
import 'package:silver_fun/models/user_profile.dart';

UserProfile _profile({
  String uid = 'u1',
  String name = 'Maya',
  bool published = false,
  bool paused = false,
}) {
  return UserProfile(
    uid: uid,
    name: name,
    age: 30,
    bio: 'Hello.',
    photoUrl: '',
    interests: const ['Coffee', 'Reading', 'Hiking'],
    city: 'Brooklyn',
    published: published,
    profilePaused: paused,
  );
}

void main() {
  group('ProfileRepository', () {
    late FakeFirebaseFirestore firestore;
    late ProfileRepository repo;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repo = ProfileRepository(firestore);
    });

    test('getProfile returns null when the doc does not exist', () async {
      final result = await repo.getProfile('missing');
      expect(result, isNull);
    });

    test('saveProfile writes via merge and getProfile reads it back',
        () async {
      await repo.saveProfile(_profile(uid: 'u1', name: 'Maya'));

      final loaded = await repo.getProfile('u1');
      expect(loaded, isNotNull);
      expect(loaded!.name, 'Maya');
      expect(loaded.published, false);
      expect(loaded.interests, containsAll(['Coffee', 'Reading', 'Hiking']));
    });

    test('saveProfile merges instead of overwriting existing fields',
        () async {
      await firestore.collection('users').doc('u1').set({
        'name': 'Maya',
        'age': 30,
        'city': 'Brooklyn',
        'bio': 'Original bio',
        'photoUrl': 'https://x/y.jpg',
        'interests': ['Coffee'],
        'published': true,
        'profilePaused': false,
      });

      await repo.updateField('u1', 'bio', 'Updated bio');

      final doc = await firestore.collection('users').doc('u1').get();
      final data = doc.data()!;
      expect(data['bio'], 'Updated bio');
      expect(data['name'], 'Maya');
      expect(data['photoUrl'], 'https://x/y.jpg');
      expect(data['published'], true);
    });

    test('watchProfile emits null then the doc when it appears', () async {
      final emitted = <UserProfile?>[];
      final sub = repo.watchProfile('u1').listen(emitted.add);

      await Future<void>.delayed(Duration.zero);
      expect(emitted.last, isNull);

      await firestore.collection('users').doc('u1').set({
        'name': 'Maya',
        'age': 30,
        'bio': 'Hi',
        'photoUrl': '',
        'interests': <String>[],
        'city': '',
        'published': false,
        'profilePaused': false,
        'createdAt': Timestamp.now(),
      });

      await Future<void>.delayed(Duration.zero);

      expect(emitted.last, isNotNull);
      expect(emitted.last!.name, 'Maya');

      await sub.cancel();
    });

    test('updateField sets only the requested field on a non-existent doc',
        () async {
      await repo.updateField('u2', 'profilePaused', true);

      final doc = await firestore.collection('users').doc('u2').get();
      expect(doc.exists, true);
      expect(doc.data()!['profilePaused'], true);
    });

    test(
        'addPhoto appends to photoUrls and sets photoUrl when no main exists',
        () async {
      await firestore.collection('users').doc('u1').set({
        'name': 'Maya',
        'photoUrl': '',
      });

      await repo.addPhoto(uid: 'u1', url: 'https://x/1.jpg');

      final data = (await firestore.collection('users').doc('u1').get()).data()!;
      expect(data['photoUrl'], 'https://x/1.jpg');
      expect(data['photoUrls'], ['https://x/1.jpg']);
    });

    test('addPhoto does not change photoUrl when a main is already set',
        () async {
      await firestore.collection('users').doc('u1').set({
        'photoUrl': 'https://x/main.jpg',
        'photoUrls': ['https://x/main.jpg'],
      });

      await repo.addPhoto(uid: 'u1', url: 'https://x/2.jpg');

      final data = (await firestore.collection('users').doc('u1').get()).data()!;
      expect(data['photoUrl'], 'https://x/main.jpg');
      expect(data['photoUrls'], ['https://x/main.jpg', 'https://x/2.jpg']);
    });

    test('removePhoto removes a non-main url from photoUrls', () async {
      await firestore.collection('users').doc('u1').set({
        'photoUrl': 'https://x/main.jpg',
        'photoUrls': ['https://x/main.jpg', 'https://x/2.jpg'],
      });

      await repo.removePhoto(uid: 'u1', url: 'https://x/2.jpg');

      final data = (await firestore.collection('users').doc('u1').get()).data()!;
      expect(data['photoUrl'], 'https://x/main.jpg');
      expect(data['photoUrls'], ['https://x/main.jpg']);
    });

    test('removePhoto of the main photo promotes the next photo', () async {
      await firestore.collection('users').doc('u1').set({
        'photoUrl': 'https://x/main.jpg',
        'photoUrls': ['https://x/main.jpg', 'https://x/2.jpg'],
      });

      await repo.removePhoto(uid: 'u1', url: 'https://x/main.jpg');

      final data = (await firestore.collection('users').doc('u1').get()).data()!;
      expect(data['photoUrl'], 'https://x/2.jpg');
      expect(data['photoUrls'], ['https://x/2.jpg']);
    });

    test('removePhoto of the only photo clears photoUrl and photoUrls',
        () async {
      await firestore.collection('users').doc('u1').set({
        'photoUrl': 'https://x/main.jpg',
        'photoUrls': ['https://x/main.jpg'],
      });

      await repo.removePhoto(uid: 'u1', url: 'https://x/main.jpg');

      final data = (await firestore.collection('users').doc('u1').get()).data()!;
      expect(data['photoUrl'], '');
      expect(data['photoUrls'], isEmpty);
    });

    test('setMainPhoto reorders photoUrls and updates photoUrl', () async {
      await firestore.collection('users').doc('u1').set({
        'photoUrl': 'https://x/1.jpg',
        'photoUrls': ['https://x/1.jpg', 'https://x/2.jpg', 'https://x/3.jpg'],
      });

      await repo.setMainPhoto(uid: 'u1', url: 'https://x/3.jpg');

      final data = (await firestore.collection('users').doc('u1').get()).data()!;
      expect(data['photoUrl'], 'https://x/3.jpg');
      expect(data['photoUrls'],
          ['https://x/3.jpg', 'https://x/1.jpg', 'https://x/2.jpg']);
    });

    test('setMainPhoto is a no-op when the url is not in photoUrls',
        () async {
      await firestore.collection('users').doc('u1').set({
        'photoUrl': 'https://x/1.jpg',
        'photoUrls': ['https://x/1.jpg', 'https://x/2.jpg'],
      });

      await repo.setMainPhoto(uid: 'u1', url: 'https://x/unknown.jpg');

      final data = (await firestore.collection('users').doc('u1').get()).data()!;
      expect(data['photoUrl'], 'https://x/1.jpg');
      expect(data['photoUrls'], ['https://x/1.jpg', 'https://x/2.jpg']);
    });
  });
}
