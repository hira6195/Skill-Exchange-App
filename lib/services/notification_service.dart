import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  /// Realtime Stream of notifications for current user
  Stream<List<NotificationModel>> getUserNotificationsStream() {
    final userId = _currentUserId;

    if (userId == null) {
      // Return empty stream if no user is logged in
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      List<NotificationModel> notifications = snapshot.docs.map((doc) {
        return NotificationModel.fromMap(doc.data(), doc.id);
      }).toList();

      // Client-side sorting by createdAt (Index error se bachne ke liye)
      notifications.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        Timestamp t1 = a.createdAt is Timestamp ? a.createdAt : Timestamp.now();
        Timestamp t2 = b.createdAt is Timestamp ? b.createdAt : Timestamp.now();
        return t2.compareTo(t1);
      });

      return notifications;
    });
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print("Error marking notification read: $e");
    }
  }

  /// Send new notification to a specific user
  Future<void> sendNotification({
    required String targetUserId,
    required String title,
    required String body,
    required String type,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': targetUserId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}