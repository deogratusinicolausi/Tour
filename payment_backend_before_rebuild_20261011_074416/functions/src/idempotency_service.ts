import * as admin from 'firebase-admin';

export class IdempotencyService {
  private db = admin.firestore();
  private collection = 'idempotency_keys';

  async checkKey(key: string): Promise<any | null> {
    const doc = await this.db.collection(this.collection).doc(key).get();
    if (doc.exists) {
      const data = doc.data();
      if (data && data.expiresAt) {
        const expiresAt = data.expiresAt.toDate();
        if (new Date() < expiresAt) return data.result;
        await doc.ref.delete();
      }
    }
    return null;
  }

  async saveKey(key: string, result: any): Promise<void> {
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 24);
    await this.db.collection(this.collection).doc(key).set({
      result,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
    });
  }
}
