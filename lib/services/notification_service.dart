import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import '../screens/map_screen.dart';
import 'sound_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐ Navigate when notification is tapped
  static final navigatorKey = GlobalKey<NavigatorState>();

  // ⭐️ Local notification plugin
  static final FlutterLocalNotificationsPlugin _localPlugin =
  FlutterLocalNotificationsPlugin();

  // ⭐️ Notification tap handler (must be declared as a named function)
  static void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload ?? '';
    if (payload.isEmpty) return;

    final parts = payload.split('|');
    if (parts.length < 3) return;

    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    final name = parts[2];

    if (lat == null || lng == null) return;

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => MapScreen(
          destinationLat: lat,
          destinationLng: lng,
          destinationName: name,
        ),
      ),
    );
  }

  // ============================================================
  // ⭐️ LOCAL NOTIFICATIONS
  // ============================================================

  static Future<void> init() async {
    // ⚠️ Use const constructors carefully — this is the FIX for error #1
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _localPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );
    } catch (e) {
      debugPrint('🔥 notification init error: $e');
    }

    // ⚠️ Guard against null (error #2 fix)
    final androidImpl = _localPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      try {
        await androidImpl.requestNotificationsPermission();
      } catch (e) {
        debugPrint('🔥 notif permission error: $e');
      }
    }
  }

  static Future<void> showNearbyNotification({
    required String title,
    required String body,
    required String id,
    required double lat,
    required double lng,
    required String name,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'turiva_nearby_sound_v1', // ⚠️ Change channel ID → forces Android to re-register sound
      'Nearby Places',
      channelDescription: 'Alerts when you are near tourist spots',
      importance: Importance.max, // ⬆️ MAX = heads-up + sound
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
      enableLights: true,
      ledColor: const Color(0xFFF5A623), // gold LED
      ledOnMs: 500,
      ledOffMs: 500,
      category: AndroidNotificationCategory.alarm, // 🔔 alarms make sound even in silent
      visibility: NotificationVisibility.public,
      // sound: RawResourceAndroidNotificationSound('safari_alert'), // (See STEP 3)
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      // 👇 custom sound name without extension (only used with STEP 3)
      // sound: 'safari_alert.aiff',
      interruptionLevel: InterruptionLevel.timeSensitive,
      // 🔔 bypass silent mode
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // ⚠️ Use NAMED args (error #3 + #4 fix)
      await _localPlugin.show(
        id: id.hashCode,
        title: title,
        body: body,
        notificationDetails: details,
        payload: '$lat|$lng|$name',
      );
    } catch (e) {
      debugPrint('🔥 show notification error: $e');
    }
  }

  // ============================================================
  // ⭐️ FIRESTORE NOTIFICATIONS (existing methods — unchanged)
  // ============================================================

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

  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

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