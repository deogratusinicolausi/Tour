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
exports.IdempotencyService = void 0;
const admin = __importStar(require("firebase-admin"));
/**
 * ⭐ Idempotency Service
 * Prevents duplicate payments
 */
class IdempotencyService {
    constructor() {
        this.db = admin.firestore();
        this.collection = 'idempotency_keys';
    }
    async checkKey(key) {
        const doc = await this.db.collection(this.collection).doc(key).get();
        if (doc.exists) {
            const data = doc.data();
            if (data && data.expiresAt) {
                const expiresAt = data.expiresAt.toDate();
                if (new Date() < expiresAt) {
                    return data.result;
                }
                await doc.ref.delete();
            }
        }
        return null;
    }
    async saveKey(key, result) {
        const expiresAt = new Date();
        expiresAt.setHours(expiresAt.getHours() + 24);
        await this.db.collection(this.collection).doc(key).set({
            result,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
        });
    }
    generateKey(userId, bookingId) {
        return `${userId}_${bookingId}_${Date.now()}`;
    }
}
exports.IdempotencyService = IdempotencyService;
//# sourceMappingURL=idempotency_service.js.map