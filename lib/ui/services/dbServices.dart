import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final _fire = FirebaseFirestore.instance;

  // =============== USER METHODS ===============

  Future<void> saveUser(Map<String, dynamic> userData) async {
    try {
      await _fire.collection("users").doc(userData["uid"]).set(userData);
      log("User saved successfully");
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> loadUser(String uid) async {
    try {
      final res = await _fire.collection("users").doc(uid).get();

      if (res.data() != null) {
        log("User fetched successfully");
        return res.data();
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>?> fetchUsers(String currentUserId) async {
    try {
      final res = await _fire
          .collection("users")
          .where("uid", isNotEqualTo: currentUserId)
          .get();

      return res.docs.map((e) => e.data()).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> fetchUserStream(
      String currentUserId) =>
      _fire
          .collection("users")
          .where("uid", isNotEqualTo: currentUserId)
          .snapshots();

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? imageUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;

      await _fire.collection("users").doc(uid).update(updateData);
      log("User profile updated successfully");
    } catch (e) {
      log("Error updating user profile: $e");
      rethrow;
    }
  }

  // Update user's last message (for home screen list)
  Future<void> updateUserLastMessage({
    required String uid,
    required Map<String, dynamic> lastMessage,
  }) async {
    try {
      await _fire.collection("users").doc(uid).update({
        'lastMessage': lastMessage,
      });
    } catch (e) {
      log("Error updating last message: $e");
    }
  }

  // Search users by email or name
  Future<List<Map<String, dynamic>>> searchUsers({
    required String query,
    required String currentUserId,
  }) async {
    try {
      final emailResults = await _fire
          .collection("users")
          .where("email", isGreaterThanOrEqualTo: query.toLowerCase())
          .where("email", isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .where("uid", isNotEqualTo: currentUserId)
          .limit(20)
          .get();

      final nameResults = await _fire
          .collection("users")
          .where("name", isGreaterThanOrEqualTo: query)
          .where("name", isLessThanOrEqualTo: '$query\uf8ff')
          .where("uid", isNotEqualTo: currentUserId)
          .limit(20)
          .get();

      // Combine and deduplicate results
      final Set<String> seenUids = {};
      final List<Map<String, dynamic>> combinedResults = [];

      for (var doc in [...emailResults.docs, ...nameResults.docs]) {
        final data = doc.data();
        if (!seenUids.contains(data['uid'])) {
          seenUids.add(data['uid']);
          combinedResults.add(data);
        }
      }

      return combinedResults;
    } catch (e) {
      log("Error searching users: $e");
      rethrow;
    }
  }

  // Check if user exists by email
  Future<bool> userExistsByEmail(String email) async {
    try {
      final result = await _fire
          .collection("users")
          .where("email", isEqualTo: email)
          .limit(1)
          .get();

      return result.docs.isNotEmpty;
    } catch (e) {
      log("Error checking user existence: $e");
      return false;
    }
  }

  // Get user by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final result = await _fire
          .collection("users")
          .where("email", isEqualTo: email)
          .limit(1)
          .get();

      if (result.docs.isNotEmpty) {
        return result.docs.first.data();
      }
    } catch (e) {
      log("Error getting user by email: $e");
    }
    return null;
  }

  // Get multiple users by UIDs
  Future<List<Map<String, dynamic>>> getUsersByIds(List<String> uids) async {
    try {
      if (uids.isEmpty) return [];

      // Firestore 'in' query limit is 10
      final List<Map<String, dynamic>> allUsers = [];

      for (int i = 0; i < uids.length; i += 10) {
        final batch = uids.skip(i).take(10).toList();
        final result = await _fire
            .collection("users")
            .where("uid", whereIn: batch)
            .get();

        allUsers.addAll(result.docs.map((e) => e.data()).toList());
      }

      return allUsers;
    } catch (e) {
      log("Error fetching users by IDs: $e");
      rethrow;
    }
  }

  // =============== UTILITY METHODS ===============

  // Batch write for better performance
  Future<void> batchUpdateUsers(
      Map<String, Map<String, dynamic>> updates) async {
    try {
      final batch = _fire.batch();

      updates.forEach((uid, data) {
        final docRef = _fire.collection("users").doc(uid);
        batch.update(docRef, data);
      });

      await batch.commit();
      log("Batch update completed");
    } catch (e) {
      log("Error in batch update: $e");
      rethrow;
    }
  }

  // Delete user account
  Future<void> deleteUser(String uid) async {
    try {
      // Delete user document
      await _fire.collection("users").doc(uid).delete();

      // TODO: Delete user's chats, messages, statuses, calls
      // This should be done via Cloud Functions for better performance

      log("User deleted successfully");
    } catch (e) {
      log("Error deleting user: $e");
      rethrow;
    }
  }

  // Get user statistics
  Future<Map<String, int>> getUserStats(String uid) async {
    try {
      // Get total chats
      final chatsSnapshot = await _fire
          .collection("chats")
          .where("participants", arrayContains: uid)
          .get();

      // Get total messages sent
      int totalMessages = 0;
      for (var chatDoc in chatsSnapshot.docs) {
        final messagesSnapshot = await _fire
            .collection("chats")
            .doc(chatDoc.id)
            .collection("messages")
            .where("senderId", isEqualTo: uid)
            .get();
        totalMessages += messagesSnapshot.docs.length;
      }

      // Get total calls
      final callsSnapshot = await _fire
          .collection("calls")
          .where("participants", arrayContains: uid)
          .get();

      // Get active statuses
      final statusesSnapshot = await _fire
          .collection("statuses")
          .where("userId", isEqualTo: uid)
          .where("expiresAt",
          isGreaterThan: DateTime.now().millisecondsSinceEpoch)
          .get();

      return {
        'totalChats': chatsSnapshot.docs.length,
        'totalMessages': totalMessages,
        'totalCalls': callsSnapshot.docs.length,
        'activeStatuses': statusesSnapshot.docs.length,
      };
    } catch (e) {
      log("Error getting user stats: $e");
      return {
        'totalChats': 0,
        'totalMessages': 0,
        'totalCalls': 0,
        'activeStatuses': 0,
      };
    }
  }
}