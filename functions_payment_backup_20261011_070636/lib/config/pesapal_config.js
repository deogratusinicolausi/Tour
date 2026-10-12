"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PesaPalConfig = void 0;
class PesaPalConfig {
    static get consumerKey() {
        return process.env.PESAPAL_CONSUMER_KEY || '';
    }
    static get consumerSecret() {
        return process.env.PESAPAL_CONSUMER_SECRET || '';
    }
    static get environment() {
        return process.env.PESAPAL_ENVIRONMENT || 'sandbox';
    }
    static get apiUrl() {
        return process.env.PESAPAL_API_URL || 'https://cybqa.pesapal.com/pesapalv3';
    }
    static get ipnUrl() {
        return process.env.PESAPAL_IPN_URL || '';
    }
    static get callbackUrl() {
        return process.env.PESAPAL_CALLBACK_URL || '';
    }
    static get isSandbox() {
        return this.environment === 'sandbox';
    }
}
exports.PesaPalConfig = PesaPalConfig;
//# sourceMappingURL=pesapal_config.js.map