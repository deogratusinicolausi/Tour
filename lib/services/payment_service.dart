import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class PaymentService {
  // ⚠️ Badilisha hii na URL yako halisi ya Cloud Function
  // Unaipata baada ya ku-deploy function yako
  static const String _functionUrl = 'https://us-central1-com-example-turiva.cloudfunctions.net/initiateAzamPayPayment';

  Future<Map<String, dynamic>> initiatePayment({
    required String mobileNumber,
    required String amount,
    required String provider,
    required String externalId,
  }) async {
    try {
      // Pata ID token ya mtumiaji (kwa usalama)
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      final idToken = await user.getIdToken();

      // Tuma ombi la HTTP POST moja kwa moja
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'mobileNumber': mobileNumber,
          'amount': amount,
          'provider': provider,
          'externalId': externalId,
        }),
      );

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Function call failed: ${response.statusCode}'
        };
      }

      final responseData = jsonDecode(response.body);
      return Map<String, dynamic>.from(responseData);

    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}