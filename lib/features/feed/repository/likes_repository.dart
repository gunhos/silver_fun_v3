import 'package:cloud_firestore/cloud_firestore.dart';

class LikesRepository {
  final FirebaseFirestore _db;

  LikesRepository(this._db);

  DocumentReference<Map<String, dynamic>> _forwardDoc(
    String fromUid,
    String toUid,
  ) {
    return _db
        .collection('likes')
        .doc(fromUid)
        .collection('liked')
        .doc(toUid);
  }

  DocumentReference<Map<String, dynamic>> _reverseDoc(
    String fromUid,
    String toUid,
  ) {
    return _db
        .collection('likedBy')
        .doc(toUid)
        .collection('from')
        .doc(fromUid);
  }

  Future<void> like(String fromUid, String toUid) async {
    final batch = _db.batch();
    final timestamp = FieldValue.serverTimestamp();
    batch.set(_forwardDoc(fromUid, toUid), {'likedAt': timestamp});
    batch.set(_reverseDoc(fromUid, toUid), {'likedAt': timestamp});
    await batch.commit();
  }

  Future<void> unlike(String fromUid, String toUid) async {
    final batch = _db.batch();
    batch.delete(_forwardDoc(fromUid, toUid));
    batch.delete(_reverseDoc(fromUid, toUid));
    await batch.commit();
  }

  Future<bool> isMutual({
    required String fromUid,
    required String toUid,
  }) async {
    final doc = await _forwardDoc(toUid, fromUid).get();
    return doc.exists;
  }

  Stream<Set<String>> watchLikedByMe(String uid) {
    return _db
        .collection('likes')
        .doc(uid)
        .collection('liked')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  Stream<Set<String>> watchLikedByOthers(String uid) {
    return _db
        .collection('likedBy')
        .doc(uid)
        .collection('from')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }
}
