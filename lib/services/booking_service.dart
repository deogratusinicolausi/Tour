import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> createBooking(BookingModel booking) async {
    try {
      DocumentReference ref =
      await _firestore.collection('bookings').add(booking.toMap());
      // ⭐️ Send notification to admin
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': 'admin',
        'title': '📅 New Booking!',
        'body': '${booking.userName} booked ${booking.itemName}',
        'type': 'booking',
        'category': 'success',
        'icon': '📅',
        'actionType': 'open_booking',
        'actionId': booking.itemId,
        'isRead': false,
        'isPushed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

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
      }





      );
      // ⭐️ Create payment record
      await _firestore.collection('payments').add({
        'userId': booking.userId,
        'userName': booking.userName,
        'userEmail': booking.userEmail,
        'userPhone': booking.userPhone,
        'bookingId': ref.id,
        'itemId': booking.itemId,
        'itemType': booking.itemType,
        'itemName': booking.itemName,
        'amount': booking.amount,
        'currency': booking.currency,
        'method': booking.paymentMethod.isNotEmpty ? booking.paymentMethod : 'cash',
        'status': 'pending',
        'transactionId': '',
        'reference': '',
        'notes': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return ref.id;
    } catch (e) {
      print('🔥 Error creating booking: $e');
      return null;
    }
  }


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