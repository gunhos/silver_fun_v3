import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/chat_message.dart';

class ChatRepository {
  final FirebaseFirestore _db;

  ChatRepository(this._db);

  static String chatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return ids.join('_');
  }

  CollectionReference<Map<String, dynamic>> _messages(String cid) {
    return _db.collection('chats').doc(cid).collection('messages');
  }

  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _messages(chatId)
        .orderBy('sentAt')
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromFirestore).toList());
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _messages(chatId).add({
      'senderId': senderId,
      'text': trimmed,
      'sentAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  Future<void> markRead({
    required String chatId,
    required String myUid,
  }) async {
    final unread = await _messages(chatId).where('read', isEqualTo: false).get();
    final toUpdate = unread.docs
        .where((d) => (d.data()['senderId'] as String?) != myUid)
        .toList();
    if (toUpdate.isEmpty) return;
    final batch = _db.batch();
    for (final d in toUpdate) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }
}
