import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:skill_exchange/models/chat_model.dart';
import 'package:skill_exchange/models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// 1. Create or Get Existing Chat Room
  /// Checks if a chat room already exists between current user & expert.
  /// If exists, returns existing chatId. If not, creates a new chat document.
  Future<String> createOrGetChat(String expertId) async {
    final uid = currentUserId;
    if (uid == null) {
      throw Exception('User is not logged in');
    }

    if (uid == expertId) {
      throw Exception('You cannot start a chat with yourself.');
    }

    try {
      // 1. Check if chat already exists between these 2 participants
      final existingChatQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: uid)
          .get();

      for (var doc in existingChatQuery.docs) {
        final List<dynamic> participants = doc.data()['participants'] ?? [];
        if (participants.contains(expertId)) {
          // Found existing chat room
          return doc.id;
        }
      }

      // 2. Fetch User & Expert details to populate participantDetails
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final expertDoc = await _firestore.collection('users').doc(expertId).get();

      final userData = userDoc.data() ?? {};
      final expertData = expertDoc.data() ?? {};

      final String userName = userData['name'] ?? userData['fullName'] ?? 'User';
      final String userImage = userData['profileImage'] ?? userData['avatarUrl'] ?? '';

      final String expertName = expertData['name'] ?? expertData['fullName'] ?? 'Expert';
      final String expertImage = expertData['profileImage'] ?? expertData['avatarUrl'] ?? '';

      // 3. Create unique chatId or let Firestore generate it
      final newChatRef = _firestore.collection('chats').doc();

      final newChatData = {
        'chatId': newChatRef.id,
        'participants': [uid, expertId],
        'participantDetails': {
          uid: {
            'name': userName,
            'avatarUrl': userImage,
            'isOnline': true,
          },
          expertId: {
            'name': expertName,
            'avatarUrl': expertImage,
            'isOnline': false,
          },
        },
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': 0,
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await newChatRef.set(newChatData);
      return newChatRef.id;
    } catch (e) {
      debugPrint("Error in createOrGetChat: $e");
      rethrow;
    }
  }

  /// 2. Send Message Function
  /// Saves message to messages subcollection and updates lastMessage, lastMessageTime, & unreadCount in batch.
  Future<void> sendMessage(
      String chatId,
      String receiverId,
      String message,
      ) async {
    final uid = currentUserId;
    if (uid == null || message.trim().isEmpty) return;

    final trimmedMessage = message.trim();
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    final MessageModel messageData = MessageModel(
      messageId: messageRef.id,
      senderId: uid,
      receiverId: receiverId,
      message: trimmedMessage,
      timestamp: DateTime.now(),
      isRead: false,
    );

    // Batch Write for atomic execution
    final WriteBatch batch = _firestore.batch();

    // 1. Add message document to messages subcollection
    batch.set(messageRef, messageData.toMap());

    // 2. Update main chat document meta fields
    final chatDocRef = _firestore.collection('chats').doc(chatId);
    batch.update(chatDocRef, {
      'lastMessage': trimmedMessage,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  /// Real-time stream for messages in a chat room
  Stream<List<MessageModel>> getMessageStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Stream for real-time chat updates
  Stream<List<ChatModel>> getChatStream() {
    final uid = currentUserId;
    if (uid == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Fetch chats for pull-to-refresh
  Future<List<ChatModel>> getChats() async {
    final uid = currentUserId;
    if (uid == null) return [];

    final snapshot = await _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ChatModel.fromFirestore(doc))
        .toList();
  }

  /// Reset unread count when opening a chat
  Future<void> markAsRead(String chatId) async {
    try {
      final chatDocRef = _firestore.collection('chats').doc(chatId);
      await chatDocRef.update({'unreadCount': 0});
    } catch (e) {
      debugPrint("Error marking chat as read: $e");
    }
  }
}