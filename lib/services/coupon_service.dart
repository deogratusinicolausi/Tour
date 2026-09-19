import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coupon_model.dart';

class CouponService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ Get all active coupons
  Stream<List<CouponModel>> getActiveCoupons() {
    return _firestore
        .collection('coupons')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CouponModel.fromMap(doc.data(), doc.id))
          .where((c) => c.isValid)
          .toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // ⭐️ Get featured coupons (active + expiring soon)
  Stream<List<CouponModel>> getFeaturedCoupons() {
    return _firestore
        .collection('coupons')
        .where('isActive', isEqualTo: true)
        .limit(5)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CouponModel.fromMap(doc.data(), doc.id))
          .where((c) => c.isValid)
          .toList();
      return list;
    });
  }

  // ⭐️ Validate coupon
  Future<Map<String, dynamic>> validateCoupon({
    required String code,
    required double amount,
    required String userId,
    required String itemType,
  }) async {
    try {
      // Find coupon
      final snapshot = await _firestore
          .collection('coupons')
          .where('code', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'valid': false,
          'message': '❌ Invalid coupon code',
        };
      }

      final coupon = CouponModel.fromMap(
          snapshot.docs.first.data(), snapshot.docs.first.id);

      // Check if active
      if (!coupon.isActive) {
        return {
          'valid': false,
          'message': '❌ This coupon is no longer active',
        };
      }

      // Check if valid (dates)
      if (!coupon.isValid) {
        return {
          'valid': false,
          'message': '❌ This coupon has expired',
        };
      }

      // Check user already used
      if (coupon.perUserLimit > 0 && coupon.userUsed(userId)) {
        return {
          'valid': false,
          'message': '❌ You have already used this coupon',
        };
      }

      // Check usage limit
      if (coupon.usageLimit > 0 && coupon.usedCount >= coupon.usageLimit) {
        return {
          'valid': false,
          'message': '❌ This coupon has reached its usage limit',
        };
      }

      // Check minimum amount
      if (coupon.minAmount > 0 && amount < coupon.minAmount) {
        return {
          'valid': false,
          'message':
          '❌ Minimum purchase required: ${coupon.currency} ${coupon.minAmount.toStringAsFixed(0)}',
        };
      }

      // Check applicable items
      if (coupon.applicableTo != 'all' &&
          coupon.applicableTo != itemType) {
        return {
          'valid': false,
          'message': '❌ This coupon is not valid for ${itemType}s',
        };
      }

      // Calculate discount
      final discount = coupon.calculateDiscount(amount);

      return {
        'valid': true,
        'coupon': coupon,
        'discount': discount,
        'message': '✅ Coupon applied! You save ${coupon.currency} ${discount.toStringAsFixed(0)}',
      };
    } catch (e) {
      print('🔥 Error validating coupon: $e');
      return {
        'valid': false,
        'message': '❌ Error validating coupon',
      };
    }
  }

  // ⭐️ Apply coupon (mark as used)
  Future<bool> applyCoupon({
    required String couponId,
    required String userId,
  }) async {
    try {
      final ref = _firestore.collection('coupons').doc(couponId);
      final doc = await ref.get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      final usedBy = List<String>.from(data['usedBy'] ?? []);
      final usedCount = data['usedCount'] ?? 0;

      if (!usedBy.contains(userId)) {
        usedBy.add(userId);
      }

      await ref.update({
        'usedBy': usedBy,
        'usedCount': usedCount + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log activity
      await _firestore.collection('activities').add({
        'type': 'coupon',
        'action': 'used',
        'title': 'Coupon Used: ${data['code']}',
        'description': 'User applied coupon ${data['code']}',
        'userId': userId,
        'itemId': couponId,
        'itemType': 'coupon',
        'icon': '🎫',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('🔥 Error applying coupon: $e');
      return false;
    }
  }

  // ⭐️ Get user's used coupons
  Stream<List<CouponModel>> getUserUsedCoupons(String userId) {
    return _firestore
        .collection('coupons')
        .where('usedBy', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => CouponModel.fromMap(doc.data(), doc.id))
        .toList());
  }
}