export class PesaPalConfig {
  static get consumerKey(): string {
    return process.env.PESAPAL_CONSUMER_KEY || '';
  }

  static get consumerSecret(): string {
    return process.env.PESAPAL_CONSUMER_SECRET || '';
  }

  static get environment(): string {
    return process.env.PESAPAL_ENVIRONMENT || 'sandbox';
  }

  static get apiUrl(): string {
    return process.env.PESAPAL_API_URL || 'https://cybqa.pesapal.com/pesapalv3';
  }

  static get ipnUrl(): string {
    return process.env.PESAPAL_IPN_URL || '';
  }

  static get callbackUrl(): string {
    return process.env.PESAPAL_CALLBACK_URL || '';
  }

  static get isSandbox(): boolean {
    return this.environment === 'sandbox';
  }
}
