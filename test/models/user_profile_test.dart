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

    test('toMap then fromFirestore round-trips', () async {
      const original = UserProfile(
        uid: 'u4',
        name: 'Jordan',
        age: 28,
        bio: 'Hi.',
        photoUrl: 'https://example.com/j.jpg',
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
