import { PaymentProvider, PaymentRequest, PaymentResponse } from '../providers/base_provider';
import { PesaPalProvider } from '../providers/pesapal_provider';

/**
 * ⭐ Payment Service — Abstraction Layer
 */
export class PaymentService {
  private providers: Map<string, PaymentProvider> = new Map();

  constructor() {
    this.registerProvider('pesapal', new PesaPalProvider());
  }

  registerProvider(name: string, provider: PaymentProvider): void {
    this.providers.set(name, provider);
  }

  getProvider(name: string): PaymentProvider | null {
    return this.providers.get(name) || null;
  }

  async initiatePayment(
    providerName: string,
    request: PaymentRequest
  ): Promise<PaymentResponse> {
    const provider = this.getProvider(providerName);
    if (!provider) throw new Error(`Provider ${providerName} not found`);
    if (!provider.isConfigured()) throw new Error(`Provider ${providerName} not configured`);
    if (!provider.supportsMethod(request.paymentMethod, request.paymentNetwork)) {
      throw new Error(`Provider ${providerName} does not support ${request.paymentMethod}/${request.paymentNetwork}`);
    }
    if (!provider.supportsCurrency(request.currency)) {
      throw new Error(`Provider ${providerName} does not support currency ${request.currency}`);
    }
    return provider.initiate(request);
  }

  async verifyPayment(
    providerName: string,
    transactionId: string
  ): Promise<PaymentResponse> {
    const provider = this.getProvider(providerName);
    if (!provider) throw new Error(`Provider ${providerName} not found`);
    return provider.verify(transactionId);
  }

  async refundPayment(
    providerName: string,
    transactionId: string,
    amount: number,
    reason: string
  ): Promise<PaymentResponse> {
    const provider = this.getProvider(providerName);
    if (!provider) throw new Error(`Provider ${providerName} not found`);
    return provider.refund(transactionId, amount, reason);
  }

  getAvailableProviders(): string[] {
    return Array.from(this.providers.keys()).filter((name) => {
      const p = this.providers.get(name);
      return p && p.isConfigured();
    });
  }
}
