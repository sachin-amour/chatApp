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

  // The unnecessary cast has been removed from this method.
  Stream<QuerySnapshot<UserProfile>>? getUserProfiles() {
    return _usersCollection
        ?.where("uid", isNotEqualTo: _auth.user!.uid)
        .snapshots();
  }

  Future<bool> CheckChatExists(String uid1, String uid2) async {
    if (_chatsCollection == null) {
      print("Error: _chatsCollection is null, cannot check chat existence.");
      return false;
    }
    String chatID = this.generateChatId(uid1: uid1, uid2: uid2);
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

