import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silver_fun/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('fromFirestore parses a fully populated document', () async {
      final created = DateTime.utc(2026, 1, 15, 12);
      final updated = DateTime.utc(2026, 4, 1, 9);
      await firestore.collection('users').doc('u1').set({
        'name': 'Maya',
        'age': 31,
        'bio': 'Coffee, books, walks.',
        'photoUrl': 'https://example.com/maya.jpg',
        'interests': ['Coffee', 'Reading', 'Hiking'],
        'city': 'Brooklyn',
        'published': true,
        'profilePaused': false,
        'createdAt': Timestamp.fromDate(created),
        'updatedAt': Timestamp.fromDate(updated),
      });

      final doc = await firestore.collection('users').doc('u1').get();
      final profile = UserProfile.fromFirestore(doc);

      expect(profile.uid, 'u1');
      expect(profile.name, 'Maya');
      expect(profile.age, 31);
      expect(profile.bio, 'Coffee, books, walks.');
      expect(profile.photoUrl, 'https://example.com/maya.jpg');
      expect(profile.photoUrls, ['https://example.com/maya.jpg']);
      expect(profile.interests, ['Coffee', 'Reading', 'Hiking']);
      expect(profile.city, 'Brooklyn');
      expect(profile.published, true);
      expect(profile.profilePaused, false);
      expect(profile.createdAt!.isAtSameMomentAs(created), isTrue);
      expect(profile.updatedAt!.isAtSameMomentAs(updated), isTrue);
      expect(profile.liked, false);
    });

    test('fromFirestore applies safe defaults for missing fields', () async {
      await firestore.collection('users').doc('u2').set(<String, dynamic>{});

      final doc = await firestore.collection('users').doc('u2').get();
      final profile = UserProfile.fromFirestore(doc);

      expect(profile.uid, 'u2');
      expect(profile.name, '');
      expect(profile.age, 0);
      expect(profile.bio, '');
      expect(profile.photoUrl, '');
      expect(profile.photoUrls, isEmpty);
      expect(profile.interests, isEmpty);
      expect(profile.city, '');
      expect(profile.published, false);
      expect(profile.profilePaused, false);
      expect(profile.createdAt, isNull);
      expect(profile.updatedAt, isNull);
    });

    test('fromFirestore filters non-string interests', () async {
      await firestore.collection('users').doc('u3').set({
        'interests': ['Coffee', 42, null, 'Hiking'],
      });

      final doc = await firestore.collection('users').doc('u3').get();
      final profile = UserProfile.fromFirestore(doc);

      expect(profile.interests, ['Coffee', 'Hiking']);
    });

    test('fromFirestore parses photoUrls when present', () async {
      await firestore.collection('users').doc('p1').set({
        'photoUrl': 'https://x/main.jpg',
        'photoUrls': [
          'https://x/main.jpg',
          'https://x/2.jpg',
          'https://x/3.jpg',
        ],
      });

      final doc = await firestore.collection('users').doc('p1').get();
      final profile = UserProfile.fromFirestore(doc);

      expect(profile.photoUrl, 'https://x/main.jpg');
      expect(profile.photoUrls, [
        'https://x/main.jpg',
        'https://x/2.jpg',
        'https://x/3.jpg',
      ]);
    });

    test('fromFirestore synthesizes photoUrls from legacy photoUrl',
        () async {
      await firestore.collection('users').doc('p2').set({
        'photoUrl': 'https://x/legacy.jpg',
      });

      final doc = await firestore.collection('users').doc('p2').get();
      final profile = UserProfile.fromFirestore(doc);

      expect(profile.photoUrl, 'https://x/legacy.jpg');
      expect(profile.photoUrls, ['https://x/legacy.jpg']);
    });

    test('fromFirestore returns empty photoUrls when both fields are missing',
        () async {
      await firestore.collection('users').doc('p3').set(<String, dynamic>{});

      final doc = await firestore.collection('users').doc('p3').get();
      final profile = UserProfile.fromFirestore(doc);

      expect(profile.photoUrl, '');
      expect(profile.photoUrls, isEmpty);
    });

    test(
        'fromFirestore filters non-string and empty entries from photoUrls',
        () async {
      await firestore.collection('users').doc('p4').set({
        'photoUrl': 'https://x/main.jpg',
        'photoUrls': ['https://x/main.jpg', '', 42, null, 'https://x/2.jpg'],
      });

      final doc = await firestore.collection('users').doc('p4').get();
      final profile = UserProfile.fromFirestore(doc);

      expect(profile.photoUrls, ['https://x/main.jpg', 'https://x/2.jpg']);
    });

    test(
        'fromFirestore promotes photoUrls[0] to photoUrl when photoUrl is empty',
        () async {
      await firestore.collection('users').doc('p5').set({
        'photoUrl': '',
        'photoUrls': ['https://x/2.jpg', 'https://x/3.jpg'],
      });

      final doc = await firestore.collection('users').doc('p5').get();
      final profile = UserProfile.fromFirestore(doc);

      expect(profile.photoUrl, 'https://x/2.jpg');
      expect(profile.photoUrls, ['https://x/2.jpg', 'https://x/3.jpg']);
    });

    test('toMap writes both photoUrl and photoUrls', () {
      const profile = UserProfile(
        uid: 'p6',
        name: 'M',
        age: 30,
        bio: 'b',
        photoUrl: 'https://x/main.jpg',
        photoUrls: ['https://x/main.jpg', 'https://x/2.jpg'],
        interests: ['Coffee'],
        city: 'NYC',
        published: true,
        profilePaused: false,
      );

      final map = profile.toMap();

      expect(map['photoUrl'], 'https://x/main.jpg');
      expect(map['photoUrls'], ['https://x/main.jpg', 'https://x/2.jpg']);
    });

    test('copyWith overrides photoUrls', () {
      const a = UserProfile(
        uid: 'p7',
        name: 'A',
        age: 30,
        bio: 'b',
        photoUrl: 'https://x/main.jpg',
        photoUrls: ['https://x/main.jpg'],
        interests: ['Coffee'],
        city: 'NYC',
        published: true,
        profilePaused: false,
      );

      final b =
          a.copyWith(photoUrls: ['https://x/main.jpg', 'https://x/2.jpg']);

      expect(b.photoUrls, ['https://x/main.jpg', 'https://x/2.jpg']);
      expect(b.photoUrl, 'https://x/main.jpg');
    });

    test('toMap then fromFirestore round-trips', () async {
      const original = UserProfile(
        uid: 'u4',
        name: 'Jordan',
        age: 28,
        bio: 'Hi.',
        photoUrl: 'https://example.com/j.jpg',
        photoUrls: ['https://example.com/j.jpg'],
        interests: ['Coffee', 'Yoga'],
        city: 'Oakland',
        published: true,
        profilePaused: false,
      );

      await firestore.collection('users').doc('u4').set(original.toMap());

      final doc = await firestore.collection('users').doc('u4').get();
      final round = UserProfile.fromFirestore(doc);

      expect(round.uid, original.uid);
      expect(round.name, original.name);
      expect(round.age, original.age);
      expect(round.bio, original.bio);
      expect(round.photoUrl, original.photoUrl);
      expect(round.interests, original.interests);
      expect(round.city, original.city);
      expect(round.published, original.published);
      expect(round.profilePaused, original.profilePaused);
    });

    test('copyWith overrides only provided fields', () {
      const a = UserProfile(
        uid: 'u5',
        name: 'A',
        age: 30,
        bio: 'b',
        photoUrl: 'p',
        interests: ['Coffee'],
        city: 'NYC',
        published: false,
        profilePaused: false,
      );

      final b = a.copyWith(published: true, liked: true);

      expect(b.uid, 'u5');
      expect(b.name, 'A');
      expect(b.published, true);
      expect(b.liked, true);
      expect(b.profilePaused, false);
    });
  });
}
