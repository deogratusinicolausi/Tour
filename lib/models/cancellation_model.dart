import 'package:cloud_firestore/cloud_firestore.dart';

class CancellationModel {
  final String id;
  final String bookingId;
  final String userId;
  final String userName;
  final String userEmail;
  final String itemId;
  final String itemType;
  final String itemName;
  final String itemImage;
  final double bookingAmount;
  final double refundAmount;
  final String currency;
  final String reason;
  final String additionalNotes;
  final String status;
  final String adminNotes;
  final String rejectionReason;
  final DateTime? requestedAt;
  final DateTime? reviewedAt;
  final DateTime? refundedAt;
  final DateTime? createdAt;

  CancellationModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.userName,
    this.userEmail = '',
    this.itemId = '',
    this.itemType = '',
    this.itemName = '',
    this.itemImage = '',
    required this.bookingAmount,
    required this.refundAmount,
    this.currency = 'USD',
    required this.reason,
    this.additionalNotes = '',
    this.status = 'pending',
    this.adminNotes = '',
    this.rejectionReason = '',
    this.requestedAt,
    this.reviewedAt,
    this.refundedAt,
    this.createdAt,
  });

  factory CancellationModel.fromMap(Map<String, dynamic> map, String id) {
    return CancellationModel(
      id: id,
      bookingId: map['bookingId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      itemId: map['itemId'] ?? '',
      itemType: map['itemType'] ?? '',
      itemName: map['itemName'] ?? '',
      itemImage: map['itemImage'] ?? '',
      bookingAmount: (map['bookingAmount'] ?? 0.0).toDouble(),
      refundAmount: (map['refundAmount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      reason: map['reason'] ?? '',
      additionalNotes: map['additionalNotes'] ?? '',
      status: map['status'] ?? 'pending',
      adminNotes: map['adminNotes'] ?? '',
      rejectionReason: map['rejectionReason'] ?? '',
      requestedAt: (map['requestedAt'] as Timestamp?)?.toDate(),
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
      refundedAt: (map['refundedAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
      'status': status,
      'adminNotes': adminNotes,
      'rejectionReason': rejectionReason,
      'requestedAt': requestedAt ?? FieldValue.serverTimestamp(),
      'reviewedAt':
      reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'refundedAt':
      refundedAt != null ? Timestamp.fromDate(refundedAt!) : null,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
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

  int get refundPercentage {
    if (bookingAmount == 0) return 0;
    return ((refundAmount / bookingAmount) * 100).round();
  }

  String get reasonText {
    switch (reason) {
      case 'change_plans':
        return '🔄 Change of plans';
      case 'emergency':
        return '🚨 Emergency';
      case 'found_cheaper':
        return '💰 Found cheaper option';
      case 'weather':
        return '🌧️ Weather concerns';
      case 'health':
        return '🏥 Health issues';
      case 'other':
        return '📝 Other reason';
      default:
        return reason;
    }
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return '⏳ Pending Review';
      case 'approved':
        return '✅ Approved';
      case 'rejected':
        return '❌ Rejected';
      case 'refunded':
        return '💰 Refunded';
      default:
        return status;
    }
  }
}