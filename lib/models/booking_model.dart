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
  final String paymentStatus;
  final String paymentMethod;   // ⭐ ONGEZA HII
  final String bookingStatus;
  final String specialRequests;
  final DateTime? createdAt;
  final DateTime? updatedAt;    // ⭐ ONGEZA HII (kama haipo)
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
    this.paymentMethod = 'cash',   // ⭐ ONGEZA
    this.bookingStatus = 'pending',
    this.specialRequests = '',
    this.createdAt, this.updatedAt,
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
      paymentMethod: map['paymentMethod'] ?? 'cash',   // ⭐ ONGEZA
      bookingStatus: map['bookingStatus'] ?? 'pending',
      specialRequests: map['specialRequests'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
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
      'travelDate':
      travelDate != null ? Timestamp.fromDate(travelDate!) : null,
      'guests': guests,
      'amount': amount,
      'currency': currency,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,   // ⭐ ONGEZA
      'bookingStatus': bookingStatus,
      'specialRequests': specialRequests,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'couponCode': couponCode,
      'couponDiscount': couponDiscount,
      'finalAmount': finalAmount,
    };
  }
}