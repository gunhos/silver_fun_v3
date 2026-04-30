import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/meetup.dart';

class MeetupsRepository {
  final FirebaseFirestore _db;

  MeetupsRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _meetups =>
      _db.collection('meetups');

  Future<String> createMeetup({
    required String organizerUid,
    required String title,
    required String description,
    required DateTime startsAt,
    required String location,
    int? maxAttendees,
  }) async {
    final ref = await _meetups.add({
      'organizerUid': organizerUid,
      'title': title,
      'description': description,
      'startsAt': Timestamp.fromDate(startsAt),
      'location': location,
      'maxAttendees': ?maxAttendees,
      'signedUpUids': const <String>[],
      'canceled': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<List<Meetup>> watchUpcoming({DateTime? now}) {
    final cutoff = Timestamp.fromDate(now ?? DateTime.now());
    return _meetups
        .where('canceled', isEqualTo: false)
        .where('startsAt', isGreaterThan: cutoff)
        .orderBy('startsAt')
        .snapshots()
        .map((snap) => snap.docs.map(Meetup.fromFirestore).toList());
  }

  Stream<Meetup?> watchMeetup(String id) {
    return _meetups.doc(id).snapshots().map(
          (doc) => doc.exists ? Meetup.fromFirestore(doc) : null,
        );
  }

  Future<void> join({required String meetupId, required String uid}) async {
    await _meetups.doc(meetupId).update({
      'signedUpUids': FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> leave({required String meetupId, required String uid}) async {
    await _meetups.doc(meetupId).update({
      'signedUpUids': FieldValue.arrayRemove([uid]),
    });
  }

  Future<void> cancel(String meetupId) async {
    await _meetups.doc(meetupId).update({'canceled': true});
  }
}
