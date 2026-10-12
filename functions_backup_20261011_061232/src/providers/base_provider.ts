/**
 * ⭐ Payment Provider — Abstract Base Class
 * Kila provider (PesaPal, AzamPay, Flutterwave) ita-extend hii
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

  abstract isConfigured(): boolean;
  abstract supportsMethod(method: string, network?: string): boolean;
  abstract supportsCurrency(currency: string): boolean;
  abstract initiate(request: PaymentRequest): Promise<PaymentResponse>;
  abstract verify(providerTransactionId: string): Promise<PaymentResponse>;
  abstract refund(
    providerTransactionId: string,
    amount: number,
    reason: string
  ): Promise<PaymentResponse>;
  abstract verifyWebhookSignature(payload: string, signature: string): boolean;
  abstract normalizeStatus(providerStatus: string): string;
}
