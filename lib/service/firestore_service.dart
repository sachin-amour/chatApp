import 'package:amour_chat/model/auth_model.dart';
import 'package:amour_chat/model/chat_model.dart';
import 'package:amour_chat/model/messages.dart';
import 'package:amour_chat/service/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetIt _getIt = GetIt.instance;
  late Authservice _auth;
  CollectionReference<UserProfile>? _usersCollection;
  CollectionReference<Chat>? _chatsCollection;

  FirestoreService() {
    _auth = _getIt.get<Authservice>();
    _setup();
  }

  void _setup() {
    _usersCollection = _firestore
        .collection("users")
        .withConverter<UserProfile>(
      fromFirestore: (snapshot, _) =>
          UserProfile.fromJson(snapshot.data()!),
      toFirestore: (userProfile, _) => userProfile.toJson(),
    );
    _chatsCollection = _firestore
        .collection("chats")
        .withConverter<Chat>(
      fromFirestore: (snapshot, _) => Chat.fromJson(snapshot.data()!),
      toFirestore: (chat, _) => chat.toJson(),
    );
  }

  Future<void> creatUserProfile({required UserProfile userProfile}) async {
    await _usersCollection?.doc(userProfile.uid).set(userProfile);
  }

  Stream<QuerySnapshot<UserProfile>>? getUserProfiles() {
    return _usersCollection
        ?.where("uid", isNotEqualTo: _auth.user!.uid)
        .snapshots();
  }

  // Get user chats that have at least one message
  Stream<QuerySnapshot<Chat>> getUserChats(String userId) {
    return _chatsCollection!
        .where("participants", arrayContains: userId)
        .orderBy("id")
        .snapshots();
  }

  // Search user by email
  Future<UserProfile?> searchUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .where('uid', isNotEqualTo: _auth.user!.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return UserProfile.fromJson(querySnapshot.docs.first.data());
    } catch (e) {
      print('Error searching user: $e');
      return null;
    }
  }

  // Get a single user profile
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _usersCollection?.doc(uid).get();
      return doc?.data();
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<bool> CheckChatExists(String uid1, String uid2) async {
    if (_chatsCollection == null) {
      print("Error: _chatsCollection is null, cannot check chat existence.");
      return false;
    }
    String chatID = generateChatId(uid1: uid1, uid2: uid2);
    final result = await _chatsCollection!.doc(chatID).get();
    return result.exists;
  }

  Future<void> createChat(String uid1, String uid2) async {
    String chatID = generateChatId(uid1: uid1, uid2: uid2);
    final docref = _chatsCollection!.doc(chatID);
    final chat = Chat(id: chatID, participants: [uid1, uid2], messages: []);
    await docref.set(chat);
  }

  Future<void> sendChatMessage(
      String uid1,
      String uid2,
      Message message,
      ) async {
    String chatID = generateChatId(uid1: uid1, uid2: uid2);
    final docref = _chatsCollection!.doc(chatID);
    await docref.update({
      "messages": FieldValue.arrayUnion([message.toJson()]),
    });
  }

  // Delete a specific message
  Future<void> deleteMessage(
      String uid1,
      String uid2,
      Message message,
      ) async {
    String chatID = generateChatId(uid1: uid1, uid2: uid2);
    final docref = _chatsCollection!.doc(chatID);
    await docref.update({
      "messages": FieldValue.arrayRemove([message.toJson()]),
    });
  }

  // Delete entire chat
  Future<void> deleteChat(String uid1, String uid2) async {
    String chatID = generateChatId(uid1: uid1, uid2: uid2);
    await _chatsCollection!.doc(chatID).delete();
  }

  Stream<DocumentSnapshot<Chat>> getChatData(String uid1, String uid2) {
    String chatID = generateChatId(uid1: uid1, uid2: uid2);
    return _chatsCollection?.doc(chatID).snapshots()
    as Stream<DocumentSnapshot<Chat>>;
  }

  String generateChatId({required String uid1, required String uid2}) {
    List uids = [uid1, uid2];
    uids.sort();
    String chatId = uids.fold("", (id, uid) => "$id$uid");
    return chatId;
  }
}