import 'dart:convert';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:http/http.dart' as http;

const String clientId = '4be90bd7-7c2a-43f5-945b-82df6b941061';
const String clientSecret = 'YbfTJgnmXmieMlXgEv3AGk/zkCkYLnjlh9M5D6SPRCWnH73c1Ydliq+OQe/OucYGM7vZbNr3jHx2oYK9zlM2v8mV1y9xPa6oANDcfp1eAHLnFkIbKO8B3wlLfaQfufNMZysr6wCDA4SP8/fIYH7k5/Z9VMw2B/qaC7Y7BRSha/U5aHawIQ2CyywPfj1C2jmVXRPhMNGO9YyKsuLSjzoPIwU7y/OxedZf/Pdg95sSHo+5nhDWP/Ko/jJnuWYGMiC7S+17LCwSrSM1ErDrqJsgdBy58iLG50HHEOP5rhHcuzQuLv6O0xqY/O1ExR45OqRW/wzGWLvuspe4bK026hJylTR9QJdbHZlUGmhDpDZUOyDgDz7HTtgUFHpdeTEEQgx+25aZNc9SuF3i6L+8WgxTe3FYDwCb1Ph6sG+gzMIw8PhC49mwEgpoO9bpXf4UjuBpJrvNc4hEYl1pTn4ZrHImxg7L7hybHs7hxIRO+/Ay3lg9e+b+/Jhaw4WPtJqItngSmcBghyV3Ufzc8KPawApLk1mxji8nZB2qsSfGBzrC4z2jNIAzcMRKB0CryUbGM1lCgott4SvPBIOIVSZ3W3+x8S8Gh8OYA4YohuwMQod8u+J+H8EvOzvZ5gHwbNe1B4UN+o5GlyNhmkXHDcnIvEIswy15UqC7b6V5gwu05aRi+jA=';
const String apiKey = '1c9d5a5a-824b-4635-89e5-c02f8c1e36c9';
const String appName = 'TURIVA';

Future<void> main(List<String> args) async {
  await runFunctions((firebase) {  // ⭐️ Badilisha fireUp → runFunctions
    final firestore = firebase.adminApp.firestore();

    // Function ya kuanzisha malipo
    firebase.https.onRequest(
      name: 'initiateAzamPayPayment',
      options: const HttpsOptions(cors: Cors(['*'])),
          (request) async {
        if (request.method == 'OPTIONS') {
          return Response(204);
        }
        if (request.method != 'POST') {
          return Response(405, body: 'Method Not Allowed');
        }

        try {
          // ⭐️ Badilisha request.body → request.readAsString()
          final bodyString = await request.readAsString();
          final data = jsonDecode(bodyString);
          final String mobileNumber = data['mobileNumber'] ?? '';
          final String amount = data['amount'] ?? '';
          final String provider = data['provider'] ?? 'Mpesa';
          final String externalId = data['externalId'] ?? '';

          if (mobileNumber.isEmpty || amount.isEmpty) {
            return Response(400, body: jsonEncode({'error': 'Missing fields'}));
          }

          final authResponse = await http.post(
            Uri.parse('https://authenticator-sandbox.azampay.co.tz/AppRegistration/GenerateToken'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'appName': appName,
              'clientId': clientId,
              'clientSecret': clientSecret,
            }),
          );

          if (authResponse.statusCode != 200) {
            return Response(401, body: jsonEncode({'success': false, 'message': 'Auth failed'}));
          }

          final authData = jsonDecode(authResponse.body);
          final String token = authData['data']?['accessToken'] ?? '';

          if (token.isEmpty) {
            return Response(401, body: jsonEncode({'success': false, 'message': 'No token'}));
          }

          final payResponse = await http.post(
            Uri.parse('https://checkout-sandbox.azampay.co.tz/azampay/mno/checkout'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'X-API-Key': apiKey,
            },
            body: jsonEncode({
              'accountNumber': mobileNumber,
              'amount': amount,
              'currency': 'TZS',
              'externalId': externalId,
              'provider': provider,
              'additionalProperties': {},
            }),
          );

          final payData = jsonDecode(payResponse.body);

          return Response(
            payResponse.statusCode,
            body: jsonEncode({
              'success': payResponse.statusCode == 200,
              'transactionId': payData['transactionId'] ?? '',
              'message': payData['message'] ?? 'Request received',
              'messageCode': payData['messageCode'] ?? 0,
            }),
          );
        } catch (e) {
          return Response(500, body: jsonEncode({'success': false, 'message': e.toString()}));
        }
      },
    );

    // Function ya webhook
    firebase.https.onRequest(
      name: 'azamPayWebhook',
      options: const HttpsOptions(cors: Cors(['*'])),
          (request) async {
        if (request.method == 'OPTIONS') {
          return Response(204);
        }
        if (request.method != 'POST') {
          return Response(405, body: 'Method Not Allowed');
        }

        try {
          // ⭐️ Badilisha request.body → request.readAsString()
          final bodyString = await request.readAsString();
          final callbackData = jsonDecode(bodyString);
          print('Webhook: $callbackData');

          final String? status = callbackData['transactionstatus'];
          final String? externalReference = callbackData['externalreference'];

          if (status != null && status.toLowerCase() == 'success' && externalReference != null) {
            // ⭐️ Badilisha where('externalId', isEqualTo: ...) → Filter.equal(...)
            final bookingsQuery = await firestore
                .collection('bookings')
                .where('externalId', WhereFilter.equal, externalReference)                .limit(1)
                .get();

            if (bookingsQuery.docs.isNotEmpty) {
              // ⭐️ Badilisha .reference.update() → firestore.collection().doc().update()
              final bookingId = bookingsQuery.docs.first.id;
              await firestore.collection('bookings').doc(bookingId).update({
                'bookingStatus': 'confirmed',
                'paymentStatus': 'paid',
                'transactionId': callbackData['transid'] ?? '',
                'updatedAt': FieldValue.serverTimestamp,
              });
              print('Booking $bookingId confirmed.');
            }
          }

          return Response(200, body: jsonEncode({'status': 'success'}));
        } catch (e) {
          return Response(500, body: jsonEncode({'error': e.toString()}));
        }
      },
    );
  });
}