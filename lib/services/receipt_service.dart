import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/receipt_model.dart';

class ReceiptService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ Create receipt
  Future<String?> createReceipt(ReceiptModel receipt) async {
    try {
      final ref = await _firestore
          .collection('receipts')
          .add(receipt.toMap());
      return ref.id;
    } catch (e) {
      print('🔥 Error creating receipt: $e');
      return null;
    }
  }

  // ⭐️ Get receipt by booking ID
  Future<ReceiptModel?> getReceiptByBooking(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('receipts')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return ReceiptModel.fromMap(
          snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (e) {
      return null;
    }
  }

  // ⭐️ Get user receipts
  Stream<List<ReceiptModel>> getUserReceipts(String userId) {
    return _firestore
        .collection('receipts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ReceiptModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // ⭐️ Auto-create receipt from booking
  Future<ReceiptModel?> createFromBooking({
    required String bookingId,
    required String userId,
    required String userName,
    required String userEmail,
    required String userPhone,
    required String itemType,
    required String itemName,
    required String itemImage,
    required DateTime? travelDate,
    required int guests,
    required double baseAmount,
    required double addonsAmount,
    required double couponDiscount,
    required String couponCode,
    required double totalAmount,
    required String currency,
    required String paymentMethod,
    required String paymentStatus,
    required String transactionId,
    required String bookingStatus,
  }) async {
    try {
      final receipt = ReceiptModel(
        id: '',
        bookingId: bookingId,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
        itemType: itemType,
        itemName: itemName,
        itemImage: itemImage,
        travelDate: travelDate,
        guests: guests,
        baseAmount: baseAmount,
        addonsAmount: addonsAmount,
        couponDiscount: couponDiscount,
        couponCode: couponCode,
        totalAmount: totalAmount,
        currency: currency,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        transactionId: transactionId,
        bookingStatus: bookingStatus,
      );

      final id = await createReceipt(receipt);
      if (id == null) return null;

      // Return receipt with ID
      return ReceiptModel(
        id: id,
        bookingId: receipt.bookingId,
        userId: receipt.userId,
        userName: receipt.userName,
        userEmail: receipt.userEmail,
        userPhone: receipt.userPhone,
        itemType: receipt.itemType,
        itemName: receipt.itemName,
        itemImage: receipt.itemImage,
        travelDate: receipt.travelDate,
        guests: receipt.guests,
        baseAmount: receipt.baseAmount,
        addonsAmount: receipt.addonsAmount,
        couponDiscount: receipt.couponDiscount,
        couponCode: receipt.couponCode,
        totalAmount: receipt.totalAmount,
        currency: receipt.currency,
        paymentMethod: receipt.paymentMethod,
        paymentStatus: receipt.paymentStatus,
        transactionId: receipt.transactionId,
        bookingStatus: receipt.bookingStatus,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('🔥 Error creating receipt from booking: $e');
      return null;
    }
  }
}