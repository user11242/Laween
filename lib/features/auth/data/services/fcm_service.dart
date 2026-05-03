import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:laween/main.dart';
import '../../../groups/data/models/group_model.dart';
import '../../../groups/pages/chat_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:laween/core/services/location_service.dart';

class FcmService {
  // Singleton Pattern
  static final FcmService instance = FcmService._internal();
  FcmService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Tracks the group currently being viewed to suppress noisy foreground alerts
  String? activeGroupId;

  // Android Notification Channel
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'chat_messages',
    'Chat Messages',
    description: 'Notifications for new group chat messages',
    importance: Importance.max,
    playSound: true,
  );

  static const AndroidNotificationChannel _sosChannel = AndroidNotificationChannel(
    'sos_emergencies',
    'SOS Emergencies',
    description: 'Urgent emergency alerts that wake the phone and show a full-screen alert',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  /// Call this once in main.dart after Firebase.initializeApp()
  Future<void> initialize() async {
    // 1. Request permissions (Crucial for iOS)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: true, // Allow for critical announcements
      badge: true,
      carPlay: true,
      criticalAlert: true, // Crucial for SOS to bypass silent mode
      provisional: false,
      sound: true,
    );

    debugPrint(
      '🔔 User notification permission status: ${settings.authorizationStatus}',
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint("❌ User denied notification permissions");
      return;
    }

    // Set foreground notification options for iOS
    // We set alert: false because we handle foreground alerts manually via _showLocalNotification
    // to prevent duplication and allow for sender filtering.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound:
          true, // Restored sound so you hear "Ding" for other groups while inside the app
    );

    debugPrint("✅ Notification permissions granted");

    // 2. Initialize Local Notifications (For Foreground Popups)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap while app is in foreground
        debugPrint("🔔 Notification Tapped: ${details.payload}");
      },
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
      
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_sosChannel);
    }

    // 3. Set up foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        '📩 Received Foreground Message: ${message.notification?.title}',
      );
      _showLocalNotification(message);
    });

    // 4. Handle notification tap (when app is in background or closed)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 5. Handle initial message (when app is launched from terminated state)
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // 6. Listen for token refreshes automatically
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
        int retries = 0;

        while (apnsToken == null && retries < 10) {
          // Try for up to 20 seconds
          debugPrint(
            "⚠️ APNS token not set yet. Waiting 2 seconds... (Attempt \${retries + 1}/10)",
          );
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await _messaging.getAPNSToken();
          retries++;
        }

        if (apnsToken == null) {
          debugPrint(
            "❌ APNS token still null after 20 seconds. Cannot generate iOS FCM token.",
          );

          // Fallback: If it's a simulator, sometimes it fails, but we should still let them use the app
          // In production, Firebase requires the APNs token.
          if (!kDebugMode) return;
        } else {
          debugPrint("✅ APNS Token retrieved (Apple Bridge Active)");
        }
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
      "tokenDiagnostics": {
        "platform": Platform.operatingSystem,
        "lastUpdate": DateTime.now().toIso8601String(),
        "apnsTokenPresent": Platform.isIOS
            ? (await _messaging.getAPNSToken() != null)
            : true,
        "swizzlingDisabled": true,
        "manualForwarding": true,
        "fcmToken": token,
      },
    }, SetOptions(merge: true));

    debugPrint("✅ FCM TOKEN DIAGNOSTICS SYNCED TO FIRESTORE");
    debugPrint("📱 Platform: ${Platform.operatingSystem}");
    if (Platform.isIOS) {
      final apns = await _messaging.getAPNSToken();
      debugPrint("🍎 APNS Token: ${apns ?? 'MISSING'}");
    }

    // ✅ Subscribe to personal topic for "Exclude Sender" logic in Cloud Functions
    await subscribeToTopic('user_$uid');

    // ✅ NEW: Sync all group memberships to topics for background delivery
    await syncAllUserGroups(uid);

    debugPrint(
      "💾 FCM Token successfully synced and topics balanced for user_$uid",
    );
  }

  /// Fetches all groups a user belongs to and ensures they are subscribed to their FCM topics
  Future<void> syncAllUserGroups(String uid) async {
    try {
      final groupsSnap = await _firestore
          .collection('groups')
          .where('memberIds', arrayContains: uid)
          .get();

      for (var doc in groupsSnap.docs) {
        await subscribeToTopic('group_${doc.id}');
      }
      debugPrint(
        "✅ Synced ${groupsSnap.docs.length} group topics for background delivery.",
      );
    } catch (e) {
      debugPrint("❌ Error syncing group topics: $e");
    }
  }

  Future<void> _handleNotificationTap(RemoteMessage message) async {
    final groupId = message.data['groupId'];
    final sessionId = message.data['sessionId'];
    if (groupId != null) {
      LocationService().setActiveSession(groupId, sessionId);
    }
    if (groupId == null) return;

    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id; // Map constructor expects id field
        final group = GroupModel.fromMap(data);

        // For SOS, we could potentially navigate directly to tracking if it's active
        // But the overlay logic in ChatPage/MapPage will handle it if we just go to the group
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => ChatPage(group: group)),
        );
      }
    } catch (e) {
      debugPrint("❌ Error navigating from notification: $e");
    }
  }

  /// Subscribe to a group topic for notifications
  Future<void> subscribeToGroup(String groupId) async {
    try {
      await _messaging.subscribeToTopic('group_$groupId');
      debugPrint("🚀 [FCM] SUCCESSFULLY subscribed to topic: group_$groupId");
    } catch (e) {
      debugPrint("❌ [FCM] FAILED to subscribe to topic group_$groupId: $e");
    }
  }

  /// Unsubscribe from a group topic
  Future<void> unsubscribeFromGroup(String groupId) async {
    try {
      await _messaging.unsubscribeFromTopic('group_$groupId');
      debugPrint("🔕 Unsubscribed from topic: group_$groupId");
    } catch (e) {
      debugPrint("❌ Error unsubscribing from topic: $e");
    }
  }

  /// Subscribe to all groups the user belongs to
  Future<void> syncGroupSubscriptions(List<String> groupIds) async {
    for (final id in groupIds) {
      await subscribeToTopic('group_$id');
    }
  }

  /// Internal helper to show a local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    debugPrint("🔔 [FCM] Processing manual local notification...");

    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    if (!notificationsEnabled) {
      debugPrint("🛡️ [FCM] Notifications are disabled by user preference.");
      return;
    }

    final senderId = message.data['senderId'];
    final groupId = message.data['groupId'];
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    debugPrint("   - Sender ID: $senderId");
    debugPrint("   - Group ID: $groupId");
    debugPrint("   - Active Group: $activeGroupId");
    debugPrint("   - Current User: $currentUserId");

    // 🛡️ Filter out self-notifications in the foreground
    if (senderId != null && currentUserId != null && senderId == currentUserId) {
      debugPrint("🛡️ [FCM] Suppressing self-notification (Matched Current User)");
      return;
    }

    // 🛡️ Suppress notification if user is already looking at this group
    if (groupId != null && activeGroupId != null && groupId == activeGroupId) {
      debugPrint(
        "🛡️ [FCM] Suppressing foreground notification for ACTIVE group: $groupId",
      );
      return;
    }

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    
    // 🚨 DETECT SOS: Check if it's an SOS alert
    bool isSos = message.data['type'] == 'sos' || 
                 (notification?.title?.contains('SOS') ?? false) || 
                 (notification?.body?.contains('SOS') ?? false);

    if (isSos && groupId != null) {
       LocationService().setActiveSession(groupId, message.data['sessionId']);
    }

    // Extract title and body. For SOS data-only messages on Android, these come from data payload.
    final title = notification?.title ?? message.data['title'] ?? (isSos ? '🚨 EMERGENCY' : 'New Message');
    final body = notification?.body ?? message.data['body'] ?? (isSos ? 'SOS Triggered!' : '');
    // NOTE: CallKit is NOT triggered here (foreground). GlobalSosListener handles
    // showing the SOS overlay when the app is open. CallKit is only for background/lock screen.

    // Show local notification if it's a normal notification OR if it's an SOS (even if data-only)
    if ((notification != null || isSos) && !kIsWeb) {
      _localNotifications.show(
        notification?.hashCode ?? message.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            isSos ? _sosChannel.id : _channel.id,
            isSos ? _sosChannel.name : _channel.name,
            channelDescription: isSos ? _sosChannel.description : _channel.description,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: isSos, // 🔥 WAKES UP THE PHONE ON ANDROID
            category: isSos ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.message,
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: isSos ? InterruptionLevel.critical : InterruptionLevel.active, // 🔥 BYPASS SILENT ON iOS

          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Generic topic subscription
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }
}
