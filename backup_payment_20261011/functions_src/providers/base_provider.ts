/**
 * ⭐ Payment Provider — Abstract Base Class
 * Kila provider (ClickPesa, AzamPay, Flutterwave) ita-extend hii
 */

export interface PaymentRequest {
  transactionId: string;
  amount: number;
  currency: string;
  paymentMethod: 'mobile_money' | 'card' | 'cash';
  paymentNetwork?: string;
  phoneNumber?: string;
  customerName: string;
  customerEmail: string;
  description: string;
  callbackUrl: string;
  metadata?: Record<string, any>;
}

export interface PaymentResponse {
  success: boolean;
  providerTransactionId?: string;
  providerReference?: string;
  providerStatus?: string;
  redirectUrl?: string;
  message?: string;
  errorCode?: string;
  raw?: any;
}

export abstract class PaymentProvider {
  abstract name: string;

  /**
   * Check if provider is configured (API keys exist)
   */
  abstract isConfigured(): boolean;

  /**
   * Check if provider supports given payment method
   */
  abstract supportsMethod(method: string, network?: string): boolean;

  /**
   * Check if provider supports currency
   */
  abstract supportsCurrency(currency: string): boolean;

  /**
   * Initiate payment
   */
  abstract initiate(request: PaymentRequest): Promise<PaymentResponse>;

  /**
   * Verify payment status
   */
  abstract verify(providerTransactionId: string): Promise<PaymentResponse>;

  /**
   * Process refund
   */
  abstract refund(
    providerTransactionId: string,
    amount: number,
    reason: string
  ): Promise<PaymentResponse>;

  /**
   * Verify webhook signature
   */
  abstract verifyWebhookSignature(
    payload: string,
    signature: string
  ): boolean;

  /**
   * Normalize provider status to TURIVA status
   */
  abstract normalizeStatus(providerStatus: string): string;
}
