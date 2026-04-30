import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/user_profile.dart';
import '../../auth/providers/auth_provider.dart';
import '../repository/profile_repository.dart';

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(firestoreProvider));
});

final myProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) {
    return Stream<UserProfile?>.value(null);
  }
  return ref.watch(profileRepositoryProvider).watchProfile(user.uid);
});

/// Picks a photo from [source] (`ImageSource.camera` or `ImageSource.gallery`)
/// and uploads it for [uid], returning the download URL. Returns `null` when
/// the user cancels the picker (so the caller can distinguish "user backed
/// out" from "upload failed"). Injected so widget tests can substitute a fake.
typedef ProfilePhotoUploader =
    Future<String?> Function(String uid, ImageSource source);

/// Best-effort deletes a photo at [url] from Storage. Failures are
/// swallowed inside the implementation. Injected so widget tests can
/// substitute a fake.
typedef ProfilePhotoDeleter = Future<void> Function(String url);

final profilePhotoUploaderProvider = Provider<ProfilePhotoUploader>((ref) {
  return _defaultProfilePhotoUploader;
});

final profilePhotoDeleterProvider = Provider<ProfilePhotoDeleter>((ref) {
  return _defaultProfilePhotoDeleter;
});

Future<String?> _defaultProfilePhotoUploader(
  String uid,
  ImageSource source,
) async {
  final picker = _picker ??= ImagePicker();
  final file = await picker.pickImage(source: source);
  if (file == null) return null;
  final raw = await file.readAsBytes();
  final Uint8List bytes = await FlutterImageCompress.compressWithList(
    raw,
    minWidth: 800,
    minHeight: 800,
    quality: 85,
    format: CompressFormat.jpeg,
  );
  final ms = DateTime.now().millisecondsSinceEpoch;
  final rand = Random.secure().nextInt(10000).toString().padLeft(4, '0');
  final ref =
      FirebaseStorage.instance.ref('profile-photos/$uid/${ms}_$rand.jpg');
  await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
  return ref.getDownloadURL();
}

Future<void> _defaultProfilePhotoDeleter(String url) async {
  try {
    await FirebaseStorage.instance.refFromURL(url).delete();
  } catch (_) {
    // Best-effort. The Firestore update is the source of truth.
  }
}

ImagePicker? _picker;
