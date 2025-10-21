import 'dart:developer';
import 'package:amour_chat/others/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import your models
// import '../models/message_model.dart';
// import '../models/chat_model.dart';

class ChatService {
  final _firestore = FirebaseFirestore.instance;

  // Generate chat ID from two user IDs
  String getChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Create or get existing chat
  Future<String> createChat(String currentUserId, String otherUserId) async {
    try {
      final chatId = getChatId(currentUserId, otherUserId);
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        await _firestore.collection('chats').doc(chatId).set({
          'chatId': chatId,
          'participants': [currentUserId, otherUserId],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': null,
          'lastMessageTime': null,
          'unreadCount': {currentUserId: 0, otherUserId: 0},
          'isTyping': {currentUserId: false, otherUserId: false},
          'lastSeen': {
            currentUserId: FieldValue.serverTimestamp(),
            otherUserId: FieldValue.serverTimestamp(),
          },
        });
        log('Chat created: $chatId');
      }
      return chatId;
    } catch (e) {
      log('Error creating chat: $e');
      rethrow;
    }
  }

  // Send message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String message,
    MessageType messageType = MessageType.text,
    String? mediaUrl,
  }) async {
    try {
      final messageId = _firestore.collection('chats').doc().id;
      final timestamp = DateTime.now();

      final messageData = MessageModel(
        messageId: messageId,
        senderId: senderId,
        receiverId: receiverId,
        message: message,
        messageType: messageType,
        timestamp: timestamp,
        status: MessageStatus.sent,
        mediaUrl: mediaUrl,
        isDeleted: false,
      );

      // Add message to messages subcollection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(messageData.toMap());

      // Update chat document
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': {
          'message': message,
          'senderId': senderId,
          'timestamp': timestamp.millisecondsSinceEpoch,
          'messageType': messageType.name,
        },
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount.$receiverId': FieldValue.increment(1),
      });

      log('Message sent successfully');
    } catch (e) {
      log('Error sending message: $e');
      rethrow;
    }
  }

  // Get messages stream
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      log('Error marking messages as read: $e');
    }
  }

  // Update typing status
  Future<void> updateTypingStatus(
      String chatId, String userId, bool isTyping) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isTyping.$userId': isTyping,
      });
    } catch (e) {
      log('Error updating typing status: $e');
    }
  }

  // Update last seen
  Future<void> updateLastSeen(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastSeen.$userId': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log('Error updating last seen: $e');
    }
  }

  // Get user's chats stream
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Delete message
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'isDeleted': true, 'message': 'This message was deleted'});
    } catch (e) {
      log('Error deleting message: $e');
      rethrow;
    }
  }

  // Update message status
  Future<void> updateMessageStatus(
      String chatId, String messageId, MessageStatus status) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'status': status.name});
    } catch (e) {
      log('Error updating message status: $e');
    }
  }
}