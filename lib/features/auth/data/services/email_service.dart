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
    .header { text-align: center; padding-bottom: 20px; border-bottom: 1px solid #eeeeee; }
    .header h1 { color: #ffca28; margin: 0; font-size: 24px; } /* Amber Color */
    .content { padding: 20px; text-align: center; color: #333333; }
    .otp-code { font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #000000; background: #fff8e1; padding: 15px; border-radius: 5px; display: inline-block; margin: 20px 0; border: 1px dashed #ffca28; }
    .footer { text-align: center; font-size: 12px; color: #888888; margin-top: 20px; border-top: 1px solid #eeeeee; padding-top: 10px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Calligro</h1> 
    </div>
    <div class="content">
      <p style="font-size: 16px;">Hello,</p>
      <p>Use the code below to verify your account.</p>
      
      <div class="otp-code">$otp</div>
      
      <p style="font-size: 14px; color: #666;">This code expires in <strong>10 minutes</strong>.</p>
      <p>If you didn't request this, you can safely ignore this email.</p>
    </div>
    <div class="footer">
      <p>&copy; 2026 Calligro Team. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
""";

      final body = jsonEncode({
        "sender": {
          "name": "Calligro Team",
          "email": "no-reply@calligro.digital", // ✅ Keep your verified email
        },
        "to": [
          {"email": email},
        ],
        "subject": "Your Calligro Verification Code",
        "htmlContent": htmlTemplate, // ✅ Use the new template
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
