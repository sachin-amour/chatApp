class UserModel {
  final String? uid;
  final String? name;
  final String? email;
  final String? imageUrl;
  final Map<String, dynamic>? lastMessage;
  final int? unreadCounter;
  final bool? isOnline;
  final DateTime? lastSeen;

  UserModel({
    this.uid,
    this.name,
    this.email,
    this.imageUrl,
    this.lastMessage,
    this.unreadCounter,
    this.isOnline,
    this.lastSeen,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'name': name,
      'email': email,
      'imageUrl': imageUrl,
      'lastMessage': lastMessage,
      'unreadCounter': unreadCounter,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] != null ? map['uid'] as String : null,
      name: map['name'] != null ? map['name'] as String : null,
      email: map['email'] != null ? map['email'] as String : null,
      imageUrl: map['imageUrl'] != null ? map['imageUrl'] as String : null,
      lastMessage: map['lastMessage'] != null
          ? Map<String, dynamic>.from(map['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCounter: map['unreadCounter'] != null ? map['unreadCounter'] as int : null,
      isOnline: map['isOnline'] != null ? map['isOnline'] as bool : null,  // 👈 Add this
      lastSeen: map['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSeen'])
          : null,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, imageUrl: $imageUrl, lastMessage: $lastMessage, unreadCounter: $unreadCounter, isOnline: $isOnline, lastSeen: $lastSeen)';
  }
}