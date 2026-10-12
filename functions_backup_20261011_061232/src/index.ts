import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import * as dotenv from 'dotenv';
import { PaymentService } from './services/payment_service';
import { IdempotencyService } from './services/idempotency_service';
import { PesaPalConfig } from './config/pesapal_config';

dotenv.config();

admin.initializeApp();

const paymentService = new PaymentService();
const idempotencyService = new IdempotencyService();
const db = admin.firestore();

// ═══════════════════════════════════════════
// ⭐ INITIATE PAYMENT
// ═══════════════════════════════════════════
export const initiatePayment = functions
  .region('us-central1')
  .https.onCall(async (data: any, context: functions.https.CallableContext) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
      }

      const userId = context.auth.uid;
      const {
        bookingId,
        paymentMethod,
        paymentNetwork,
        phoneNumber,
        amount,
        currency,
        idempotencyKey,
      } = data;

      console.log('📥 initiatePayment:', { bookingId, paymentMethod, paymentNetwork, amount, currency });

      if (!bookingId || !paymentMethod || !amount || !currency) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
      }

      if (amount <= 0) {
        throw new functions.https.HttpsError('invalid-argument', 'Amount must be positive');
      }

      const existingResult = await idempotencyService.checkKey(idempotencyKey);
      if (existingResult) {
        console.log('♻️ Idempotency — returning existing');
        return existingResult;
      }

      const bookingDoc = await db.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Booking not found');
      }

      const bookingData = bookingDoc.data()!;
      if (bookingData.userId !== userId) {
        throw new functions.https.HttpsError('permission-denied', 'Booking does not belong to user');
      }

      const expectedAmount = bookingData.finalAmount || bookingData.amount;
      if (Math.abs(expectedAmount - amount) > 1) {
        throw new functions.https.HttpsError('invalid-argument', `Amount mismatch`);
      }

      const transactionRef = db.collection('payment_transactions').doc();
      const transactionId = transactionRef.id;

      await transactionRef.set({
        bookingId,
        userId,
        userName: bookingData.userName,
        userEmail: bookingData.userEmail,
        userPhone: phoneNumber,
        paymentMethod,
        paymentNetwork,
        currency,
        amount,
        baseAmount: amount,
        status: 'pending',
        provider: 'pesapal',
        idempotencyKey,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 15 * 60 * 1000)),
      });

      const result = await paymentService.initiatePayment('pesapal', {
        transactionId,
        amount,
        currency,
        paymentMethod,
        paymentNetwork,
        phoneNumber,
        customerName: bookingData.userName || 'Customer',
        customerEmail: bookingData.userEmail || '',
        description: `TURIVA Booking: ${bookingData.itemName}`,
        callbackUrl: PesaPalConfig.callbackUrl,
      });

      console.log('📤 PesaPal response:', result);

      if (result.success && result.providerTransactionId) {
        await transactionRef.update({
          providerTransactionId: result.providerTransactionId,
          providerReference: result.providerReference || '',
          providerStatus: result.providerStatus || 'pending',
          redirectUrl: result.redirectUrl || '',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        await transactionRef.update({
          status: 'failed',
          failureReason: result.message || 'Initiation failed',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      await idempotencyService.saveKey(idempotencyKey, result);

      return {
        success: result.success,
        transactionId,
        providerTransactionId: result.providerTransactionId,
        redirectUrl: result.redirectUrl,
        message: result.message,
        error: result.success ? null : result.message,
      };
    } catch (error: any) {
      console.error('🔥 initiatePayment error:', error);
      throw new functions.https.HttpsError('internal', error.message || 'Payment initiation failed');
    }
  });

// ═══════════════════════════════════════════
// ⭐ VERIFY PAYMENT
// ═══════════════════════════════════════════
export const verifyPayment = functions
  .region('us-central1')
  .https.onCall(async (data: any, context: functions.https.CallableContext) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Login required');
      }

      const { transactionId } = data;
      if (!transactionId) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing transactionId');
      }

      const doc = await db.collection('payment_transactions').doc(transactionId).get();
      if (!doc.exists) {
        throw new functions.https.HttpsError('not-found', 'Transaction not found');
      }

      const transaction = doc.data()!;
      if (transaction.userId !== context.auth.uid) {
        throw new functions.https.HttpsError('permission-denied', 'Not your transaction');
      }

      const result = await paymentService.verifyPayment('pesapal', transaction.providerTransactionId);

      const provider = paymentService.getProvider('pesapal');
      const normalizedStatus = provider
        ? provider.normalizeStatus(result.providerStatus || '')
        : 'pending';

      if (normalizedStatus !== transaction.status) {
        await db.collection('payment_transactions').doc(transactionId).update({
          status: normalizedStatus,
          providerStatus: result.providerStatus || '',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          ...(normalizedStatus === 'successful' && {
            paidAt: admin.firestore.FieldValue.serverTimestamp(),
          }),
        });

        if (normalizedStatus === 'successful') {
          await db.collection('bookings').doc(transaction.bookingId).update({
            paymentStatus: 'successful',
            bookingStatus: 'confirmed',
            paymentTransactionId: transactionId,
            paidAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }

      return {
        success: true,
        transactionId,
        status: normalizedStatus,
        providerStatus: result.providerStatus,
      };
    } catch (error: any) {
      console.error('🔥 verifyPayment error:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  });

// ═══════════════════════════════════════════
// ⭐ PESAPAL IPN (Webhook)
// ═══════════════════════════════════════════
export const pesapalIPN = functions
  .region('us-central1')
  .https.onRequest(async (req, res) => {
    try {
      console.log('📥 PesaPal IPN received:', {
        method: req.method,
        body: req.body,
        query: req.query,
      });

      const OrderTrackingId = req.query.OrderTrackingId as string;
      const OrderMerchantReference = req.query.OrderMerchantReference as string;
      const OrderNotificationType = req.query.OrderNotificationType as string;

      console.log('📥 IPN params:', {
        OrderTrackingId,
        OrderMerchantReference,
        OrderNotificationType,
      });

      if (!OrderTrackingId) {
        res.status(400).send('Missing OrderTrackingId');
        return;
      }

      await db.collection('payment_webhooks').add({
        provider: 'pesapal',
        payload: req.query,
        headers: req.headers,
        receivedAt: admin.firestore.FieldValue.serverTimestamp(),
        processed: false,
      });

      const result = await paymentService.verifyPayment('pesapal', OrderTrackingId);
      console.log('✅ PesaPal verify result:', result);

      const transactionsSnap = await db
        .collection('payment_transactions')
        .where('providerTransactionId', '==', OrderTrackingId)
        .limit(1)
        .get();

      if (transactionsSnap.empty) {
        console.error('❌ Transaction not found:', OrderTrackingId);
        res.status(404).send('Transaction not found');
        return;
      }

      const transactionDoc = transactionsSnap.docs[0];
      const transaction = transactionDoc.data();

      const provider = paymentService.getProvider('pesapal');
      const normalizedStatus = provider
        ? provider.normalizeStatus(result.providerStatus || '')
        : 'pending';

      await transactionDoc.ref.update({
        status: normalizedStatus,
        providerStatus: result.providerStatus || '',
        providerReference: result.providerReference || transaction.providerReference,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        ...(normalizedStatus === 'successful' && {
          paidAt: admin.firestore.FieldValue.serverTimestamp(),
        }),
      });

      if (normalizedStatus === 'successful') {
        await db.collection('bookings').doc(transaction.bookingId).update({
          paymentStatus: 'successful',
          bookingStatus: 'confirmed',
          paymentTransactionId: transactionDoc.id,
          paidAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        await db.collection('notifications').add({
          userId: transaction.userId,
          title: '✅ Payment Successful!',
          body: `Your payment for ${transaction.currency} ${transaction.amount} has been confirmed.`,
          type: 'payment',
          category: 'success',
          icon: '✅',
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      await db.collection('payment_webhooks').add({
        provider: 'pesapal',
        payload: req.query,
        processed: true,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      res.status(200).send('OK');
    } catch (error: any) {
      console.error('🔥 IPN error:', error);
      res.status(500).send('Error');
    }
  });

// ═══════════════════════════════════════════
// ⭐ GET SUPPORTED PROVIDERS
// ═══════════════════════════════════════════
export const getSupportedProviders = functions
  .region('us-central1')
  .https.onCall(async (data: any, context: functions.https.CallableContext) => {
    return {
      providers: paymentService.getAvailableProviders(),
      methods: {
        mobile_money: ['mpesa', 'airtel', 'tigo', 'halotel'],
        card: ['visa', 'mastercard'],
      },
      currencies: ['TZS', 'USD', 'EUR', 'GBP'],
      environment: PesaPalConfig.environment,
    };
  });

// ═══════════════════════════════════════════
// ⭐ REQUEST REFUND
// ═══════════════════════════════════════════
export const requestRefund = functions
  .region('us-central1')
  .https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Login required');
    }
    return { success: false, message: 'Refund feature coming soon' };
  });
