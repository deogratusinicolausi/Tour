import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cancellation_model.dart';

class CancellationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ Request cancellation
  Future<String?> requestCancellation({
    required String bookingId,
    required String userId,
    required String userName,
    required String userEmail,
    required String itemId,
    required String itemType,
    required String itemName,
    required String itemImage,
    required double bookingAmount,
    required String currency,
    required String reason,
    String additionalNotes = '',
    required double refundAmount,
  }) async {
    try {
      // Check if cancellation already requested
      final existing = await _firestore
          .collection('cancellations')
          .where('bookingId', isEqualTo: bookingId)
          .where('status', whereIn: ['pending', 'approved'])
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('Cancellation already requested for this booking');
      }

      // Create cancellation
      final ref = await _firestore.collection('cancellations').add({
        'bookingId': bookingId,
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'itemId': itemId,
        'itemType': itemType,
        'itemName': itemName,
        'itemImage': itemImage,
        'bookingAmount': bookingAmount,
        'refundAmount': refundAmount,
        'currency': currency,
        'reason': reason,
        'additionalNotes': additionalNotes,
        'status': 'pending',
        'adminNotes': '',
        'rejectionReason': '',
        'requestedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update booking status
      await _firestore.collection('bookings').doc(bookingId).update({
        'bookingStatus': 'cancellation_requested',
        'cancellationId': ref.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify admin
      await _firestore.collection('notifications').add({
        'userId': 'admin',
        'title': '❌ New Cancellation Request',
        'body': '$userName wants to cancel "$itemName"',
        'type': 'cancellation',
        'category': 'warning',
        'icon': '❌',
        'actionType': 'open_cancellation',
        'actionId': ref.id,
        'isRead': false,
        'isPushed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Log activity
      await _firestore.collection('activities').add({
        'type': 'cancellation',
        'action': 'requested',
        'title': 'Cancellation Requested',
        'description': '$userName requested cancellation for $itemName',
        'userId': userId,
        'userName': userName,
        'itemId': ref.id,
        'itemType': 'cancellation',
        'icon': '❌',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return ref.id;
    } catch (e) {
      print('🔥 Error requesting cancellation: $e');
      throw e;
    }
  }

  // ⭐️ Get user cancellations
  Stream<List<CancellationModel>> getUserCancellations(String userId) {
    return _firestore
        .collection('cancellations')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CancellationModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // ⭐️ Check if booking can be cancelled
  Future<Map<String, dynamic>> canCancelBooking({
    required String bookingId,
    required DateTime? travelDate,
  }) async {
    try {
      // Check if already requested
      final existing = await _firestore
          .collection('cancellations')
          .where('bookingId', isEqualTo: bookingId)
          .where('status', whereIn: ['pending', 'approved'])
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return {
          'canCancel': false,
          'message': 'Cancellation already requested for this booking',
        };
      }

      // Check cancel window (must cancel 2 days before travel)
      if (travelDate != null) {
        final daysUntilTravel =
            travelDate.difference(DateTime.now()).inDays;
        if (daysUntilTravel < 2) {
          return {
            'canCancel': false,
            'message':
            'Cannot cancel within 2 days of travel date. Please contact support.',
          };
        }
      }

      return {'canCancel': true, 'message': ''};
    } catch (e) {
      return {
        'canCancel': false,
        'message': 'Error checking cancellation',
      };
    }
  }

  // ⭐️ Calculate refund amount
  double calculateRefund({
    required double bookingAmount,
    required DateTime? travelDate,
  }) {
    if (travelDate == null) return bookingAmount * 0.5;

    final daysUntilTravel = travelDate.difference(DateTime.now()).inDays;

    // Refund policy:
    // 7+ days before: 100% refund
    // 3-6 days before: 75% refund
    // 2 days before: 50% refund
    // Less than 2 days: 0% refund

    if (daysUntilTravel >= 7) return bookingAmount;
    if (daysUntilTravel >= 3) return bookingAmount * 0.75;
    if (daysUntilTravel >= 2) return bookingAmount * 0.5;
    return 0;
  }

  // ⭐️ Get refund policy text
  String getRefundPolicy(DateTime? travelDate) {
    if (travelDate == null) return 'Refund policy applies';

    final daysUntilTravel = travelDate.difference(DateTime.now()).inDays;

    if (daysUntilTravel >= 7) return '100% refund available';
    if (daysUntilTravel >= 3) return '75% refund available';
    if (daysUntilTravel >= 2) return '50% refund available';
    return 'No refund available';
  }

  // ⭐️ Get cancellation stats
  Future<Map<String, int>> getStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('cancellations')
          .where('userId', isEqualTo: userId)
          .get();

      int pending = 0;
      int approved = 0;
      int rejected = 0;
      int refunded = 0;

      for (var doc in snapshot.docs) {
        final status = (doc.data())['status'] ?? 'pending';
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'approved':
            approved++;
            break;
          case 'rejected':
            rejected++;
            break;
          case 'refunded':
            refunded++;
            break;
        }
      }

      return {
        'total': snapshot.docs.length,
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
        'refunded': refunded,
      };
    } catch (e) {
      return {
        'total': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'refunded': 0,
      };
    }
  }
}