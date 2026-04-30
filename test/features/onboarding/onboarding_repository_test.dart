import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:silver_fun/features/onboarding/notifiers/onboarding_form_notifier.dart';
import 'package:silver_fun/features/onboarding/repository/onboarding_repository.dart';

void main() {
  group('OnboardingRepository', () {
    late FakeFirebaseFirestore firestore;
    late OnboardingRepository repo;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repo = OnboardingRepository(
        firestore,
        photoUploader: (uid, file) async => 'https://stub/$uid.jpg',
      );
    });

    Future<Map<String, dynamic>> readUser(String uid) async {
      final doc = await firestore.collection('users').doc(uid).get();
      return doc.data() ?? const <String, dynamic>{};
    }

    test('saveNameAge writes name and age via merge', () async {
      await firestore.collection('users').doc('u1').set({
        'bio': 'Existing bio',
      });

      await repo.saveNameAge(uid: 'u1', name: '  Maya  ', age: 31);

      final data = await readUser('u1');
      expect(data['name'], 'Maya');
      expect(data['age'], 31);
      expect(data['bio'], 'Existing bio'); // preserved
    });

    test('saveBio writes trimmed bio and preserves other fields', () async {
      await firestore.collection('users').doc('u1').set({
        'name': 'Maya',
        'age': 31,
      });

      await repo.saveBio(uid: 'u1', bio: '  Coffee, books, walks.  ');

      final data = await readUser('u1');
      expect(data['bio'], 'Coffee, books, walks.');
      expect(data['name'], 'Maya');
      expect(data['age'], 31);
    });

    test('saveInterests writes the list and preserves other fields',
        () async {
      await firestore.collection('users').doc('u1').set({'name': 'Maya'});

      await repo.saveInterests(
        uid: 'u1',
        interests: const ['Coffee', 'Reading', 'Hiking'],
      );

      final data = await readUser('u1');
      expect(data['interests'], ['Coffee', 'Reading', 'Hiking']);
      expect(data['name'], 'Maya');
    });

    test('savePhotoUrl writes both photoUrl and photoUrls', () async {
      await firestore.collection('users').doc('u1').set({'name': 'Maya'});

      await repo.savePhotoUrl(
        uid: 'u1',
        url: 'https://example.com/u1.jpg',
      );

      final data = await readUser('u1');
      expect(data['photoUrl'], 'https://example.com/u1.jpg');
      expect(data['photoUrls'], ['https://example.com/u1.jpg']);
      expect(data['name'], 'Maya');
    });

    test('uploadPhoto delegates to the injected uploader', () async {
      final url = await repo.uploadPhoto(
        uid: 'u1',
        file: XFile('dummy/path.jpg'),
      );
      expect(url, 'https://stub/u1.jpg');
    });

    test('publishProfile writes all fields plus published and createdAt',
        () async {
      const form = OnboardingFormState(
        name: 'Maya',
        age: 31,
        bio: 'Coffee, books, walks.',
        photoUrl: 'https://example.com/u1.jpg',
        interests: ['Coffee', 'Reading', 'Hiking'],
      );

      await repo.publishProfile(uid: 'u1', form: form);

      final data = await readUser('u1');
      expect(data['name'], 'Maya');
      expect(data['age'], 31);
      expect(data['bio'], 'Coffee, books, walks.');
      expect(data['photoUrl'], 'https://example.com/u1.jpg');
      expect(data['photoUrls'], ['https://example.com/u1.jpg']);
      expect(data['interests'], ['Coffee', 'Reading', 'Hiking']);
      expect(data['published'], true);
      expect(data['profilePaused'], false);
      expect(data['createdAt'], isA<Timestamp>());
    });

    test('publishProfile does not clobber existing fields outside the form',
        () async {
      await firestore.collection('users').doc('u1').set({
        'city': 'Brooklyn',
      });

      const form = OnboardingFormState(
        name: 'Maya',
        age: 31,
        bio: 'Coffee, books, walks.',
        photoUrl: 'https://example.com/u1.jpg',
        interests: ['Coffee', 'Reading', 'Hiking'],
      );

      await repo.publishProfile(uid: 'u1', form: form);

      final data = await readUser('u1');
      expect(data['city'], 'Brooklyn');
      expect(data['published'], true);
    });
  });

  group('OnboardingFormState', () {
    test('isNameAgeValid requires name >= 2 and age in [18, 120)', () {
      expect(const OnboardingFormState(name: 'M', age: 30).isNameAgeValid,
          isFalse);
      expect(const OnboardingFormState(name: 'Maya').isNameAgeValid, isFalse);
      expect(const OnboardingFormState(name: 'Maya', age: 17).isNameAgeValid,
          isFalse);
      expect(const OnboardingFormState(name: 'Maya', age: 18).isNameAgeValid,
          isTrue);
      expect(const OnboardingFormState(name: 'Maya', age: 120).isNameAgeValid,
          isFalse);
    });

    test('isBioValid requires 10..180 chars', () {
      expect(const OnboardingFormState(bio: 'too short').isBioValid, isFalse);
      expect(const OnboardingFormState(bio: 'just enough').isBioValid, isTrue);
      expect(
        OnboardingFormState(bio: 'x' * 181).isBioValid,
        isFalse,
      );
    });

    test('isInterestsValid requires 3..6 items', () {
      expect(const OnboardingFormState(interests: ['a', 'b']).isInterestsValid,
          isFalse);
      expect(
        const OnboardingFormState(interests: ['a', 'b', 'c']).isInterestsValid,
        isTrue,
      );
      expect(
        const OnboardingFormState(
                interests: ['a', 'b', 'c', 'd', 'e', 'f', 'g'])
            .isInterestsValid,
        isFalse,
      );
    });

    test('copyWith can clear age via explicit null', () {
      const a = OnboardingFormState(name: 'Maya', age: 30);
      final b = a.copyWith(age: null);
      expect(b.name, 'Maya');
      expect(b.age, isNull);
    });

    test('copyWith without age leaves it unchanged', () {
      const a = OnboardingFormState(name: 'Maya', age: 30);
      final b = a.copyWith(name: 'May');
      expect(b.age, 30);
    });
  });
}
