// lib/features/auth/data/services/email_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  final String _brevoUrl = "https://api.brevo.com/v3/smtp/email";

  Future<bool> sendOtp(String email, String otp) async {
    try {
      final apiKey = dotenv.env['BREVO_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint("❌ Error: BREVO_API_KEY is missing in .env file");
        return false;
      }

      final headers = {
        'accept': 'application/json',
        'api-key': apiKey,
        'content-type': 'application/json',
      };

      // ✅ NEW: Professional HTML Template
      final String htmlTemplate =
          """
<!DOCTYPE html>
<html>
<body style="font-family: sans-serif; padding: 20px; color: #333;">
  <div style="max-width: 600px; margin: auto; border: 1px solid #eee; padding: 20px; border-radius: 10px;">
    <h2 style="color: #006D77;">Verify your account</h2>
    <p>Use the following code to complete your registration:</p>
    <div style="font-size: 32px; font-weight: bold; background: #f4f4f4; padding: 20px; text-align: center; border-radius: 5px; color: #006D77; letter-spacing: 5px;">
      $otp
    </div>
    <p>This code will expire in 10 minutes.</p>
    <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
    <p style="font-size: 12px; color: #999;">If you didn't request this, you can ignore this email.</p>
  </div>
</body>
</html>
""";

      final body = jsonEncode({
        "sender": {
          "name": "Laween Team",
          "email": "no-reply@laween.xyz", 
        },
        "to": [
          {"email": email},
        ],
        "subject": "Verify your Laween account",
        "htmlContent": htmlTemplate,
        "textContent": "Your Laween Verification Code is: $otp. This code will expire in 10 minutes.", 
      });

      final response = await http.post(
        Uri.parse(_brevoUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint("✅ Email sent successfully to $email");
        return true;
      } else {
        debugPrint("❌ Failed to send email. Status: ${response.statusCode}");
        debugPrint("❌ Brevo Error Body: ${response.body}");
        // If you see 'unauthorized' here, it means the API key is invalid.
        // If you see 'sender not verified', change 'no-reply@laween.xyz' to your verified email.
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error sending email: $e");
      return false;
    }
  }
}
