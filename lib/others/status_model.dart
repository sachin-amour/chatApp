import 'dart:convert';

enum StatusType { text, image, video }

class StatusModel {
  final String? statusId;
  final String? userId;
  final String? content;
  final StatusType? statusType;
  final String? mediaUrl;
  final String? backgroundColor;
  final DateTime? timestamp;
  final DateTime? expiresAt;
  final List<String>? viewedBy;
  final String? caption;

  StatusModel({
    this.statusId,
    this.userId,
    this.content,
    this.statusType,
    this.mediaUrl,
    this.backgroundColor,
    this.timestamp,
    this.expiresAt,
    this.viewedBy,
    this.caption,
  });

  Map<String, dynamic> toMap() {
    return {
      'statusId': statusId,
      'userId': userId,
      'content': content,
      'statusType': statusType?.name,
      'mediaUrl': mediaUrl,
      'backgroundColor': backgroundColor,
      'timestamp': timestamp?.millisecondsSinceEpoch,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
      'viewedBy': viewedBy,
      'caption': caption,
    };
  }

  factory StatusModel.fromMap(Map<String, dynamic> map) {
    return StatusModel(
      statusId: map['statusId'],
      userId: map['userId'],
      content: map['content'],
      statusType: map['statusType'] != null
          ? StatusType.values.firstWhere(
            (e) => e.name == map['statusType'],
        orElse: () => StatusType.text,
      )
          : StatusType.text,
      mediaUrl: map['mediaUrl'],
      backgroundColor: map['backgroundColor'],
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : null,
      expiresAt: map['expiresAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expiresAt'])
          : null,
      viewedBy: map['viewedBy'] != null
          ? List<String>.from(map['viewedBy'])
          : null,
      caption: map['caption'],
    );
  }

  String toJson() => json.encode(toMap());

  factory StatusModel.fromJson(String source) =>
      StatusModel.fromMap(json.decode(source));

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  int get viewCount => viewedBy?.length ?? 0;

  StatusModel copyWith({
    String? statusId,
    String? userId,
    String? content,
    StatusType? statusType,
    String? mediaUrl,
    String? backgroundColor,
    DateTime? timestamp,
    DateTime? expiresAt,
    List<String>? viewedBy,
    String? caption,
  }) {
    return StatusModel(
      statusId: statusId ?? this.statusId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      statusType: statusType ?? this.statusType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      timestamp: timestamp ?? this.timestamp,
      expiresAt: expiresAt ?? this.expiresAt,
      viewedBy: viewedBy ?? this.viewedBy,
      caption: caption ?? this.caption,
    );
  }
}