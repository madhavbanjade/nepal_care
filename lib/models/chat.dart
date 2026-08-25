import 'package:cloud_firestore/cloud_firestore.dart';

/// One row in the Messages list — a conversation between the current user
/// and one other participant (customer <-> provider, or provider <-> support).
///
/// Firestore shape (collection: `conversations`):
/// {
///   participantIds: [uid1, uid2],
///   participantNames: { uid1: "Sita Thapa", uid2: "Aarav" },
///   participantRoles: { uid1: "Senior Care Provider", uid2: "Customer" },
///   lastMessage: "See you at 10 AM tomorrow!",
///   lastMessageAt: Timestamp,
///   lastMessageSenderId: uid1,
///   unreadCount: { uid1: 0, uid2: 2 },   // per-participant unread count
/// }
class Conversation {
  const Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserRole,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastMessageIsMine,
    required this.unreadCount,
  });

  final String id;
  final String otherUserId;
  final String otherUserName;
  final String otherUserRole;
  final String lastMessage;
  final DateTime lastMessageAt;
  final bool lastMessageIsMine;
  final int unreadCount;

  factory Conversation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc, String currentUserId) {
    final data = doc.data()!;
    final participantIds = List<String>.from(data['participantIds'] as List);
    final otherId = participantIds.firstWhere((id) => id != currentUserId, orElse: () => '');
    final names = Map<String, dynamic>.from(data['participantNames'] as Map? ?? {});
    final roles = Map<String, dynamic>.from(data['participantRoles'] as Map? ?? {});
    final unread = Map<String, dynamic>.from(data['unreadCount'] as Map? ?? {});

    return Conversation(
      id: doc.id,
      otherUserId: otherId,
      otherUserName: (names[otherId] as String?) ?? 'Unknown',
      otherUserRole: (roles[otherId] as String?) ?? '',
      lastMessage: (data['lastMessage'] as String?) ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageIsMine: data['lastMessageSenderId'] == currentUserId,
      unreadCount: (unread[currentUserId] as int?) ?? 0,
    );
  }
}

/// A single chat bubble inside a conversation.
///
/// Firestore shape (subcollection: `conversations/{id}/messages`):
/// {
///   senderId: uid,
///   text: "See you at 10 AM tomorrow!",
///   sentAt: Timestamp,
/// }
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;

  bool isMine(String currentUserId) => senderId == currentUserId;

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String,
      text: data['text'] as String,
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}