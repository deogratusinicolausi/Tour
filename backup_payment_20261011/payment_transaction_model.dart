import 'package:cloud_firestore/cloud_firestore.dart';

/// ⭐ TURIVA Payment Transaction Model
/// Inahifadhi transaction records kutoka payment providers
class PaymentTransactionModel {
  final String transactionId;             // TURIVA internal ID
  final String bookingId;                 // Reference to booking
  final String orderId;                   // For bulk orders
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;

  // ⭐ Provider Info
  final String provider;                  // clickpesa, azampay, flutterwave
  final String providerTransactionId;
  final String providerReference;
  final String providerStatus;

  // ⭐ Payment Method
  final String paymentMethod;             // mobile_money, card, cash
  final String paymentNetwork;            // mpesa, airtel, tigo, halotel, visa, mastercard
  final String maskedAccount;

  // ⭐ Financial
  final String currency;
  final double amount;
  final double fees;
  final double netAmount;
  final double baseAmount;
  final double taxAmount;

  // ⭐ Status (SEPARATE from booking status)
  final String status;                    // pending, processing, successful, failed, cancelled, expired, refunded, partially_refunded
  final String? failureReason;

  // ⭐ Refund
  final String refundStatus;              // none, requested, processing, completed, failed
  final double refundAmount;
  final DateTime? refundedAt;

  // ⭐ Idempotency
  final String idempotencyKey;

  // ⭐ Timestamps
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? paidAt;
  final DateTime? expiresAt;

  // ⭐ Metadata
  final Map<String, dynamic> metadata;

  PaymentTransactionModel({
    required this.transactionId,
    required this.bookingId,
    this.orderId = '',
    required this.userId,
    this.userName = '',
    this.userEmail = '',
    this.userPhone = '',
    this.provider = 'pending',
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
    this.baseAmount = 0.0,
    this.taxAmount = 0.0,
    this.status = 'pending',
    this.failureReason,
    this.refundStatus = 'none',
    this.refundAmount = 0.0,
    this.refundedAt,
    this.idempotencyKey = '',
    required this.createdAt,
    this.updatedAt,
    this.paidAt,
    this.expiresAt,
    this.metadata = const {},
  });

  factory PaymentTransactionModel.fromMap(
      Map<String, dynamic> map, String id) {
    return PaymentTransactionModel(
      transactionId: id,
      bookingId: map['bookingId'] ?? '',
      orderId: map['orderId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userPhone: map['userPhone'] ?? '',
      provider: map['provider'] ?? 'pending',
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
      baseAmount: (map['baseAmount'] ?? 0.0).toDouble(),
      taxAmount: (map['taxAmount'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      failureReason: map['failureReason'],
      refundStatus: map['refundStatus'] ?? 'none',
      refundAmount: (map['refundAmount'] ?? 0.0).toDouble(),
      refundedAt: (map['refundedAt'] as Timestamp?)?.toDate(),
      idempotencyKey: map['idempotencyKey'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'orderId': orderId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'provider': provider,
      'providerTransactionId': providerTransactionId,
      'providerReference': providerReference,
      'providerStatus': providerStatus,
      'paymentMethod': paymentMethod,
      'paymentNetwork': paymentNetwork,
      'maskedAccount': maskedAccount,
      'currency': currency,
      'amount': amount,
      'fees': fees,
      'netAmount': netAmount,
      'baseAmount': baseAmount,
      'taxAmount': taxAmount,
      'status': status,
      'failureReason': failureReason,
      'refundStatus': refundStatus,
      'refundAmount': refundAmount,
      'refundedAt': refundedAt != null ? Timestamp.fromDate(refundedAt!) : null,
      'idempotencyKey': idempotencyKey,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'metadata': metadata,
    };
  }

  // ⭐ Helpers
  bool get isSuccessful => status == 'successful';
  bool get isPending => status == 'pending' || status == 'processing';
  bool get isFailed => status == 'failed';
  bool get isRefunded => refundStatus == 'completed';
  bool get canRefund => isSuccessful && refundStatus == 'none';
  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
}
