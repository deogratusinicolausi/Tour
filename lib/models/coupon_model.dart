import 'package:cloud_firestore/cloud_firestore.dart';

class CouponModel {
  final String id;
  final String code;
  final String title;
  final String description;
  final String discountType; // percentage, fixed
  final double discountValue;
  final double minAmount;
  final double maxDiscount;
  final String currency;
  final String applicableTo;
  final List<String> applicableItems;
  final int usageLimit;
  final int usedCount;
  final int perUserLimit;
  final List<String> usedBy;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final String bannerImage;
  final String termsAndConditions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CouponModel({
    required this.id,
    required this.code,
    required this.title,
    this.description = '',
    this.discountType = 'percentage',
    required this.discountValue,
    this.minAmount = 0.0,
    this.maxDiscount = 0.0,
    this.currency = 'USD',
    this.applicableTo = 'all',
    this.applicableItems = const [],
    this.usageLimit = 0,
    this.usedCount = 0,
    this.perUserLimit = 1,
    this.usedBy = const [],
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.bannerImage = '',
    this.termsAndConditions = '',
    this.createdAt,
    this.updatedAt,
  });

  factory CouponModel.fromMap(Map<String, dynamic> map, String id) {
    return CouponModel(
      id: id,
      code: map['code'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      discountType: map['discountType'] ?? 'percentage',
      discountValue: (map['discountValue'] ?? 0.0).toDouble(),
      minAmount: (map['minAmount'] ?? 0.0).toDouble(),
      maxDiscount: (map['maxDiscount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      applicableTo: map['applicableTo'] ?? 'all',
      applicableItems: List<String>.from(map['applicableItems'] ?? []),
      usageLimit: map['usageLimit'] ?? 0,
      usedCount: map['usedCount'] ?? 0,
      perUserLimit: map['perUserLimit'] ?? 1,
      usedBy: List<String>.from(map['usedBy'] ?? []),
      startDate: (map['startDate'] as Timestamp?)?.toDate(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] ?? true,
      bannerImage: map['bannerImage'] ?? '',
      termsAndConditions: map['termsAndConditions'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  double calculateDiscount(double amount) {
    if (amount < minAmount) return 0;
    double discount = 0;
    if (discountType == 'percentage') {
      discount = amount * (discountValue / 100);
      if (maxDiscount > 0 && discount > maxDiscount) {
        discount = maxDiscount;
      }
    } else {
      discount = discountValue;
      if (discount > amount) discount = amount;
    }
    return discount;
  }

  bool get isValid {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    if (usageLimit > 0 && usedCount >= usageLimit) return false;
    return true;
  }

  bool userUsed(String userId) => usedBy.contains(userId);

  bool canUserUse(String userId) {
    if (perUserLimit == 0) return true;
    return !usedBy.contains(userId);
  }

  String get discountDisplay {
    if (discountType == 'percentage') {
      return '${discountValue.toStringAsFixed(0)}% OFF';
    }
    return '$currency ${discountValue.toStringAsFixed(0)} OFF';
  }

  String get expiryText {
    if (endDate == null) return 'No expiry';
    final diff = endDate!.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays < 1) return 'Ends in ${diff.inHours}h';
    if (diff.inDays < 7) return 'Ends in ${diff.inDays}d';
    return 'Ends in ${diff.inDays ~/ 7}w';
  }

  int get daysLeft {
    if (endDate == null) return 999;
    final diff = endDate!.difference(DateTime.now());
    return diff.inDays;
  }
}