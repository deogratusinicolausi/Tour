"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentService = void 0;
const pesapal_provider_1 = require("../providers/pesapal_provider");
/**
 * ⭐ Payment Service — Abstraction Layer
 */
class PaymentService {
    constructor() {
        this.providers = new Map();
        this.registerProvider('pesapal', new pesapal_provider_1.PesaPalProvider());
    }
    registerProvider(name, provider) {
        this.providers.set(name, provider);
    }
    getProvider(name) {
        return this.providers.get(name) || null;
    }
    async initiatePayment(providerName, request) {
        const provider = this.getProvider(providerName);
        if (!provider)
            throw new Error(`Provider ${providerName} not found`);
        if (!provider.isConfigured())
            throw new Error(`Provider ${providerName} not configured`);
        if (!provider.supportsMethod(request.paymentMethod, request.paymentNetwork)) {
            throw new Error(`Provider ${providerName} does not support ${request.paymentMethod}/${request.paymentNetwork}`);
        }
        if (!provider.supportsCurrency(request.currency)) {
            throw new Error(`Provider ${providerName} does not support currency ${request.currency}`);
        }
        return provider.initiate(request);
    }
    async verifyPayment(providerName, transactionId) {
        const provider = this.getProvider(providerName);
        if (!provider)
            throw new Error(`Provider ${providerName} not found`);
        return provider.verify(transactionId);
    }
    async refundPayment(providerName, transactionId, amount, reason) {
        const provider = this.getProvider(providerName);
        if (!provider)
            throw new Error(`Provider ${providerName} not found`);
        return provider.refund(transactionId, amount, reason);
    }
    getAvailableProviders() {
        return Array.from(this.providers.keys()).filter((name) => {
            const p = this.providers.get(name);
            return p && p.isConfigured();
        });
    }
}
exports.PaymentService = PaymentService;
//# sourceMappingURL=payment_service.js.map