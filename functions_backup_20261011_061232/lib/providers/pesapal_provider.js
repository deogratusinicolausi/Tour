"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PesaPalProvider = void 0;
const axios_1 = __importDefault(require("axios"));
const base_provider_1 = require("./base_provider");
const pesapal_config_1 = require("../config/pesapal_config");
/**
 * ⭐ PesaPal Payment Provider
 * Supports: M-Pesa, Airtel, Tigo, Halotel, Visa, Mastercard
 */
class PesaPalProvider extends base_provider_1.PaymentProvider {
    constructor() {
        super();
        this.name = 'pesapal';
        this.token = null;
        this.tokenExpiry = null;
        this.ipnId = null;
        this.client = axios_1.default.create({
            baseURL: pesapal_config_1.PesaPalConfig.apiUrl,
            timeout: 30000,
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
        });
    }
    isConfigured() {
        try {
            return !!(pesapal_config_1.PesaPalConfig.consumerKey && pesapal_config_1.PesaPalConfig.consumerSecret);
        }
        catch (_a) {
            return false;
        }
    }
    supportsMethod(method, network) {
        if (method === 'mobile_money') {
            return ['mpesa', 'airtel', 'tigo', 'halotel'].includes(network || '');
        }
        if (method === 'card') {
            return ['visa', 'mastercard'].includes(network || '');
        }
        return false;
    }
    supportsCurrency(currency) {
        return ['TZS', 'USD', 'KES', 'UGX'].includes(currency);
    }
    async getAuthToken() {
        var _a;
        if (this.token && this.tokenExpiry && new Date() < this.tokenExpiry) {
            return this.token;
        }
        try {
            const response = await this.client.post('/api/Auth/RequestToken', {
                consumer_key: pesapal_config_1.PesaPalConfig.consumerKey,
                consumer_secret: pesapal_config_1.PesaPalConfig.consumerSecret,
            });
            if (response.data && response.data.token) {
                this.token = response.data.token;
                this.tokenExpiry = new Date(Date.now() + 4 * 60 * 1000);
                return this.token;
            }
            throw new Error('Failed to get PesaPal token');
        }
        catch (error) {
            console.error('🔥 PesaPal auth error:', ((_a = error.response) === null || _a === void 0 ? void 0 : _a.data) || error.message);
            throw new Error(`PesaPal auth failed: ${error.message}`);
        }
    }
    async registerIPN() {
        var _a;
        if (this.ipnId)
            return this.ipnId;
        const token = await this.getAuthToken();
        try {
            const response = await this.client.post('/api/URLSetup/RegisterIPN', {
                url: pesapal_config_1.PesaPalConfig.ipnUrl,
                ipn_notification_type: 'POST',
            }, {
                headers: { Authorization: `Bearer ${token}` },
            });
            if (response.data && response.data.ipn_id) {
                this.ipnId = response.data.ipn_id;
                console.log('✅ PesaPal IPN registered:', this.ipnId);
                return this.ipnId;
            }
            throw new Error('Failed to register IPN');
        }
        catch (error) {
            console.error('🔥 PesaPal IPN error:', ((_a = error.response) === null || _a === void 0 ? void 0 : _a.data) || error.message);
            throw new Error(`IPN registration failed: ${error.message}`);
        }
    }
    async initiate(request) {
        var _a;
        try {
            const token = await this.getAuthToken();
            const ipnId = await this.registerIPN();
            const orderPayload = {
                id: request.transactionId,
                currency: request.currency,
                amount: request.amount,
                description: request.description,
                callback_url: pesapal_config_1.PesaPalConfig.callbackUrl,
                notification_id: ipnId,
                billing_address: {
                    email_address: request.customerEmail,
                    phone_number: request.phoneNumber || '',
                    country_code: 'TZ',
                    first_name: request.customerName.split(' ')[0] || 'Customer',
                    last_name: request.customerName.split(' ').slice(1).join(' ') || '',
                },
            };
            const response = await this.client.post('/api/Transactions/SubmitOrderRequest', orderPayload, {
                headers: { Authorization: `Bearer ${token}` },
            });
            if (response.data && response.data.order_tracking_id) {
                return {
                    success: true,
                    providerTransactionId: response.data.order_tracking_id,
                    providerReference: response.data.merchant_reference || '',
                    providerStatus: 'pending',
                    redirectUrl: response.data.redirect_url || '',
                    message: response.data.status || 'Payment initiated',
                    raw: response.data,
                };
            }
            return {
                success: false,
                message: 'Failed to initiate payment',
                errorCode: 'INIT_FAILED',
                raw: response.data,
            };
        }
        catch (error) {
            console.error('🔥 PesaPal initiate error:', ((_a = error.response) === null || _a === void 0 ? void 0 : _a.data) || error.message);
            return {
                success: false,
                message: error.message,
                errorCode: 'INIT_ERROR',
            };
        }
    }
    async verify(providerTransactionId) {
        var _a;
        try {
            const token = await this.getAuthToken();
            const response = await this.client.get(`/api/Transactions/GetTransactionStatus?orderTrackingId=${providerTransactionId}`, {
                headers: { Authorization: `Bearer ${token}` },
            });
            if (response.data) {
                return {
                    success: response.data.status_code === 1,
                    providerTransactionId,
                    providerStatus: response.data.payment_status_description || 'unknown',
                    providerReference: response.data.payment_account || '',
                    message: response.data.payment_status_description || '',
                    raw: response.data,
                };
            }
            return {
                success: false,
                message: 'Verification failed',
                errorCode: 'VERIFY_FAILED',
            };
        }
        catch (error) {
            console.error('🔥 PesaPal verify error:', ((_a = error.response) === null || _a === void 0 ? void 0 : _a.data) || error.message);
            return {
                success: false,
                message: error.message,
                errorCode: 'VERIFY_ERROR',
            };
        }
    }
    async refund(providerTransactionId, amount, reason) {
        console.log(`🔄 Refund request: ${providerTransactionId}, amount: ${amount}, reason: ${reason}`);
        return {
            success: false,
            message: 'Refund pending manual approval',
            errorCode: 'REFUND_MANUAL',
        };
    }
    verifyWebhookSignature(payload, signature) {
        return true;
    }
    normalizeStatus(providerStatus) {
        const status = providerStatus.toLowerCase();
        if (status.includes('completed') || status === 'completed') {
            return 'successful';
        }
        if (status.includes('failed'))
            return 'failed';
        if (status.includes('reversed'))
            return 'refunded';
        if (status.includes('pending'))
            return 'processing';
        return 'pending';
    }
}
exports.PesaPalProvider = PesaPalProvider;
//# sourceMappingURL=pesapal_provider.js.map