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

export const initiatePayment = functions
  .region('us-central1')
  .https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
    const userId = context.auth.uid;
    const { bookingId, paymentMethod, paymentNetwork, phoneNumber, amount, currency, idempotencyKey } = data;

    console.log('📥 initiatePayment:', { bookingId, paymentMethod, amount, currency });

    const existing = await idempotencyService.checkKey(idempotencyKey);
    if (existing) return existing;

    const bookingDoc = await db.collection('bookings').doc(bookingId).get();
    if (!bookingDoc.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');
    const bookingData = bookingDoc.data()!;

    const transactionRef = db.collection('payment_transactions').doc();
    const transactionId = transactionRef.id;

    await transactionRef.set({
      bookingId, userId, userName: bookingData.userName, userEmail: bookingData.userEmail,
      userPhone: phoneNumber, paymentMethod, paymentNetwork, currency, amount,
      status: 'pending', provider: 'pesapal', idempotencyKey,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const result = await paymentService.initiatePayment('pesapal', {
      transactionId, amount, currency, paymentMethod, paymentNetwork, phoneNumber,
      customerName: bookingData.userName || 'Customer',
      customerEmail: bookingData.userEmail || '',
      description: `TURIVA Booking: ${bookingData.itemName}`,
      callbackUrl: PesaPalConfig.callbackUrl,
    });

    console.log('📤 PesaPal response:', result);

    if (result.success && result.providerTransactionId) {
      await transactionRef.update({
        providerTransactionId: result.providerTransactionId,
        providerStatus: result.providerStatus,
        redirectUrl: result.redirectUrl,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await idempotencyService.saveKey(idempotencyKey, result);

    return {
      success: result.success,
      transactionId,
      redirectUrl: result.redirectUrl,
      message: result.message,
    };
  });

export const verifyPayment = functions
  .region('us-central1')
  .https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
    const doc = await db.collection('payment_transactions').doc(data.transactionId).get();
    if (!doc.exists) throw new functions.https.HttpsError('not-found', 'Not found');
    const t = doc.data()!;
    const result = await paymentService.verifyPayment('pesapal', t.providerTransactionId);
    return { success: true, status: result.providerStatus };
  });

export const pesapalIPN = functions
  .region('us-central1')
  .https.onRequest(async (req: any, res: any) => {
    console.log('📥 IPN:', req.query);
    const OrderTrackingId = req.query.OrderTrackingId as string;
    if (!OrderTrackingId) { res.status(400).send('Missing ID'); return; }

    const result = await paymentService.verifyPayment('pesapal', OrderTrackingId);
    const snaps = await db.collection('payment_transactions')
      .where('providerTransactionId', '==', OrderTrackingId).limit(1).get();

    if (!snaps.empty) {
      const txn = snaps.docs[0];
      const t = txn.data();
      const provider = paymentService.getProvider('pesapal');
      const status = provider ? provider.normalizeStatus(result.providerStatus || '') : 'pending';

      await txn.ref.update({ status, providerStatus: result.providerStatus, updatedAt: admin.firestore.FieldValue.serverTimestamp() });

      if (status === 'successful') {
        await db.collection('bookings').doc(t.bookingId).update({
          paymentStatus: 'successful', bookingStatus: 'confirmed',
          paymentTransactionId: txn.id, paidAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }
    res.status(200).send('OK');
  });

export const getSupportedProviders = functions
  .region('us-central1')
  .https.onCall(async () => {
    return {
      providers: paymentService.getAvailableProviders(),
      methods: { mobile_money: ['mpesa', 'airtel', 'tigo', 'halotel'], card: ['visa', 'mastercard'] },
      currencies: ['TZS', 'USD', 'EUR', 'GBP'],
    };
  });

export const requestRefund = functions
  .region('us-central1')
  .https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
    return { success: false, message: 'Coming soon' };
  });
