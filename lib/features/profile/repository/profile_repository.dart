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

  /// Append [url] to `photoUrls`. If no main photo is set yet, also set
  /// `photoUrl` to [url] so the gallery and the main photo stay in sync.
  Future<void> addPhoto({required String uid, required String url}) async {
    final doc = _users.doc(uid);
    final snap = await doc.get();
    final data = snap.data() ?? const <String, dynamic>{};
    final existing = ((data['photoUrls'] as List?) ?? const [])
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    final mainUrl = (data['photoUrl'] as String?) ?? '';
    final next = [...existing, url];
    final updates = <String, dynamic>{
      'photoUrls': next,
    };
    if (mainUrl.isEmpty) {
      updates['photoUrl'] = url;
    }
    await doc.set(updates, SetOptions(merge: true));
  }

  /// Remove [url] from `photoUrls`. If [url] is the current main photo,
  /// promote the next-remaining url to main, or clear `photoUrl` if the
  /// gallery becomes empty.
  Future<void> removePhoto({required String uid, required String url}) async {
    final doc = _users.doc(uid);
    final snap = await doc.get();
    final data = snap.data() ?? const <String, dynamic>{};
    final existing = ((data['photoUrls'] as List?) ?? const [])
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    final mainUrl = (data['photoUrl'] as String?) ?? '';
    final next = existing.where((u) => u != url).toList();
    final updates = <String, dynamic>{
      'photoUrls': next,
    };
    if (mainUrl == url) {
      updates['photoUrl'] = next.isEmpty ? '' : next.first;
    }
    await doc.set(updates, SetOptions(merge: true));
  }

  /// Move [url] to position 0 of `photoUrls` and update `photoUrl` to match.
  /// No-op when [url] is not in the current gallery.
  Future<void> setMainPhoto({required String uid, required String url}) async {
    final doc = _users.doc(uid);
    final snap = await doc.get();
    final data = snap.data() ?? const <String, dynamic>{};
    final existing = ((data['photoUrls'] as List?) ?? const [])
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    if (!existing.contains(url)) return;
    final reordered = [url, ...existing.where((u) => u != url)];
    await doc.set({
      'photoUrl': url,
      'photoUrls': reordered,
    }, SetOptions(merge: true));
  }
}
