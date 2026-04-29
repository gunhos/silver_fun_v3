import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/user_profile.dart';

class FeedRepository {
  final FirebaseFirestore _db;

  FeedRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Stream<List<UserProfile>> watchFeed(String currentUid) {
    return _users
        .where('published', isEqualTo: true)
        .where('profilePaused', isEqualTo: false)
        .snapshots()
        .map((snap) {
      return snap.docs
          .where((doc) => doc.id != currentUid)
          .map(UserProfile.fromFirestore)
          .toList();
    });
  }

  Future<UserProfile?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }
}
