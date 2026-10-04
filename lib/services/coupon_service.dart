import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coupon_model.dart';

class CouponService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ Get all active coupons (real-time)
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

  // ⭐️ Get featured coupons (active + limited)
  Stream<List<CouponModel>> getFeaturedCoupons() {
    return _firestore
        .collection('coupons')
        .where('isActive', isEqualTo: true)
        .limit(5)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CouponModel.fromMap(doc.data(), doc.id))
          .where((c) => c.isValid)
          .toList();
    });
  }

  // ⭐️ NEW: Get one coupon by ID
  Future<CouponModel?> getCoupon(String id) async {
    try {
      final doc = await _firestore.collection('coupons').doc(id).get();
      if (!doc.exists) return null;
      return CouponModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('🔥 Error getting coupon: $e');
      return null;
    }
  }

  // ⭐️ Find coupon by code (used internally)
  Future<CouponModel?> _findByCode(String code) async {
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty) return null;

    final snapshot = await _firestore
        .collection('coupons')
        .where('code', isEqualTo: clean)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return CouponModel.fromMap(
        snapshot.docs.first.data(), snapshot.docs.first.id);
  }

  // ⭐️ Validate coupon (FIXED — trims whitespace, safer checks)
  Future<Map<String, dynamic>> validateCoupon({
    required String code,
    required double amount,
    required String userId,
    required String itemType,
  }) async {
    try {
      // 1. Find coupon
      final coupon = await _findByCode(code);
      if (coupon == null) {
        return {
          'valid': false,
          'message': '❌ Invalid coupon code',
        };
      }

      // 2. Active
      if (!coupon.isActive) {
        return {
          'valid': false,
          'message': '❌ This coupon is no longer active',
        };
      }

      // 3. Date valid
      if (!coupon.isValid) {
        return {
          'valid': false,
          'message': '❌ This coupon has expired',
        };
      }

      // 4. User already used
      if (coupon.perUserLimit > 0 && coupon.userUsed(userId)) {
        return {
          'valid': false,
          'message': '❌ You have already used this coupon',
        };
      }

      // 5. Global usage limit
      if (coupon.usageLimit > 0 &&
          coupon.usedCount >= coupon.usageLimit) {
        return {
          'valid': false,
          'message': '❌ This coupon has reached its usage limit',
        };
      }

      // 6. Minimum amount
      if (coupon.minAmount > 0 && amount < coupon.minAmount) {
        return {
          'valid': false,
          'message':
          '❌ Minimum purchase required: ${coupon.currency} ${coupon.minAmount.toStringAsFixed(0)}',
        };
      }

      // 7. Applicable items
      if (coupon.applicableTo != 'all' &&
          coupon.applicableTo != itemType) {
        return {
          'valid': false,
          'message': '❌ This coupon is not valid for ${itemType}s',
        };
      }

      // 8. Calculate discount
      final discount = coupon.calculateDiscount(amount);

      return {
        'valid': true,
        'coupon': coupon,
        'discount': discount,
        'message':
        '✅ Coupon applied! You save ${coupon.currency} ${discount.toStringAsFixed(0)}',
      };
    } catch (e) {
      print('🔥 Error validating coupon: $e');
      return {
        'valid': false,
        'message': '❌ Error validating coupon',
      };
    }
  }

  // ⭐️ Apply coupon (FIXED — prevents double-increment)
  Future<bool> applyCoupon({
    required String couponId,
    required String userId,
  }) async {
    try {
      final ref = _firestore.collection('coupons').doc(couponId);

      // Use a transaction to avoid race conditions
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(ref);
        if (!doc.exists) throw Exception('Coupon not found');

        final data = doc.data()!;
        final usedBy = List<String>.from(data['usedBy'] ?? []);
        final usedCount = (data['usedCount'] ?? 0) as int;

        // 🛑 Already used by this user → do nothing (safe)
        if (usedBy.contains(userId)) return;

        usedBy.add(userId);

        transaction.update(ref, {
          'usedBy': usedBy,
          'usedCount': usedCount + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Log activity (outside transaction — non-critical)
      try {
        final doc = await ref.get();
        final code = (doc.data()?['code'] ?? '').toString();

        await _firestore.collection('activities').add({
          'type': 'coupon',
          'action': 'used',
          'title': 'Coupon Used: $code',
          'description': 'User applied coupon $code',
          'userId': userId,
          'itemId': couponId,
          'itemType': 'coupon',
          'icon': '🎫',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      return true;
    } catch (e) {
      print('🔥 Error applying coupon: $e');
      return false;
    }
  }

  // ⭐️ Get user's used coupons (real-time, safer)
  Stream<List<CouponModel>> getUserUsedCoupons(String userId) {
    return _firestore
        .collection('coupons')
        .where('usedBy', arrayContains: userId)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => CouponModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // ⭐️ NEW: Count available coupons for badge
  Stream<int> getAvailableCouponsCount(String userId) {
    return _firestore
        .collection('coupons')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final active = snapshot.docs
          .map((d) => CouponModel.fromMap(d.data(), d.id))
          .where((c) => c.isValid && !c.userUsed(userId))
          .toList();
      return active.length;
    });
  }
}