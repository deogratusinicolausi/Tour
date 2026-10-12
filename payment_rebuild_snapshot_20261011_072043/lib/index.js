"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.requestRefund = exports.getSupportedProviders = exports.pesapalIPN = exports.verifyPayment = exports.initiatePayment = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions"));
const dotenv = __importStar(require("dotenv"));
const payment_service_1 = require("./services/payment_service");
const idempotency_service_1 = require("./services/idempotency_service");
const pesapal_config_1 = require("./config/pesapal_config");
dotenv.config();
admin.initializeApp();
const paymentService = new payment_service_1.PaymentService();
const idempotencyService = new idempotency_service_1.IdempotencyService();
const db = admin.firestore();
exports.initiatePayment = functions
    .region('us-central1')
    .https.onCall(async (data, context) => {
    if (!context.auth)
        throw new functions.https.HttpsError('unauthenticated', 'Login required');
    const userId = context.auth.uid;
    const { bookingId, paymentMethod, paymentNetwork, phoneNumber, amount, currency, idempotencyKey } = data;
    console.log('📥 initiatePayment:', { bookingId, paymentMethod, amount, currency });
    const existing = await idempotencyService.checkKey(idempotencyKey);
    if (existing)
        return existing;
    const bookingDoc = await db.collection('bookings').doc(bookingId).get();
    if (!bookingDoc.exists)
        throw new functions.https.HttpsError('not-found', 'Booking not found');
    const bookingData = bookingDoc.data();
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
        callbackUrl: pesapal_config_1.PesaPalConfig.callbackUrl,
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
exports.verifyPayment = functions
    .region('us-central1')
    .https.onCall(async (data, context) => {
    if (!context.auth)
        throw new functions.https.HttpsError('unauthenticated', 'Login required');
    const doc = await db.collection('payment_transactions').doc(data.transactionId).get();
    if (!doc.exists)
        throw new functions.https.HttpsError('not-found', 'Not found');
    const t = doc.data();
    const result = await paymentService.verifyPayment('pesapal', t.providerTransactionId);
    return { success: true, status: result.providerStatus };
});
exports.pesapalIPN = functions
    .region('us-central1')
    .https.onRequest(async (req, res) => {
    console.log('📥 IPN:', req.query);
    const OrderTrackingId = req.query.OrderTrackingId;
    if (!OrderTrackingId) {
        res.status(400).send('Missing ID');
        return;
    }
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
exports.getSupportedProviders = functions
    .region('us-central1')
    .https.onCall(async () => {
    return {
        providers: paymentService.getAvailableProviders(),
        methods: { mobile_money: ['mpesa', 'airtel', 'tigo', 'halotel'], card: ['visa', 'mastercard'] },
        currencies: ['TZS', 'USD', 'EUR', 'GBP'],
    };
});
exports.requestRefund = functions
    .region('us-central1')
    .https.onCall(async (data, context) => {
    if (!context.auth)
        throw new functions.https.HttpsError('unauthenticated', 'Login required');
    return { success: false, message: 'Coming soon' };
});
//# sourceMappingURL=index.js.map