import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final List<String> participants;
  final Map<String, dynamic>? participantDetails; // Stores names, avatars, online status
  final String lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  ChatModel({
    required this.chatId,
    required this.participants,
    this.participantDetails,
    required this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? messageTime;
    if (data['lastMessageTime'] != null) {
      if (data['lastMessageTime'] is Timestamp) {
        messageTime = (data['lastMessageTime'] as Timestamp).toDate();
      } else if (data['lastMessageTime'] is int) {
        messageTime = DateTime.fromMillisecondsSinceEpoch(data['lastMessageTime']);
      }
    }

    return ChatModel(
      chatId: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantDetails: data['participantDetails'] as Map<String, dynamic>?,
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: messageTime,
      unreadCount: (data['unreadCount'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'participants': participants,
      'participantDetails': participantDetails,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : FieldValue.serverTimestamp(),
      'unreadCount': unreadCount,
    };
  }
}