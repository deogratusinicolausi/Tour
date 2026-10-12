import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════
  // ⭐ CREATE BOOKING (kabla ya payment)
  // ═══════════════════════════════════════════
  /// Booking inaundwa na paymentStatus: 'pending'
  /// Booking status = 'pending' — haitakuwa 'confirmed' hadi payment ifanikiwe
  Future<String?> createBooking(BookingModel booking) async {
    try {
      // ⭐ Force payment pending — SERVER will update baada ya payment
      final bookingData = booking.toMap();
      bookingData['paymentStatus'] = 'pending';
      bookingData['bookingStatus'] = 'pending';

      DocumentReference ref =
          await _firestore.collection('bookings').add(bookingData);

      // ⭐ Admin notification
      await _firestore.collection('notifications').add({
        'userId': 'admin',
        'title': '📅 New Booking (Unpaid)!',
        'body': '${booking.userName} booked ${booking.itemName} — awaiting payment',
        'type': 'booking',
        'category': 'warning',
        'icon': '📅',
        'actionType': 'open_booking',
        'actionId': ref.id,
        'isRead': false,
        'isPushed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ⭐ Activity log
      await _firestore.collection('activities').add({
        'type': 'booking',
        'action': 'created',
        'title': 'New Booking: ${booking.itemName}',
        'description':
            '${booking.userName} booked ${booking.guests} guest(s) for ${booking.currency} ${booking.amount}',
        'userId': booking.userId,
        'userName': booking.userName,
        'itemId': booking.itemId,
        'itemType': booking.itemType,
        'icon': '📅',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return ref.id;
    } catch (e) {
      print('🔥 Error creating booking: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════
  // ⭐ GET USER BOOKINGS
  // ═══════════════════════════════════════════
  Stream<List<BookingModel>> getUserBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // ═══════════════════════════════════════════
  // ⭐ GET SINGLE BOOKING (Real-time)
  // ═══════════════════════════════════════════
  Stream<BookingModel?> getBooking(String bookingId) {
    return _firestore
        .collection('bookings')
        .doc(bookingId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return BookingModel.fromMap(
          doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  // ═══════════════════════════════════════════
  // ⭐ CANCEL BOOKING (user side)
  // ═══════════════════════════════════════════
  Future<bool> cancelBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'bookingStatus': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
