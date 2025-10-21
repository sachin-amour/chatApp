import 'dart:convert';

enum CallType { voice, video }

enum CallStatus { incoming, outgoing, missed, declined }

class CallModel {
  final String? callId;
  final String? callerId;
  final String? receiverId;
  final CallType? callType;
  final CallStatus? callStatus;
  final DateTime? timestamp;
  final int? duration; // in seconds
  final bool? isGroupCall;
  final List<String>? participants;

  CallModel({
    this.callId,
    this.callerId,
    this.receiverId,
    this.callType,
    this.callStatus,
    this.timestamp,
    this.duration,
    this.isGroupCall,
    this.participants,
  });

  Map<String, dynamic> toMap() {
    return {
      'callId': callId,
      'callerId': callerId,
      'receiverId': receiverId,
      'callType': callType?.name,
      'callStatus': callStatus?.name,
      'timestamp': timestamp?.millisecondsSinceEpoch,
      'duration': duration,
      'isGroupCall': isGroupCall ?? false,
      'participants': participants,
    };
  }

  factory CallModel.fromMap(Map<String, dynamic> map) {
    return CallModel(
      callId: map['callId'],
      callerId: map['callerId'],
      receiverId: map['receiverId'],
      callType: map['callType'] != null
          ? CallType.values.firstWhere(
            (e) => e.name == map['callType'],
        orElse: () => CallType.voice,
      )
          : CallType.voice,
      callStatus: map['callStatus'] != null
          ? CallStatus.values.firstWhere(
            (e) => e.name == map['callStatus'],
        orElse: () => CallStatus.outgoing,
      )
          : CallStatus.outgoing,
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : null,
      duration: map['duration'],
      isGroupCall: map['isGroupCall'] ?? false,
      participants: map['participants'] != null
          ? List<String>.from(map['participants'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CallModel.fromJson(String source) =>
      CallModel.fromMap(json.decode(source));

  CallModel copyWith({
    String? callId,
    String? callerId,
    String? receiverId,
    CallType? callType,
    CallStatus? callStatus,
    DateTime? timestamp,
    int? duration,
    bool? isGroupCall,
    List<String>? participants,
  }) {
    return CallModel(
      callId: callId ?? this.callId,
      callerId: callerId ?? this.callerId,
      receiverId: receiverId ?? this.receiverId,
      callType: callType ?? this.callType,
      callStatus: callStatus ?? this.callStatus,
      timestamp: timestamp ?? this.timestamp,
      duration: duration ?? this.duration,
      isGroupCall: isGroupCall ?? this.isGroupCall,
      participants: participants ?? this.participants,
    );
  }
}