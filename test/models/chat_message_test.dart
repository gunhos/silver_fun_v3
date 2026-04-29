import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silver_fun/models/chat_message.dart';

void main() {
  group('ChatMessage', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('fromFirestore parses a fully populated document', () async {
      final sentAt = DateTime.utc(2026, 4, 28, 10, 30);
      await firestore
          .collection('chats')
          .doc('c1')
          .collection('messages')
          .doc('m1')
          .set({
        'senderId': 'u1',
        'text': 'hey',
        'sentAt': Timestamp.fromDate(sentAt),
        'read': true,
      });

      final doc = await firestore
          .collection('chats')
          .doc('c1')
          .collection('messages')
          .doc('m1')
          .get();
      final msg = ChatMessage.fromFirestore(doc);

      expect(msg.id, 'm1');
      expect(msg.senderId, 'u1');
      expect(msg.text, 'hey');
      expect(msg.sentAt!.isAtSameMomentAs(sentAt), isTrue);
      expect(msg.read, true);
    });

    test('fromFirestore applies safe defaults for missing fields', () async {
      await firestore
          .collection('chats')
          .doc('c1')
          .collection('messages')
          .doc('m2')
          .set(<String, dynamic>{});

      final doc = await firestore
          .collection('chats')
          .doc('c1')
          .collection('messages')
          .doc('m2')
          .get();
      final msg = ChatMessage.fromFirestore(doc);

      expect(msg.id, 'm2');
      expect(msg.senderId, '');
      expect(msg.text, '');
      expect(msg.sentAt, isNull);
      expect(msg.read, false);
    });

    test('toMap uses serverTimestamp sentinel and round-trips through Firestore',
        () async {
      const original = ChatMessage(
        id: 'm3',
        senderId: 'u1',
        text: 'hello',
      );

      final map = original.toMap();
      expect(map['sentAt'], isA<FieldValue>());

      await firestore
          .collection('chats')
          .doc('c1')
          .collection('messages')
          .doc('m3')
          .set(map);

      final doc = await firestore
          .collection('chats')
          .doc('c1')
          .collection('messages')
          .doc('m3')
          .get();
      final round = ChatMessage.fromFirestore(doc);

      expect(round.id, 'm3');
      expect(round.senderId, 'u1');
      expect(round.text, 'hello');
      expect(round.read, false);
      expect(round.sentAt, isNotNull);
    });
  });
}
