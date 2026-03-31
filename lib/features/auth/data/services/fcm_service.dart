// lib/features/auth/data/services/fcm_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FcmService {
  // Singleton Pattern
  static final FcmService instance = FcmService._internal();
  FcmService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Call this once in main.dart after Firebase.initializeApp()
  Future<void> initialize() async {
    // 1. Request permissions (Requires user prompt on iOS/Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint("❌ User denied notification permissions");
      return;
    }
    debugPrint("✅ Notification permissions granted");

    // 2. Set up foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Received Foreground Message: ${message.notification?.title}');
      // Here you could trigger a local flushbar/snackbar if you want in-app popups
    });

    // 3. Set up listener for when app is opened from a background notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🚀 App opened from notification: ${message.data}');
      // Handle routing here if needed
    });

    // 4. Listen for token refreshes automatically
    _messaging.onTokenRefresh.listen((newToken) {
      // We don't have the UID here easily, so we usually rely on the login/boot routine calling saveUserFcmToken
      debugPrint("🔄 FCM Token Refreshed (Need to sync to DB on next boot)");
    });
  }

  /// Syncs the device token to the database so the backend knows where to find them
  Future<void> saveUserFcmToken(String uid) async {
    String? token;

    try {
      // CRITICAL FOR iOS: We must wait for the APNs token before getting the FCM token.
      if (Platform.isIOS) {
        String? apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          debugPrint("⚠️ APNS token not set yet. Waiting 3 seconds...");
          await Future.delayed(const Duration(seconds: 3));
          apnsToken = await _messaging.getAPNSToken();
          if (apnsToken == null) {
            debugPrint("❌ APNS token still null. Cannot generate iOS FCM token.");
            return;
          }
        }
        debugPrint("✅ APNS Token retrieved (Apple Bridge Active)");
      }

      // Generate the universal FCM token
      token = await _messaging.getToken();
      debugPrint("✅ FCM Token retrieved: $token");
      
    } catch (e) {
      debugPrint("❌ FCM Token Generation Error: $e");
      return;
    }

    if (token == null) return;

    // Save to Firestore Profile
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('selected_language_code') ?? 'en';

    await _firestore.collection("users").doc(uid).set({
      "fcmToken": token,
      "preferredLanguage": languageCode,
      "lastTokenUpdate": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    debugPrint("💾 FCM Token successfully synced to database for UID: $uid");
  }
}
