/**
 * ⭐ PesaPal Configuration
 * Inasoma environment variables kutoka functions/.env
 */
export class PesaPalConfig {
  static get consumerKey(): string {
    const key = process.env.PESAPAL_CONSUMER_KEY;
    if (!key) throw new Error('PESAPAL_CONSUMER_KEY not set');
    return key;
  }

  static get consumerSecret(): string {
    const secret = process.env.PESAPAL_CONSUMER_SECRET;
    if (!secret) throw new Error('PESAPAL_CONSUMER_SECRET not set');
    return secret;
  }

  static get environment(): 'sandbox' | 'production' {
    const env = process.env.PESAPAL_ENVIRONMENT || 'sandbox';
    return env === 'production' ? 'production' : 'sandbox';
  }

  static get apiUrl(): string {
    return process.env.PESAPAL_API_URL ||
      (this.environment === 'sandbox'
        ? 'https://cybqa.pesapal.com/pesapalv3'
        : 'https://pay.pesapal.com/v3');
  }

  static get ipnUrl(): string {
    return process.env.PESAPAL_IPN_URL ||
      'https://us-central1-turiva.cloudfunctions.net/pesapalIPN';
  }

  static get callbackUrl(): string {
    return process.env.PESAPAL_CALLBACK_URL ||
      'https://turiva.app/payment/callback';
  }

  static get isSandbox(): boolean {
    return this.environment === 'sandbox';
  }

  static get currency(): string {
    return 'TZS';
  }
}
