import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/payment_transaction_model.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
}
