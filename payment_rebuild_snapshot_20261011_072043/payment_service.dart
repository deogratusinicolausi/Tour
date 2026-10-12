
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../backup_payment_20261011/payment_transaction_model.dart';

class PaymentService {
  PaymentService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1'),
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

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
        return {
          'success': false,
          'error': 'Please sign in before making a payment.',
        };
      }

      if (bookingId.trim().isEmpty) {
        return {
          'success': false,
          'error': 'A valid booking ID is required.',
        };
      }

      if (amount <= 0 || !amount.isFinite) {
        return {
          'success': false,
          'error': 'The payment amount must be greater than zero.',
        };
      }

      if (currency.trim().isEmpty) {
        return {
          'success': false,
          'error': 'A valid currency is required.',
        };
      }

      if (paymentMethod == 'mobile_money' &&
          phoneNumber.trim().isEmpty) {
        return {
          'success': false,
          'error': 'Enter a phone number for mobile money.',
        };
      }

      final callable =
      _functions.httpsCallable('initiatePayment');

      final result = await callable.call({
        'bookingId': bookingId.trim(),
        'paymentMethod': paymentMethod,
        'paymentNetwork': paymentNetwork,
        'phoneNumber': phoneNumber.trim(),
        'amount': amount,
        'currency': currency.trim().toUpperCase(),
      });

      final data = result.data;

      if (data is! Map) {
        return {
          'success': false,
          'error': 'The payment server returned an invalid response.',
        };
      }

      return Map<String, dynamic>.from(data);
    } on FirebaseFunctionsException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'The payment request failed.',
        'code': e.code,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Authentication failed.',
        'code': e.code,
      };
    } catch (e) {
      // Log the technical error for development.
      // Avoid displaying raw internal errors to customers.
      print('Payment initiation error: $e');

      return {
        'success': false,
        'error': 'Unable to start the payment. Please try again.',
      };
    }
  }

  Stream<PaymentTransactionModel?> getTransaction(
      String transactionId,
      ) {
    return _firestore
        .collection('payment_transactions')
        .doc(transactionId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return null;
      }

      final data = doc.data();

      if (data == null) {
        return null;
      }

      return PaymentTransactionModel.fromMap(
        data,
        doc.id,
      );
    });
  }
}
