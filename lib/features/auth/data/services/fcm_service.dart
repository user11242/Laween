// lib/features/auth/data/services/fcm_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:shared_preferences/shared_preferences.dart';

class FcmService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Renamed to 'saveUserFcmToken' because it works for all users
  Future<void> saveUserFcmToken(String uid) async {
    String? token;

    try {
      // 1. Request permissions (Crucial for iOS)
      NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true);

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint("❌ User denied notification permissions");
        return;
      }

      // 2. Attempt to get the token
      token = await FirebaseMessaging.instance.getToken();

      debugPrint("✅ FCM Token retrieved: $token");
    } catch (e) {
      // Specific iOS error handling (Simulator often throws this)
      if (e.toString().contains("apns-token-not-set")) {
        debugPrint(
          "⚠️ FCM Warning: APNS token not set yet. (Normal on Simulators)",
        );
      } else {
        debugPrint("❌ FCM Token Error: $e");
      }
      return;
    }

    // 3. Update Firestore
    // 4. Get preferred language
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('selected_language_code') ?? 'en';

    await _firestore.collection("users").doc(uid).update({
      "fcmToken": token,
      "preferredLanguage": languageCode,
      "lastTokenUpdate": FieldValue.serverTimestamp(), // Good for debugging
    });
    }
}
