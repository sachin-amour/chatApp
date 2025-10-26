import 'package:amour_chat/model/auth_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference? _usersCollection;
  FirestoreService() {
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
  }
  Future<void> creatUserProfile({
    required UserProfile userProfile,
  }) async {
    await _usersCollection?.doc(userProfile.uid).set(userProfile);
  }
}
