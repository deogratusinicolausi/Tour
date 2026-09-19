import 'package:cloud_firestore/cloud_firestore.dart';

class ReceiptModel {
  final String id;
  final String bookingId;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String itemType;
  final String itemName;
  final String itemImage;
  final DateTime? travelDate;
  final int guests;
  final double baseAmount;
  final double addonsAmount;
  final double couponDiscount;
  final String couponCode;
  final double totalAmount;
  final String currency;
  final String paymentMethod;
  final String paymentStatus;
  final String transactionId;
  final String bookingStatus;
  final DateTime? issuedAt;
  final DateTime? createdAt;

  ReceiptModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.userName,
    this.userEmail = '',
    this.userPhone = '',
    this.itemType = '',
    this.itemName = '',
    this.itemImage = '',
    this.travelDate,
    this.guests = 1,
    this.baseAmount = 0.0,
    this.addonsAmount = 0.0,
    this.couponDiscount = 0.0,
    this.couponCode = '',
    required this.totalAmount,
    this.currency = 'USD',
    this.paymentMethod = '',
    this.paymentStatus = 'pending',
    this.transactionId = '',
    this.bookingStatus = 'pending',
    this.issuedAt,
    this.createdAt,
  });

  factory ReceiptModel.fromMap(Map<String, dynamic> map, String id) {
    return ReceiptModel(
      id: id,
      bookingId: map['bookingId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userPhone: map['userPhone'] ?? '',
      itemType: map['itemType'] ?? '',
      itemName: map['itemName'] ?? '',
      itemImage: map['itemImage'] ?? '',
      travelDate: (map['travelDate'] as Timestamp?)?.toDate(),
      guests: map['guests'] ?? 1,
      baseAmount: (map['baseAmount'] ?? 0.0).toDouble(),
      addonsAmount: (map['addonsAmount'] ?? 0.0).toDouble(),
      couponDiscount: (map['couponDiscount'] ?? 0.0).toDouble(),
      couponCode: map['couponCode'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      paymentMethod: map['paymentMethod'] ?? '',
      paymentStatus: map['paymentStatus'] ?? 'pending',
      transactionId: map['transactionId'] ?? '',
      bookingStatus: map['bookingStatus'] ?? 'pending',
      issuedAt: (map['issuedAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'itemType': itemType,
      'itemName': itemName,
      'itemImage': itemImage,
      'travelDate': travelDate != null ? Timestamp.fromDate(travelDate!) : null,
      'guests': guests,
      'baseAmount': baseAmount,
      'addonsAmount': addonsAmount,
      'couponDiscount': couponDiscount,
      'couponCode': couponCode,
      'totalAmount': totalAmount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'transactionId': transactionId,
      'bookingStatus': bookingStatus,
      'issuedAt': issuedAt ?? FieldValue.serverTimestamp(),
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  String get receiptNumber {
    final date = createdAt ?? DateTime.now();
    return 'TUR-${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}-${id.substring(0, 6).toUpperCase()}';
  }

  String get timeAgo {
    if (createdAt == null) return 'just now';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 7}w ago';
  }
}