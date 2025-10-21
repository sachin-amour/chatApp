import 'dart:convert';

enum MessageType { text, image, video, audio, document }

enum MessageStatus { sending, sent, delivered, read }

class MessageModel {
  final String? messageId;
  final String? senderId;
  final String? receiverId;
  final String? message;
  final MessageType? messageType;
  final DateTime? timestamp;
  final MessageStatus? status;
  final String? mediaUrl;
  final bool? isDeleted;
  final String? replyTo;

  MessageModel({
    this.messageId,
    this.senderId,
    this.receiverId,
    this.message,
    this.messageType,
    this.timestamp,
    this.status,
    this.mediaUrl,
    this.isDeleted,
    this.replyTo,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'messageType': messageType?.name,
      'timestamp': timestamp?.millisecondsSinceEpoch,
      'status': status?.name,
      'mediaUrl': mediaUrl,
      'isDeleted': isDeleted ?? false,
      'replyTo': replyTo,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      message: map['message'],
      messageType: map['messageType'] != null
          ? MessageType.values.firstWhere(
            (e) => e.name == map['messageType'],
        orElse: () => MessageType.text,
      )
          : MessageType.text,
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : null,
      status: map['status'] != null
          ? MessageStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => MessageStatus.sent,
      )
          : MessageStatus.sent,
      mediaUrl: map['mediaUrl'],
      isDeleted: map['isDeleted'] ?? false,
      replyTo: map['replyTo'],
    );
  }

  String toJson() => json.encode(toMap());

  factory MessageModel.fromJson(String source) =>
      MessageModel.fromMap(json.decode(source));

  MessageModel copyWith({
    String? messageId,
    String? senderId,
    String? receiverId,
    String? message,
    MessageType? messageType,
    DateTime? timestamp,
    MessageStatus? status,
    String? mediaUrl,
    bool? isDeleted,
    String? replyTo,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      isDeleted: isDeleted ?? this.isDeleted,
      replyTo: replyTo ?? this.replyTo,
    );
  }
}