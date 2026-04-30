import 'package:cloud_firestore/cloud_firestore.dart';

class Meetup {
  final String id;
  final String organizerUid;
  final String title;
  final String description;
  final DateTime startsAt;
  final String location;
  final int? maxAttendees;
  final List<String> signedUpUids;
  final bool canceled;
  final DateTime? createdAt;

  const Meetup({
    required this.id,
    required this.organizerUid,
    required this.title,
    required this.description,
    required this.startsAt,
    required this.location,
    this.maxAttendees,
    this.signedUpUids = const [],
    this.canceled = false,
    this.createdAt,
  });

  factory Meetup.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Meetup(
      id: doc.id,
      organizerUid: (data['organizerUid'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      startsAt: (data['startsAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      location: (data['location'] as String?) ?? '',
      maxAttendees: (data['maxAttendees'] as num?)?.toInt(),
      signedUpUids: ((data['signedUpUids'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      canceled: (data['canceled'] as bool?) ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  bool isOrganizer(String uid) => organizerUid == uid;
  bool hasJoined(String uid) => signedUpUids.contains(uid);
  int get attendeeCount => signedUpUids.length;
  bool get isFull =>
      maxAttendees != null && signedUpUids.length >= maxAttendees!;
}
