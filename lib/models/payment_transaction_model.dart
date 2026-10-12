import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentTransactionModel {
  final String transactionId;
  final String bookingId;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String provider;
  final String providerTransactionId;
  final String providerReference;
  final String providerStatus;
  final String paymentMethod;
  final String paymentNetwork;
  final String maskedAccount;
  final String currency;
  final double amount;
  final double fees;
  final double netAmount;
  final String status;
  final String? failureReason;
  final String refundStatus;
  final double refundAmount;
  final DateTime? refundedAt;
  final String idempotencyKey;
  final String redirectUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? paidAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;

  PaymentTransactionModel({
    required this.transactionId,
    required this.bookingId,
    required this.userId,
    this.userName = '',
    this.userEmail = '',
    this.userPhone = '',
    this.provider = 'pesapal',
    this.providerTransactionId = '',
    this.providerReference = '',
    this.providerStatus = '',
    this.paymentMethod = 'mobile_money',
    this.paymentNetwork = '',
    this.maskedAccount = '',
    this.currency = 'TZS',
    required this.amount,
    this.fees = 0.0,
    this.netAmount = 0.0,
    this.status = 'pending',
    this.failureReason,
    this.refundStatus = 'none',
    this.refundAmount = 0.0,
    this.refundedAt,
    this.idempotencyKey = '',
    this.redirectUrl = '',
    required this.createdAt,
    this.updatedAt,
    this.paidAt,
    this.expiresAt,
    this.metadata = const {},
  });

  factory PaymentTransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentTransactionModel(
      transactionId: id,
      bookingId: map['bookingId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userPhone: map['userPhone'] ?? '',
      provider: map['provider'] ?? 'pesapal',
      providerTransactionId: map['providerTransactionId'] ?? '',
      providerReference: map['providerReference'] ?? '',
      providerStatus: map['providerStatus'] ?? '',
      paymentMethod: map['paymentMethod'] ?? 'mobile_money',
      paymentNetwork: map['paymentNetwork'] ?? '',
      maskedAccount: map['maskedAccount'] ?? '',
      currency: map['currency'] ?? 'TZS',
      amount: (map['amount'] ?? 0.0).toDouble(),
      fees: (map['fees'] ?? 0.0).toDouble(),
      netAmount: (map['netAmount'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      failureReason: map['failureReason'],
      refundStatus: map['refundStatus'] ?? 'none',
      refundAmount: (map['refundAmount'] ?? 0.0).toDouble(),
      refundedAt: (map['refundedAt'] as Timestamp?)?.toDate(),
      idempotencyKey: map['idempotencyKey'] ?? '',
      redirectUrl: map['redirectUrl'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  bool get isSuccessful => status == 'successful';
  bool get isPending => status == 'pending' || status == 'processing';
  bool get isFailed => status == 'failed';
}
