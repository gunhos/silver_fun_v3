import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silver_fun/features/meetups/repository/meetups_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late MeetupsRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = MeetupsRepository(firestore);
  });

  group('createMeetup', () {
    test('writes the meetup with default empty signedUpUids and canceled=false',
        () async {
      final start = DateTime.utc(2026, 6, 15, 18, 0);

      final id = await repo.createMeetup(
        organizerUid: 'org-1',
        title: 'Saturday coffee',
        description: 'Casual chat',
        startsAt: start,
        location: 'Blue Bottle',
        maxAttendees: 8,
      );

      final doc = await firestore.collection('meetups').doc(id).get();
      final data = doc.data()!;
      expect(data['organizerUid'], 'org-1');
      expect(data['title'], 'Saturday coffee');
      expect(data['description'], 'Casual chat');
      expect(
        (data['startsAt'] as Timestamp).toDate().isAtSameMomentAs(start),
        isTrue,
      );
      expect(data['location'], 'Blue Bottle');
      expect(data['maxAttendees'], 8);
      expect(data['signedUpUids'], isEmpty);
      expect(data['canceled'], false);
      expect(data['createdAt'], isA<Timestamp>());
    });

    test('omits maxAttendees when not provided', () async {
      final id = await repo.createMeetup(
        organizerUid: 'org-1',
        title: 'Walk',
        description: '',
        startsAt: DateTime.utc(2026, 7, 1, 9, 0),
        location: 'Park',
      );
      final data =
          (await firestore.collection('meetups').doc(id).get()).data()!;
      expect(data['maxAttendees'], isNull);
    });
  });

  group('watchUpcoming', () {
    test('emits future, non-canceled meetups ordered by startsAt', () async {
      final now = DateTime.utc(2026, 5, 1, 12, 0);
      // Past meetup — excluded.
      await firestore.collection('meetups').add({
        'organizerUid': 'a',
        'title': 'Yesterday',
        'description': '',
        'startsAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'location': 'x',
        'signedUpUids': <String>[],
        'canceled': false,
        'createdAt': Timestamp.fromDate(now),
      });
      // Canceled future meetup — excluded.
      await firestore.collection('meetups').add({
        'organizerUid': 'a',
        'title': 'Canceled',
        'description': '',
        'startsAt': Timestamp.fromDate(now.add(const Duration(days: 2))),
        'location': 'x',
        'signedUpUids': <String>[],
        'canceled': true,
        'createdAt': Timestamp.fromDate(now),
      });
      // Future, active — included.
      await firestore.collection('meetups').add({
        'organizerUid': 'a',
        'title': 'Later',
        'description': '',
        'startsAt': Timestamp.fromDate(now.add(const Duration(days: 5))),
        'location': 'x',
        'signedUpUids': <String>[],
        'canceled': false,
        'createdAt': Timestamp.fromDate(now),
      });
      await firestore.collection('meetups').add({
        'organizerUid': 'a',
        'title': 'Sooner',
        'description': '',
        'startsAt': Timestamp.fromDate(now.add(const Duration(days: 1))),
        'location': 'x',
        'signedUpUids': <String>[],
        'canceled': false,
        'createdAt': Timestamp.fromDate(now),
      });

      final list = await repo.watchUpcoming(now: now).first;

      expect(list.map((m) => m.title), equals(['Sooner', 'Later']));
    });

    test('emits an empty list when there are no future meetups', () async {
      final list =
          await repo.watchUpcoming(now: DateTime.utc(2026, 5, 1)).first;
      expect(list, isEmpty);
    });
  });

  group('watchMeetup', () {
    test('emits null when the doc does not exist', () async {
      final result = await repo.watchMeetup('missing').first;
      expect(result, isNull);
    });

    test('emits the meetup when the doc exists', () async {
      await firestore.collection('meetups').doc('m1').set({
        'organizerUid': 'org-1',
        'title': 'Coffee',
        'description': '',
        'startsAt': Timestamp.fromDate(DateTime.utc(2026, 7, 1, 10, 0)),
        'location': 'Cafe',
        'signedUpUids': <String>[],
        'canceled': false,
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 4, 30)),
      });

      final result = await repo.watchMeetup('m1').first;
      expect(result, isNotNull);
      expect(result!.title, 'Coffee');
    });
  });

  group('join', () {
    test('adds the uid to signedUpUids', () async {
      await firestore.collection('meetups').doc('m1').set({
        'organizerUid': 'org-1',
        'title': 't',
        'description': '',
        'startsAt': Timestamp.fromDate(DateTime.utc(2026, 7, 1)),
        'location': 'x',
        'signedUpUids': <String>[],
        'canceled': false,
      });

      await repo.join(meetupId: 'm1', uid: 'u1');

      final data =
          (await firestore.collection('meetups').doc('m1').get()).data()!;
      expect(data['signedUpUids'], ['u1']);
    });

    test('is idempotent — joining twice keeps a single entry', () async {
      await firestore.collection('meetups').doc('m1').set({
        'organizerUid': 'org-1',
        'title': 't',
        'description': '',
        'startsAt': Timestamp.fromDate(DateTime.utc(2026, 7, 1)),
        'location': 'x',
        'signedUpUids': <String>[],
        'canceled': false,
      });

      await repo.join(meetupId: 'm1', uid: 'u1');
      await repo.join(meetupId: 'm1', uid: 'u1');

      final data =
          (await firestore.collection('meetups').doc('m1').get()).data()!;
      expect(data['signedUpUids'], ['u1']);
    });
  });

  group('leave', () {
    test('removes the uid from signedUpUids', () async {
      await firestore.collection('meetups').doc('m1').set({
        'organizerUid': 'org-1',
        'title': 't',
        'description': '',
        'startsAt': Timestamp.fromDate(DateTime.utc(2026, 7, 1)),
        'location': 'x',
        'signedUpUids': <String>['u1', 'u2'],
        'canceled': false,
      });

      await repo.leave(meetupId: 'm1', uid: 'u1');

      final data =
          (await firestore.collection('meetups').doc('m1').get()).data()!;
      expect(data['signedUpUids'], ['u2']);
    });

    test('is idempotent — leaving when not joined is a no-op', () async {
      await firestore.collection('meetups').doc('m1').set({
        'organizerUid': 'org-1',
        'title': 't',
        'description': '',
        'startsAt': Timestamp.fromDate(DateTime.utc(2026, 7, 1)),
        'location': 'x',
        'signedUpUids': <String>['u2'],
        'canceled': false,
      });

      await repo.leave(meetupId: 'm1', uid: 'u1');

      final data =
          (await firestore.collection('meetups').doc('m1').get()).data()!;
      expect(data['signedUpUids'], ['u2']);
    });
  });

  group('cancel', () {
    test('sets canceled=true on the meetup doc', () async {
      await firestore.collection('meetups').doc('m1').set({
        'organizerUid': 'org-1',
        'title': 't',
        'description': '',
        'startsAt': Timestamp.fromDate(DateTime.utc(2026, 7, 1)),
        'location': 'x',
        'signedUpUids': <String>[],
        'canceled': false,
      });

      await repo.cancel('m1');

      final data =
          (await firestore.collection('meetups').doc('m1').get()).data()!;
      expect(data['canceled'], true);
    });

    test('a canceled meetup is excluded from watchUpcoming', () async {
      final now = DateTime.utc(2026, 5, 1, 12, 0);
      final id = await repo.createMeetup(
        organizerUid: 'org-1',
        title: 'Will be canceled',
        description: '',
        startsAt: now.add(const Duration(days: 1)),
        location: 'x',
      );

      // Sanity: shows up before cancel.
      var list = await repo.watchUpcoming(now: now).first;
      expect(list.map((m) => m.title), contains('Will be canceled'));

      await repo.cancel(id);

      list = await repo.watchUpcoming(now: now).first;
      expect(list.map((m) => m.title), isNot(contains('Will be canceled')));
    });
  });
}
