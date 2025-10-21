import 'dart:developer';
import 'package:amour_chat/others/call_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:amour_chat/others/status_model.dart';

class CallStatusService {
  final _firestore = FirebaseFirestore.instance;

  // =============== CALL METHODS ===============

  // Save call record
  Future<void> saveCallRecord(CallModel call) async {
    try {
      await _firestore
          .collection('calls')
          .doc(call.callId)
          .set(call.toMap());
      log('Call record saved');
    } catch (e) {
      log('Error saving call record: $e');
      rethrow;
    }
  }

  // Get user's call history
  Stream<QuerySnapshot<Map<String, dynamic>>> getCallHistory(String userId) {
    return _firestore
        .collection('calls')
        .where('participants', arrayContains: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  // Update call duration and status
  Future<void> updateCallStatus({
    required String callId,
    required CallStatus status,
    int? duration,
  }) async {
    try {
      final updateData = {
        'callStatus': status.name,
        if (duration != null) 'duration': duration,
      };
      await _firestore.collection('calls').doc(callId).update(updateData);
    } catch (e) {
      log('Error updating call status: $e');
      rethrow;
    }
  }

  // =============== STATUS METHODS ===============

  // Add status
  Future<void> addStatus(StatusModel status) async {
    try {
      await _firestore
          .collection('statuses')
          .doc(status.statusId)
          .set(status.toMap());
      log('Status added successfully');
    } catch (e) {
      log('Error adding status: $e');
      rethrow;
    }
  }

  // Get user's statuses
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserStatuses(String userId) {
    return _firestore
        .collection('statuses')
        .where('userId', isEqualTo: userId)
        .where('expiresAt',
        isGreaterThan: DateTime.now().millisecondsSinceEpoch)
        .orderBy('expiresAt', descending: false)
        .snapshots();
  }

  // Get all contacts' statuses
  Stream<QuerySnapshot<Map<String, dynamic>>> getContactsStatuses(
      List<String> contactIds) {
    if (contactIds.isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection('statuses')
        .where('userId', whereIn: contactIds.take(10).toList()) // Firestore limit
        .where('expiresAt',
        isGreaterThan: DateTime.now().millisecondsSinceEpoch)
        .orderBy('expiresAt', descending: false)
        .snapshots();
  }

  // Mark status as viewed
  Future<void> markStatusAsViewed(String statusId, String viewerId) async {
    try {
      await _firestore.collection('statuses').doc(statusId).update({
        'viewedBy': FieldValue.arrayUnion([viewerId]),
      });
    } catch (e) {
      log('Error marking status as viewed: $e');
      rethrow;
    }
  }

  // Delete status
  Future<void> deleteStatus(String statusId) async {
    try {
      await _firestore.collection('statuses').doc(statusId).delete();
      log('Status deleted successfully');
    } catch (e) {
      log('Error deleting status: $e');
      rethrow;
    }
  }

  // Delete expired statuses (cleanup)
  Future<void> deleteExpiredStatuses(String userId) async {
    try {
      final expiredStatuses = await _firestore
          .collection('statuses')
          .where('userId', isEqualTo: userId)
          .where('expiresAt',
          isLessThan: DateTime.now().millisecondsSinceEpoch)
          .get();

      for (var doc in expiredStatuses.docs) {
        await doc.reference.delete();
      }
      log('Expired statuses deleted');
    } catch (e) {
      log('Error deleting expired statuses: $e');
    }
  }
}