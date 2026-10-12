import axios, { AxiosInstance } from 'axios';
import { PaymentProvider, PaymentRequest, PaymentResponse } from './base_provider';
import { PesaPalConfig } from '../config/pesapal_config';

/**
 * ⭐ PesaPal Payment Provider
 * Ina-support: M-Pesa, Airtel, Tigo, Halotel, Visa, Mastercard
 */
export class PesaPalProvider extends PaymentProvider {
  name = 'pesapal';
  private client: AxiosInstance;
  private token: string | null = null;
  private tokenExpiry: Date | null = null;

  constructor() {
    super();
    this.client = axios.create({
      baseURL: PesaPalConfig.apiUrl,
      timeout: 30000,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    });
  }

  isConfigured(): boolean {
    try {
      return !!(PesaPalConfig.consumerKey && PesaPalConfig.consumerSecret);
    } catch {
      return false;
    }
  }

  supportsMethod(method: string, network?: string): boolean {
    // PesaPal ina-support mobile money + cards
    if (method === 'mobile_money') {
      return ['mpesa', 'airtel', 'tigo', 'halotel'].includes(network || '');
    }
    if (method === 'card') {
      return ['visa', 'mastercard'].includes(network || '');
    }
    return false;
  }

  supportsCurrency(currency: string): boolean {
    return ['TZS', 'USD', 'KES', 'UGX'].includes(currency);
  }

  /**
   * ⭐ Get auth token from PesaPal
   */
  private async getAuthToken(): Promise<string> {
    // Check if token is still valid
    if (this.token && this.tokenExpiry && new Date() < this.tokenExpiry) {
      return this.token;
    }

    try {
      const response = await this.client.post('/api/Auth/RequestToken', {
        consumer_key: PesaPalConfig.consumerKey,
        consumer_secret: PesaPalConfig.consumerSecret,
      });

      if (response.data && response.data.token) {
        this.token = response.data.token;
        // Token expires after ~5 min, refresh at 4 min
        this.tokenExpiry = new Date(Date.now() + 4 * 60 * 1000);
        return this.token!;
      }

      throw new Error('Failed to get PesaPal token');
    } catch (error: any) {
      console.error('🔥 PesaPal auth error:', error.response?.data || error.message);
      throw new Error(`PesaPal auth failed: ${error.message}`);
    }
  }

  /**
   * ⭐ Register IPN URL (mara moja tu)
   */
  async registerIPN(): Promise<string> {
    const token = await this.getAuthToken();

    try {
      const response = await this.client.post(
        '/api/URLSetup/RegisterIPN',
        {
          url: PesaPalConfig.ipnUrl,
          ipn_notification_type: 'POST',
        },
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      if (response.data && response.data.ipn_id) {
        console.log('✅ PesaPal IPN registered:', response.data.ipn_id);
        return response.data.ipn_id;
      }

      throw new Error('Failed to register IPN');
    } catch (error: any) {
      console.error('🔥 PesaPal IPN error:', error.response?.data || error.message);
      throw new Error(`IPN registration failed: ${error.message}`);
    }
  }

  /**
   * ⭐ Submit order request
   */
  async initiate(request: PaymentRequest): Promise<PaymentResponse> {
    try {
      const token = await this.getAuthToken();

      // Get IPN ID (should be cached)
      const ipnId = await this.registerIPN();

      const orderPayload = {
        id: request.transactionId,
        currency: request.currency,
        amount: request.amount,
        description: request.description,
        callback_url: PesaPalConfig.callbackUrl,
        notification_id: ipnId,
        billing_address: {
          email_address: request.customerEmail,
          phone_number: request.phoneNumber || '',
          country_code: 'TZ',
          first_name: request.customerName.split(' ')[0] || 'Customer',
          last_name: request.customerName.split(' ').slice(1).join(' ') || '',
        },
      };

      const response = await this.client.post(
        '/api/Transactions/SubmitOrderRequest',
        orderPayload,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

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
    } catch (error: any) {
      console.error('🔥 PesaPal initiate error:', error.response?.data || error.message);
      return {
        success: false,
        message: error.message,
        errorCode: 'INIT_ERROR',
      };
    }
  }

  /**
   * ⭐ Verify payment status
   */
  async verify(providerTransactionId: string): Promise<PaymentResponse> {
    try {
      const token = await this.getAuthToken();

      const response = await this.client.get(
        `/api/Transactions/GetTransactionStatus?orderTrackingId=${providerTransactionId}`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

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
    } catch (error: any) {
      console.error('🔥 PesaPal verify error:', error.response?.data || error.message);
      return {
        success: false,
        message: error.message,
        errorCode: 'VERIFY_ERROR',
      };
    }
  }

  /**
   * ⭐ Refund (kama PesaPal ina-support)
   */
  async refund(
    providerTransactionId: string,
    amount: number,
    reason: string
  ): Promise<PaymentResponse> {
    // PesaPal refund inahitaji contact support au different endpoint
    // Kwa sasa — placeholder
    console.log(`🔄 Refund request: ${providerTransactionId}, amount: ${amount}`);
    return {
      success: false,
      message: 'Refund pending manual approval',
      errorCode: 'REFUND_MANUAL',
    };
  }

  /**
   * ⭐ Verify webhook signature (IPN)
   */
  verifyWebhookSignature(payload: string, signature: string): boolean {
    // PesaPal IPN ina-verify kwa API call (tunaifanya kwenye handler)
    // Return true — verification inafanyika kupitia API
    return true;
  }

  /**
   * ⭐ Normalize PesaPal status → TURIVA status
   */
  normalizeStatus(providerStatus: string): string {
    const status = providerStatus.toLowerCase();
    if (status.includes('completed') || status === 'completed') {
      return 'successful';
    }
    if (status.includes('failed')) return 'failed';
    if (status.includes('reversed')) return 'refunded';
    if (status.includes('pending')) return 'processing';
    return 'pending';
  }
}
