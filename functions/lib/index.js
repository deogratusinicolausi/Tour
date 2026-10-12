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
const pesapal_config_1 = require("./config/pesapal_config");
dotenv.config();
if (!admin.apps.length) {
    admin.initializeApp();
}
const paymentService = new payment_service_1.PaymentService();
const db = admin.firestore();
function requireString(value, field) {
    if (typeof value !== 'string' || !value.trim()) {
        throw new functions.https.HttpsError('invalid-argument', `${field} is required`);
    }
    return value.trim();
}
function normalizeNetwork(value) {
    const network = String(value || '')
        .toLowerCase()
        .replace(/[\s_-]/g, '');
    const aliases = {
        mpesa: 'mpesa',
        airtelmoney: 'airtel',
        airtel: 'airtel',
        tigopesa: 'tigo',
        tigo: 'tigo',
        halotel: 'halotel',
        visa: 'visa',
        mastercard: 'mastercard',
    };
    return aliases[network] || network;
}
function getVerifiedStatus(providerStatus) {
    const provider = paymentService.getProvider('pesapal');
    return provider
        ? provider.normalizeStatus(providerStatus)
        : 'pending';
}
async function applyVerifiedStatus(transactionId, status, providerStatus) {
    const transactionRef = db
        .collection('payment_transactions')
        .doc(transactionId);
    await db.runTransaction(async (firestoreTransaction) => {
        const transactionDoc = await firestoreTransaction.get(transactionRef);
        if (!transactionDoc.exists)
            return;
        const payment = transactionDoc.data();
        const bookingId = payment.bookingId;
        if (typeof bookingId !== 'string' || !bookingId)
            return;
        const bookingRef = db.collection('bookings').doc(bookingId);
        const bookingDoc = await firestoreTransaction.get(bookingRef);
        if (!bookingDoc.exists)
            return;
        // A confirmed payment must never be downgraded by a later callback.
        if (payment.status === 'successful')
            return;
        const timestamp = admin.firestore.FieldValue.serverTimestamp();
        firestoreTransaction.update(transactionRef, {
            status,
            providerStatus,
            verifiedAt: timestamp,
            updatedAt: timestamp,
        });
        const bookingUpdate = {
            paymentStatus: status,
            updatedAt: timestamp,
        };
        if (status === 'successful') {
            bookingUpdate.bookingStatus = 'confirmed';
            bookingUpdate.paymentTransactionId = transactionId;
            bookingUpdate.paidAt = timestamp;
        }
        firestoreTransaction.update(bookingRef, bookingUpdate);
    });
}
exports.initiatePayment = functions
    .region('us-central1')
    .https.onCall(async (data, context) => {
    var _a;
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Please sign in before paying.');
    }
    const userId = context.auth.uid;
    const bookingId = requireString(data === null || data === void 0 ? void 0 : data.bookingId, 'bookingId');
    const paymentMethod = String((data === null || data === void 0 ? void 0 : data.paymentMethod) || '')
        .trim()
        .toLowerCase();
    const paymentNetwork = normalizeNetwork(data === null || data === void 0 ? void 0 : data.paymentNetwork);
    const phoneNumber = String((data === null || data === void 0 ? void 0 : data.phoneNumber) || '').trim();
    if (!['mobile_money', 'card'].includes(paymentMethod)) {
        throw new functions.https.HttpsError('invalid-argument', 'Choose mobile money or card for online payment.');
    }
    if (!paymentService.getAvailableProviders().includes('pesapal')) {
        throw new functions.https.HttpsError('failed-precondition', 'PesaPal is not configured. Check the server environment.');
    }
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();
    if (!bookingDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Booking not found.');
    }
    const booking = bookingDoc.data();
    if (booking.userId !== userId) {
        throw new functions.https.HttpsError('permission-denied', 'You cannot pay for another user’s booking.');
    }
    if (booking.paymentStatus === 'successful') {
        throw new functions.https.HttpsError('failed-precondition', 'This booking has already been paid.');
    }
    // The server calculates the amount from the saved booking.
    const finalAmount = Number(booking.finalAmount);
    const originalAmount = Number(booking.amount);
    const amount = Number.isFinite(finalAmount) && finalAmount > 0
        ? finalAmount
        : originalAmount;
    const currency = String(booking.currency || '')
        .trim()
        .toUpperCase();
    if (!Number.isFinite(amount) || amount <= 0) {
        throw new functions.https.HttpsError('failed-precondition', 'The booking amount is invalid.');
    }
    if (!((_a = paymentService.getProvider('pesapal')) === null || _a === void 0 ? void 0 : _a.supportsCurrency(currency))) {
        throw new functions.https.HttpsError('invalid-argument', `Currency ${currency || '(missing)'} is not supported by this payment setup.`);
    }
    const provider = paymentService.getProvider('pesapal');
    if (!(provider === null || provider === void 0 ? void 0 : provider.supportsMethod(paymentMethod, paymentNetwork))) {
        throw new functions.https.HttpsError('invalid-argument', 'The selected payment method or network is not supported.');
    }
    if (paymentMethod === 'mobile_money' && !phoneNumber) {
        throw new functions.https.HttpsError('invalid-argument', 'A phone number is required for mobile money.');
    }
    // Reuse an existing active order instead of creating duplicate orders
    // when the customer taps Pay more than once.
    const previousTransactions = await db
        .collection('payment_transactions')
        .where('bookingId', '==', bookingId)
        .limit(20)
        .get();
    const previousPending = previousTransactions.docs.find((doc) => {
        const payment = doc.data();
        return payment.userId === userId &&
            payment.provider === 'pesapal' &&
            ['pending', 'processing'].includes(payment.status) &&
            typeof payment.providerTransactionId === 'string' &&
            typeof payment.redirectUrl === 'string' &&
            payment.redirectUrl.length > 0;
    });
    if (previousPending) {
        const payment = previousPending.data();
        return {
            success: true,
            transactionId: previousPending.id,
            redirectUrl: payment.redirectUrl,
            message: 'An existing payment order is awaiting completion.',
        };
    }
    const transactionRef = db
        .collection('payment_transactions')
        .doc();
    await transactionRef.set({
        bookingId,
        userId,
        userName: booking.userName || 'Customer',
        userEmail: booking.userEmail || '',
        userPhone: phoneNumber || booking.userPhone || '',
        paymentMethod,
        paymentNetwork,
        currency,
        amount,
        status: 'pending',
        provider: 'pesapal',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    try {
        const result = await paymentService.initiatePayment('pesapal', {
            transactionId: transactionRef.id,
            amount,
            currency,
            paymentMethod: paymentMethod,
            paymentNetwork,
            phoneNumber,
            customerName: booking.userName || 'Customer',
            customerEmail: booking.userEmail || '',
            description: `TURIVA Booking: ${booking.itemName || bookingId}`,
            callbackUrl: pesapal_config_1.PesaPalConfig.callbackUrl,
        });
        if (!result.success ||
            !result.providerTransactionId ||
            !result.redirectUrl) {
            await transactionRef.update({
                status: 'failed',
                errorMessage: result.message || 'PesaPal order creation failed.',
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            return {
                success: false,
                transactionId: transactionRef.id,
                message: result.message || 'Could not create the PesaPal payment order.',
            };
        }
        await transactionRef.update({
            providerTransactionId: result.providerTransactionId,
            providerReference: result.providerReference || '',
            providerStatus: result.providerStatus || 'pending',
            redirectUrl: result.redirectUrl,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return {
            success: true,
            transactionId: transactionRef.id,
            redirectUrl: result.redirectUrl,
            message: 'Payment order created. Complete payment on PesaPal.',
        };
    }
    catch (error) {
        await transactionRef.update({
            status: 'failed',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.error('Payment initiation failed:', error);
        throw new functions.https.HttpsError('internal', 'Unable to start payment. Please try again.');
    }
});
exports.verifyPayment = functions
    .region('us-central1')
    .https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Please sign in first.');
    }
    const transactionId = requireString(data === null || data === void 0 ? void 0 : data.transactionId, 'transactionId');
    const transactionRef = db
        .collection('payment_transactions')
        .doc(transactionId);
    const transactionDoc = await transactionRef.get();
    if (!transactionDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Payment transaction not found.');
    }
    const payment = transactionDoc.data();
    if (payment.userId !== context.auth.uid) {
        throw new functions.https.HttpsError('permission-denied', 'You cannot verify another user’s payment.');
    }
    if (payment.status === 'successful') {
        return { success: true, status: 'successful' };
    }
    if (payment.provider !== 'pesapal' ||
        typeof payment.providerTransactionId !== 'string' ||
        !payment.providerTransactionId) {
        throw new functions.https.HttpsError('failed-precondition', 'The PesaPal transaction reference is missing.');
    }
    const result = await paymentService.verifyPayment('pesapal', payment.providerTransactionId);
    if (!result.providerStatus) {
        return {
            success: false,
            status: payment.status || 'pending',
            message: 'PesaPal has not returned a verifiable payment status yet.',
        };
    }
    const status = getVerifiedStatus(result.providerStatus);
    await applyVerifiedStatus(transactionId, status, result.providerStatus);
    return {
        success: status === 'successful',
        status,
        message: status === 'successful'
            ? 'Payment verified.'
            : 'Payment is not confirmed as successful yet.',
    };
});
exports.pesapalIPN = functions
    .region('us-central1')
    .https.onRequest(async (req, res) => {
    var _a, _b, _c;
    try {
        const orderTrackingId = String(((_a = req.query) === null || _a === void 0 ? void 0 : _a.OrderTrackingId) ||
            ((_b = req.body) === null || _b === void 0 ? void 0 : _b.OrderTrackingId) ||
            ((_c = req.body) === null || _c === void 0 ? void 0 : _c.orderTrackingId) ||
            '').trim();
        if (!orderTrackingId) {
            res.status(400).send('Missing OrderTrackingId');
            return;
        }
        // Always verify with PesaPal; do not trust the notification alone.
        const result = await paymentService.verifyPayment('pesapal', orderTrackingId);
        if (!result.providerStatus) {
            res.status(502).send('Could not verify transaction with PesaPal');
            return;
        }
        const matches = await db
            .collection('payment_transactions')
            .where('providerTransactionId', '==', orderTrackingId)
            .limit(1)
            .get();
        if (matches.empty) {
            res.status(200).send('Notification received; transaction not found');
            return;
        }
        const transactionDoc = matches.docs[0];
        const status = getVerifiedStatus(result.providerStatus);
        await applyVerifiedStatus(transactionDoc.id, status, result.providerStatus);
        res.status(200).send('OK');
    }
    catch (error) {
        console.error('PesaPal notification verification failed:', error);
        res.status(500).send('Notification processing failed');
    }
});
exports.getSupportedProviders = functions
    .region('us-central1')
    .https.onCall(async () => ({
    providers: paymentService.getAvailableProviders(),
    methods: {
        mobile_money: ['mpesa', 'airtel', 'tigo', 'halotel'],
        card: ['visa', 'mastercard'],
    },
    currencies: ['TZS', 'USD', 'KES', 'UGX'],
}));
exports.requestRefund = functions
    .region('us-central1')
    .https.onCall(async (_data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Please sign in first.');
    }
    return {
        success: false,
        message: 'Refunds are not automated yet. Please contact TURIVA support.',
    };
});
//# sourceMappingURL=index.js.map