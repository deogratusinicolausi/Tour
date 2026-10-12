import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String itemType;
  final String itemId;
  final String itemName;
  final String itemImage;
  final DateTime? travelDate;
  final int guests;
  final double amount;
  final String currency;

  // ⭐ Payment
  final String paymentStatus;        // pending, processing, successful, failed, cancelled, expired, refunded
  final String paymentMethod;        // mobile_money, card, cash
  final String paymentNetwork;       // mpesa, airtel, tigo, visa, n.k.
  final String paymentTransactionId; // ⭐ NEW — Reference to payment_transactions
  final DateTime? paidAt;            // ⭐ NEW

  // ⭐ Booking status (SEPARATE from payment status)
  final String bookingStatus;        // pending, confirmed, cancelled, completed, cancellation_requested

  final String specialRequests;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ⭐ Refund
  final String refundStatus;         // none, requested, processing, completed, failed
  final double refundAmount;
  final DateTime? refundedAt;

  // ⭐ Coupons
  final String couponCode;
  final double couponDiscount;
  final double finalAmount;

  BookingModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userEmail = '',
    this.userPhone = '',
    required this.itemType,
    required this.itemId,
    required this.itemName,
    this.itemImage = '',
    this.travelDate,
    this.guests = 1,
    required this.amount,
    this.currency = 'USD',
    this.paymentStatus = 'pending',
    this.paymentMethod = 'mobile_money',
    this.paymentNetwork = '',
    this.paymentTransactionId = '',
    this.paidAt,
    this.bookingStatus = 'pending',
    this.specialRequests = '',
    this.createdAt,
    this.updatedAt,
    this.refundStatus = 'none',
    this.refundAmount = 0.0,
    this.refundedAt,
    this.couponCode = '',
    this.couponDiscount = 0.0,
    this.finalAmount = 0.0,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userPhone: map['userPhone'] ?? '',
      itemType: map['itemType'] ?? '',
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      itemImage: map['itemImage'] ?? '',
      travelDate: (map['travelDate'] as Timestamp?)?.toDate(),
      guests: map['guests'] ?? 1,
      amount: (map['amount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      paymentStatus: map['paymentStatus'] ?? 'pending',
      paymentMethod: map['paymentMethod'] ?? 'mobile_money',
      paymentNetwork: map['paymentNetwork'] ?? '',
      paymentTransactionId: map['paymentTransactionId'] ?? '',
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
      bookingStatus: map['bookingStatus'] ?? 'pending',
      specialRequests: map['specialRequests'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      refundStatus: map['refundStatus'] ?? 'none',
      refundAmount: (map['refundAmount'] ?? 0.0).toDouble(),
      refundedAt: (map['refundedAt'] as Timestamp?)?.toDate(),
      couponCode: map['couponCode'] ?? '',
      couponDiscount: (map['couponDiscount'] ?? 0.0).toDouble(),
      finalAmount: (map['finalAmount'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'itemType': itemType,
      'itemId': itemId,
      'itemName': itemName,
      'itemImage': itemImage,
      'travelDate': travelDate != null ? Timestamp.fromDate(travelDate!) : null,
      'guests': guests,
      'amount': amount,
      'currency': currency,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'paymentNetwork': paymentNetwork,
      'paymentTransactionId': paymentTransactionId,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'bookingStatus': bookingStatus,
      'specialRequests': specialRequests,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'refundStatus': refundStatus,
      'refundAmount': refundAmount,
      'refundedAt': refundedAt != null ? Timestamp.fromDate(refundedAt!) : null,
      'couponCode': couponCode,
      'couponDiscount': couponDiscount,
      'finalAmount': finalAmount,
    };
  }

  // ⭐ Convenience
  bool get isPaid => paymentStatus == 'successful';
  bool get isPending => paymentStatus == 'pending' || paymentStatus == 'processing';
  bool get isFailed => paymentStatus == 'failed';
  bool get isConfirmed => bookingStatus == 'confirmed';
  bool get isCancelled => bookingStatus == 'cancelled';
}
