import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/payment_transaction_model.dart';

/// ⭐ TURIVA Payment Service
/// Client-side wrapper — inaita Cloud Functions kwa payment operations
/// ⚠️ HAKUNA secret keys hapa — zote ziko server-side
class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ═══════════════════════════════════════════
  // ⭐ INITIATE PAYMENT
  // ═══════════════════════════════════════════
  Future<Map<String, dynamic>?> initiatePayment({
    required String bookingId,
    required String paymentMethod,
    required String paymentNetwork,
    required String phoneNumber,
    required double amount,
    required String currency,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      // ⭐ Generate idempotency key (unique per booking + user)
      final idempotencyKey =
          '${user.uid}_${bookingId}_${DateTime.now().millisecondsSinceEpoch}';

      final callable = _functions.httpsCallable('initiatePayment');
      final result = await callable.call({
        'bookingId': bookingId,
        'paymentMethod': paymentMethod,
        'paymentNetwork': paymentNetwork,
        'phoneNumber': phoneNumber,
        'amount': amount,
        'currency': currency,
        'idempotencyKey': idempotencyKey,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      print('🔥 initiatePayment error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ═══════════════════════════════════════════
  // ⭐ VERIFY PAYMENT
  // ═══════════════════════════════════════════
  Future<Map<String, dynamic>?> verifyPayment(String transactionId) async {
    try {
      final callable = _functions.httpsCallable('verifyPayment');
      final result = await callable.call({'transactionId': transactionId});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      print('🔥 verifyPayment error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════
  // ⭐ GET TRANSACTION (Real-time)
  // ═══════════════════════════════════════════
  Stream<PaymentTransactionModel?> getTransaction(String transactionId) {
    return _firestore
        .collection('payment_transactions')
        .doc(transactionId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return PaymentTransactionModel.fromMap(
          doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  // ═══════════════════════════════════════════
  // ⭐ GET USER TRANSACTIONS
  // ═══════════════════════════════════════════
  Stream<List<PaymentTransactionModel>> getUserTransactions() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('payment_transactions')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => PaymentTransactionModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
      return list;
    });
  }

  // ═══════════════════════════════════════════
  // ⭐ REQUEST REFUND
  // ═══════════════════════════════════════════
  Future<Map<String, dynamic>?> requestRefund({
    required String transactionId,
    required String reason,
    double? amount,
  }) async {
    try {
      final callable = _functions.httpsCallable('requestRefund');
      final result = await callable.call({
        'transactionId': transactionId,
        'reason': reason,
        'amount': amount,
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      print('🔥 requestRefund error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════
  // ⭐ GET SUPPORTED PROVIDERS
  // ═══════════════════════════════════════════
  Future<Map<String, dynamic>?> getSupportedProviders() async {
    try {
      final callable = _functions.httpsCallable('getSupportedProviders');
      final result = await callable.call();
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      print('🔥 getSupportedProviders error: $e');
      return null;
    }
  }
}
