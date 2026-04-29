import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/providers/my_profile_provider.dart';
import '../notifiers/onboarding_form_notifier.dart';

typedef PhotoUploader = Future<String> Function(String uid, XFile file);

class OnboardingRepository {
  final FirebaseFirestore _db;
  final PhotoUploader _uploadPhotoFn;

  OnboardingRepository(
    this._db, {
    PhotoUploader? photoUploader,
  }) : _uploadPhotoFn = photoUploader ?? _defaultUploader;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Future<void> saveNameAge({
    required String uid,
    required String name,
    required int age,
  }) {
    return _users.doc(uid).set({
      'name': name.trim(),
      'age': age,
    }, SetOptions(merge: true));
  }

  Future<void> saveBio({required String uid, required String bio}) {
    return _users.doc(uid).set({
      'bio': bio.trim(),
    }, SetOptions(merge: true));
  }

  Future<void> saveInterests({
    required String uid,
    required List<String> interests,
  }) {
    return _users.doc(uid).set({
      'interests': interests,
    }, SetOptions(merge: true));
  }

  Future<void> savePhotoUrl({
    required String uid,
    required String url,
  }) {
    return _users.doc(uid).set({
      'photoUrl': url,
    }, SetOptions(merge: true));
  }

  Future<String> uploadPhoto({
    required String uid,
    required XFile file,
  }) {
    return _uploadPhotoFn(uid, file);
  }

  Future<void> publishProfile({
    required String uid,
    required OnboardingFormState form,
  }) {
    return _users.doc(uid).set({
      'name': form.name.trim(),
      'age': form.age,
      'bio': form.bio.trim(),
      'photoUrl': form.photoUrl,
      'interests': form.interests,
      'published': true,
      'profilePaused': false,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

Future<String> _defaultUploader(String uid, XFile file) async {
  final raw = await file.readAsBytes();
  final Uint8List bytes = await FlutterImageCompress.compressWithList(
    raw,
    minWidth: 800,
    minHeight: 800,
    quality: 85,
    format: CompressFormat.jpeg,
  );
  final ref = FirebaseStorage.instance.ref('profile-photos/$uid.jpg');
  await ref.putData(
    bytes,
    SettableMetadata(contentType: 'image/jpeg'),
  );
  return ref.getDownloadURL();
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(ref.watch(firestoreProvider));
});
