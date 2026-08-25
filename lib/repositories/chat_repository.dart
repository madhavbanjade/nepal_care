import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nepal_care/models/chat.dart';

/// Handles all Firestore reads/writes for conversations + messages.
/// Follows the same shape as UserRepository (stream-based, no manual polling).
class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _conversations => _db.collection('conversations');

  /// All conversations the current user is part of, newest first.
  Stream<List<Conversation>> streamConversations(String currentUserId) {
    return _conversations
        .where('participantIds', arrayContains: currentUserId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Conversation.fromDoc(doc, currentUserId)).toList());
  }

  /// All messages in one conversation, oldest first (so a ListView can
  /// render top-to-bottom, or reverse it for a bottom-anchored chat UI).
  Stream<List<ChatMessage>> streamMessages(String conversationId) {
    return _conversations
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList());
  }

  /// Finds an existing conversation between two users, or creates one.
  /// Call this when a customer taps "Message" on a provider's profile
  /// (or "Book" flow) for the first time.
  Future<String> getOrCreateConversation({
    required String userAId,
    required String userAName,
    required String userARole,
    required String userBId,
    required String userBName,
    required String userBRole,
  }) async {
    final existing = await _conversations
        .where('participantIds', arrayContains: userAId)
        .get();

    for (final doc in existing.docs) {
      final ids = List<String>.from(doc.data()['participantIds'] as List);
      if (ids.contains(userBId)) return doc.id;
    }

    final newDoc = await _conversations.add({
      'participantIds': [userAId, userBId],
      'participantNames': {userAId: userAName, userBId: userBName},
      'participantRoles': {userAId: userARole, userBId: userBRole},
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageSenderId': '',
      'unreadCount': {userAId: 0, userBId: 0},
    });

    return newDoc.id;
  }

  /// Sends a message and updates the conversation's preview fields +
  /// bumps the recipient's unread count in one batched write.
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String recipientId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final conversationRef = _conversations.doc(conversationId);
    final messageRef = conversationRef.collection('messages').doc();

    final batch = _db.batch();
    batch.set(messageRef, {
      'senderId': senderId,
      'text': trimmed,
      'sentAt': FieldValue.serverTimestamp(),
    });
    batch.update(conversationRef, {
      'lastMessage': trimmed,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
      'unreadCount.$recipientId': FieldValue.increment(1),
    });

    await batch.commit();
  }

  /// Call when the user opens a conversation, to clear their unread badge.
  Future<void> markConversationRead({
    required String conversationId,
    required String currentUserId,
  }) {
    return _conversations.doc(conversationId).update({
      'unreadCount.$currentUserId': 0,
    });
  }
}