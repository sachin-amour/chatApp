import 'dart:convert';

class ChatModel {
  final String? chatId;
  final List<String>? participants;
  final Map<String, dynamic>? lastMessage;
  final DateTime? lastMessageTime;
  final Map<String, int>? unreadCount;
  final DateTime? createdAt;
  final Map<String, bool>? isTyping;
  final Map<String, DateTime>? lastSeen;

  ChatModel({
    this.chatId,
    this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount,
    this.createdAt,
    this.isTyping,
    this.lastSeen,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
      'unreadCount': unreadCount,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'isTyping': isTyping,
      'lastSeen': lastSeen?.map(
            (key, value) => MapEntry(key, value.millisecondsSinceEpoch),
      ),
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      chatId: map['chatId'],
      participants: map['participants'] != null
          ? List<String>.from(map['participants'])
          : null,
      lastMessage: map['lastMessage'] != null
          ? Map<String, dynamic>.from(map['lastMessage'])
          : null,
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime'])
          : null,
      unreadCount: map['unreadCount'] != null
          ? Map<String, int>.from(map['unreadCount'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
      isTyping: map['isTyping'] != null
          ? Map<String, bool>.from(map['isTyping'])
          : null,
      lastSeen: map['lastSeen'] != null
          ? (map['lastSeen'] as Map<String, dynamic>).map(
            (key, value) =>
            MapEntry(key, DateTime.fromMillisecondsSinceEpoch(value)),
      )
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatModel.fromJson(String source) =>
      ChatModel.fromMap(json.decode(source));

  ChatModel copyWith({
    String? chatId,
    List<String>? participants,
    Map<String, dynamic>? lastMessage,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCount,
    DateTime? createdAt,
    Map<String, bool>? isTyping,
    Map<String, DateTime>? lastSeen,
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      isTyping: isTyping ?? this.isTyping,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}