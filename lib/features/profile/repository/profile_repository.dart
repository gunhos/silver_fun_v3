import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/user_profile.dart';

class ProfileRepository {
  final FirebaseFirestore _db;

  ProfileRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  Stream<UserProfile?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map(
      (doc) => doc.exists ? UserProfile.fromFirestore(doc) : null,
    );
  }

  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _users.doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
  }

  Future<void> updateField(String uid, String field, Object? value) async {
    await _users.doc(uid).set({field: value}, SetOptions(merge: true));
  }
}
