import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import 'sound_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ Get user notifications (Real-time)
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // ⭐️ Get unread count (Real-time)
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ⭐️ Create notification
  Future<String?> createNotification(NotificationModel notification) async {
    try {
      final ref = await _firestore
          .collection('notifications')
          .add(notification.toMap());
      return ref.id;
    } catch (e) {
      print('🔥 Error creating notification: $e');
      return null;
    }
  }

  // ⭐️ Mark as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Mark all as read
  Future<bool> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Clear all notifications
  Future<bool> clearAll(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ WATCH for NEW notifications → Play sound
  void listenForNewNotifications(String userId) {
    bool isFirstLoad = true;

    _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (isFirstLoad) {
        isFirstLoad = false;
        return;
      }

      // New notification added
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            final type = data['type'] ?? 'system';
            SoundService.playByType(type);
          }
        }
      }
    });
  }

  // ⭐️ Send booking notification
  Future<void> sendBookingNotification({
    required String userId,
    required String title,
    required String body,
    required String bookingId,
  }) async {
    await createNotification(NotificationModel(
      id: '',
      userId: userId,
      title: title,
      body: body,
      type: 'booking',
      category: 'success',
      icon: '✅',
      actionType: 'open_booking',
      actionId: bookingId,
    ));
  }

  // ⭐️ Send deal notification
  Future<void> sendDealNotification({
    required String userId,
    required String title,
    required String body,
    required String dealId,
  }) async {
    await createNotification(NotificationModel(
      id: '',
      userId: userId,
      title: title,
      body: body,
      type: 'deal',
      category: 'info',
      icon: '🎁',
      actionType: 'open_deal',
      actionId: dealId,
    ));
  }

  // ⭐️ Send review reply notification
  Future<void> sendReviewReplyNotification({
    required String userId,
    required String title,
    required String body,
    required String reviewId,
  }) async {
    await createNotification(NotificationModel(
      id: '',
      userId: userId,
      title: title,
      body: body,
      type: 'review',
      category: 'info',
      icon: '💬',
      actionType: 'open_review',
      actionId: reviewId,
    ));
  }
}