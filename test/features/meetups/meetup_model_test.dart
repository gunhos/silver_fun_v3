import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silver_fun/features/meetups/models/meetup.dart';

void main() {
  group('Meetup.fromFirestore', () {
    late FakeFirebaseFirestore firestore;

    setUp(() => firestore = FakeFirebaseFirestore());

    test('reads all fields from a populated doc', () async {
      final start = DateTime.utc(2026, 6, 15, 18, 0);
      final created = DateTime.utc(2026, 4, 30, 12, 0);
      await firestore.collection('meetups').doc('m1').set({
        'organizerUid': 'org-1',
        'title': 'Saturday coffee',
        'description': 'Casual chat at the cafe.',
        'startsAt': Timestamp.fromDate(start),
        'location': 'Blue Bottle, 5th Ave',
        'maxAttendees': 8,
        'signedUpUids': ['u1', 'u2'],
        'canceled': false,
        'createdAt': Timestamp.fromDate(created),
      });

      final doc = await firestore.collection('meetups').doc('m1').get();
      final m = Meetup.fromFirestore(doc);

      expect(m.id, 'm1');
      expect(m.organizerUid, 'org-1');
      expect(m.title, 'Saturday coffee');
      expect(m.description, 'Casual chat at the cafe.');
      expect(m.startsAt.isAtSameMomentAs(start), isTrue);
      expect(m.location, 'Blue Bottle, 5th Ave');
      expect(m.maxAttendees, 8);
      expect(m.signedUpUids, ['u1', 'u2']);
      expect(m.canceled, false);
      expect(m.createdAt!.isAtSameMomentAs(created), isTrue);
    });

    test('defaults missing fields to safe values', () async {
      await firestore.collection('meetups').doc('m2').set(<String, dynamic>{});
      final doc = await firestore.collection('meetups').doc('m2').get();
      final m = Meetup.fromFirestore(doc);

      expect(m.id, 'm2');
      expect(m.organizerUid, '');
      expect(m.title, '');
      expect(m.description, '');
      expect(m.location, '');
      expect(m.maxAttendees, isNull);
      expect(m.signedUpUids, isEmpty);
      expect(m.canceled, false);
      expect(m.createdAt, isNull);
    });
  });

  group('Meetup helpers', () {
    Meetup base({
      String organizerUid = 'org-1',
      List<String> signedUpUids = const [],
      int? maxAttendees,
    }) {
      return Meetup(
        id: 'm1',
        organizerUid: organizerUid,
        title: 't',
        description: '',
        startsAt: DateTime.utc(2026, 6, 1),
        location: 'x',
        maxAttendees: maxAttendees,
        signedUpUids: signedUpUids,
      );
    }

    test('isOrganizer is true only for the organizer uid', () {
      final m = base(organizerUid: 'org-1');
      expect(m.isOrganizer('org-1'), isTrue);
      expect(m.isOrganizer('someone-else'), isFalse);
    });

    test('hasJoined reflects signedUpUids membership', () {
      final m = base(signedUpUids: ['a', 'b']);
      expect(m.hasJoined('a'), isTrue);
      expect(m.hasJoined('c'), isFalse);
    });

    test('attendeeCount is the length of signedUpUids', () {
      expect(base(signedUpUids: const []).attendeeCount, 0);
      expect(base(signedUpUids: const ['a', 'b', 'c']).attendeeCount, 3);
    });

    test('isFull is false when maxAttendees is null', () {
      final m = base(signedUpUids: const ['a', 'b'], maxAttendees: null);
      expect(m.isFull, isFalse);
    });

    test('isFull is true when signedUpUids reaches maxAttendees', () {
      final m = base(signedUpUids: const ['a', 'b'], maxAttendees: 2);
      expect(m.isFull, isTrue);
    });
  });
}
