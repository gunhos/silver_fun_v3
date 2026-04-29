import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silver_fun/features/chat/repository/chat_repository.dart';

void main() {
  group('ChatRepository.chatId', () {
    test('sorts uids alphabetically and joins with underscore', () {
      expect(ChatRepository.chatId('zoe', 'aaron'), 'aaron_zoe');
      expect(ChatRepository.chatId('aaron', 'zoe'), 'aaron_zoe');
    });

    test('is consistent regardless of argument order', () {
      final a = ChatRepository.chatId('uid-a', 'uid-b');
      final b = ChatRepository.chatId('uid-b', 'uid-a');
      expect(a, equals(b));
    });

    test('handles equal uids deterministically', () {
      expect(ChatRepository.chatId('me', 'me'), 'me_me');
    });
  });

  group('ChatRepository (Firestore)', () {
    late FakeFirebaseFirestore firestore;
    late ChatRepository repo;
    const cid = 'a_b';

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repo = ChatRepository(firestore);
    });

    CollectionReference<Map<String, dynamic>> messages() {
      return firestore.collection('chats').doc(cid).collection('messages');
    }

    test('sendMessage writes a message with senderId, text, read=false, sentAt',
        () async {
      await repo.sendMessage(chatId: cid, senderId: 'a', text: 'hi');

      final snap = await messages().get();
      expect(snap.docs, hasLength(1));
      final data = snap.docs.first.data();
      expect(data['senderId'], 'a');
      expect(data['text'], 'hi');
      expect(data['read'], false);
      expect(data['sentAt'], isA<Timestamp>());
    });

    test('sendMessage trims whitespace and ignores empty text', () async {
      await repo.sendMessage(chatId: cid, senderId: 'a', text: '   ');
      await repo.sendMessage(chatId: cid, senderId: 'a', text: '  hello  ');

      final snap = await messages().get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first.data()['text'], 'hello');
    });

    test('watchMessages streams messages ordered by sentAt ascending',
        () async {
      await messages().add({
        'senderId': 'a',
        'text': 'first',
        'sentAt': Timestamp.fromDate(DateTime.utc(2026, 4, 28, 10)),
        'read': false,
      });
      await messages().add({
        'senderId': 'b',
        'text': 'third',
        'sentAt': Timestamp.fromDate(DateTime.utc(2026, 4, 28, 12)),
        'read': false,
      });
      await messages().add({
        'senderId': 'a',
        'text': 'second',
        'sentAt': Timestamp.fromDate(DateTime.utc(2026, 4, 28, 11)),
        'read': false,
      });

      final list = await repo.watchMessages(cid).first;
      expect(list.map((m) => m.text), equals(['first', 'second', 'third']));
    });

    test('markRead marks only incoming unread messages as read', () async {
      // Outgoing unread (mine, should stay false)
      await messages().add({
        'senderId': 'me',
        'text': 'mine unread',
        'sentAt': Timestamp.fromDate(DateTime.utc(2026, 4, 28, 9)),
        'read': false,
      });
      // Incoming unread (theirs — should flip to true)
      await messages().add({
        'senderId': 'them',
        'text': 'theirs unread',
        'sentAt': Timestamp.fromDate(DateTime.utc(2026, 4, 28, 10)),
        'read': false,
      });
      // Incoming already read (should stay true)
      await messages().add({
        'senderId': 'them',
        'text': 'theirs read',
        'sentAt': Timestamp.fromDate(DateTime.utc(2026, 4, 28, 11)),
        'read': true,
      });

      await repo.markRead(chatId: cid, myUid: 'me');

      final snap = await messages().get();
      final byText = {
        for (final d in snap.docs) d.data()['text'] as String: d.data(),
      };

      expect(byText['mine unread']!['read'], false);
      expect(byText['theirs unread']!['read'], true);
      expect(byText['theirs read']!['read'], true);
    });

    test('markRead is a no-op when there are no unread incoming messages',
        () async {
      await messages().add({
        'senderId': 'me',
        'text': 'mine',
        'sentAt': Timestamp.fromDate(DateTime.utc(2026, 4, 28, 9)),
        'read': false,
      });
      await messages().add({
        'senderId': 'them',
        'text': 'theirs read',
        'sentAt': Timestamp.fromDate(DateTime.utc(2026, 4, 28, 10)),
        'read': true,
      });

      await repo.markRead(chatId: cid, myUid: 'me');

      final snap = await messages().get();
      final byText = {
        for (final d in snap.docs) d.data()['text'] as String: d.data(),
      };
      expect(byText['mine']!['read'], false);
      expect(byText['theirs read']!['read'], true);
    });
  });
}
