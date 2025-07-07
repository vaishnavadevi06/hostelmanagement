import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Initialize the environment (load .env file)
void initializeEnv() {
  dotenv.load();
}

/// Send an SMS via Twilio using environment variables
Future<void> sendSMS({
  required String name,
  required String phone,
  required String checkIn,
  required String checkOut,
  required String roomType,
}) async {
  final String? accountSid = dotenv.env['TWILIO_SID'];
  final String? authToken = dotenv.env['TWILIO_TOKEN'];
  final String? fromNumber = dotenv.env['TWILIO_FROM'];

  if (accountSid == null || authToken == null || fromNumber == null) {
    throw Exception('❌ Twilio credentials missing in .env file');
  }

  final String message =
      '✅ Hello $name! Your booking from $checkIn to $checkOut '
      'for a $roomType room is confirmed. – Hostel Team';

  final Uri url = Uri.https(
    'api.twilio.com',
    '/2010-04-01/Accounts/$accountSid/Messages.json',
  );

  final response = await http.post(
    url,
    headers: {
      'Authorization':
          'Basic ${base64Encode(utf8.encode('$accountSid:$authToken'))}',
    },
    body: {'To': '+91$phone', 'From': fromNumber, 'Body': message},
  );

  if (response.statusCode == 201 || response.statusCode == 200) {
    print('✅ SMS sent to $phone');
  } else {
    print('❌ SMS failed: ${response.statusCode}');
    print(response.body);
  }
}
