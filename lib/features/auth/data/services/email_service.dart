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
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 0; }
    .container { max-width: 500px; margin: 30px auto; background: #ffffff; padding: 20px; border-radius: 8px; box-shadow: 0 4px 10px rgba(0,0,0,0.1); }
    .header { text-align: center; padding: 25px 0; background-color: #006D77; border-radius: 8px 8px 0 0; }
    .header h1 { color: #ffffff; margin: 0; font-size: 28px; letter-spacing: 2px; }
    .content { padding: 30px; text-align: center; color: #333333; line-height: 1.6; }
    .otp-code { font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #006D77; background: #f0f7f8; padding: 20px; border-radius: 12px; display: inline-block; margin: 25px 0; border: 2px solid #006D77; }
    .footer { text-align: center; font-size: 12px; color: #888888; margin-top: 20px; border-top: 1px solid #eeeeee; padding: 20px; }
    .btn { display: inline-block; padding: 12px 24px; color: #ffffff; background-color: #006D77; border-radius: 30px; text-decoration: none; font-weight: bold; margin-top: 20px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Laween</h1> 
    </div>
    <div class="content">
      <p style="font-size: 18px; font-weight: bold;">Hello!</p>
      <p>Your security is important to us. Use the verification code below to complete your sign-in process.</p>
      
      <div class="otp-code">$otp</div>
      
      <p style="font-size: 14px; color: #666;">This secure code will expire in <strong style="color: #006D77;">10 minutes</strong>.</p>
      <div style="margin-top: 25px;">
        <p style="font-size: 13px;">If you didn't request this code, your account is safe – you can simply ignore this email.</p>
      </div>
    </div>
    <div class="footer">
      <p>Sent with ❤️ from the Laween Team</p>
      <p>&copy; 2026 Laween Inc. All rights reserved.</p>
    </div>
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
        "subject": "Your Laween Verification Code",
        "htmlContent": htmlTemplate, 
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
        debugPrint("Response: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error sending email: $e");
      return false;
    }
  }
}
