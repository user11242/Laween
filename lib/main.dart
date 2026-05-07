import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:laween/features/auth/data/services/fcm_service.dart';
import 'package:laween/features/groups/widgets/global_sos_listener.dart';
import 'package:laween/features/groups/pages/chat_page.dart';
import 'package:laween/features/groups/data/models/group_model.dart';
import 'package:laween/features/auth/pages/verification_wizard_page.dart';
import 'package:laween/features/auth/pages/verification_page.dart';
import 'package:laween/features/home/pages/home_page.dart';
import 'package:laween/features/auth/data/services/google_auth_service.dart';
import 'package:laween/features/auth/pages/splash_page.dart';
import 'package:laween/core/providers/locale_provider.dart';
import 'package:laween/features/auth/pages/forgot_password_page.dart';
import 'package:laween/features/auth/pages/create_new_password_page.dart';
import 'package:laween/features/auth/pages/login_page.dart';
import 'package:laween/features/auth/pages/register_page.dart';
import 'package:laween/features/groups/providers/wallpaper_provider.dart';
import 'package:laween/core/providers/theme_provider.dart';
import 'package:laween/core/theme/colors.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'firebase_options.dart';
import 'package:laween/core/services/location_service.dart';
import 'package:intl/date_symbol_data_local.dart';

/// 🚨 Show the full-screen CallKit SOS alert (works on lock screen & background)
Future<void> showSosCallkit({
  required String callerName,
  String? groupId,
  String? sessionId,
}) async {
  final callUUID = const Uuid().v4();
  final params = CallKitParams(
    id: callUUID,
    nameCaller: '🚨 SOS: $callerName',
    appName: 'Laween',
    handle: 'Emergency Alert',
    type: 0, // 0 = audio call style
    duration: 45000, // Ring for 45 seconds
    textAccept: 'SEE MAP',
    textDecline: 'DISMISS',
    missedCallNotification: const NotificationParams(
      showNotification: true,
      isShowCallback: false,
      subtitle: 'SOS Emergency Alert',
      callbackText: 'Open App',
    ),
    extra: <String, dynamic>{
      'groupId': groupId ?? '',
      'sessionId': sessionId ?? '',
    },
    android: const AndroidParams(
      isCustomNotification: true,
      isShowLogo: false,
      ringtonePath: 'system_ringtone_default',
      backgroundColor: '#FF0000',
      actionColor: '#FF4444',
      isShowFullLockedScreen: true, // 🔥 Shows on lock screen
    ),
    ios: const IOSParams(
      iconName: 'AppIcon',
      handleType: 'generic',
      supportsVideo: false,
      maximumCallGroups: 1,
      maximumCallsPerCallGroup: 1,
      audioSessionMode: 'default',
      audioSessionActive: true,
      audioSessionPreferredSampleRate: 44100.0,
      audioSessionPreferredIOBufferDuration: 0.005,
      ringtonePath: 'system_ringtone_default',
    ),
  );

  await FlutterCallkitIncoming.showCallkitIncoming(params);
  debugPrint('🚨 CallKit SOS displayed for: $callerName (uuid: $callUUID)');
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");

  final isSos =
      message.data['type'] == 'sos' ||
      (message.notification?.title?.contains('SOS') ?? false) ||
      (message.notification?.body?.contains('SOS') ?? false);

  final groupId = message.data['groupId'];
  final sessionId = message.data['sessionId'];

  if (isSos && groupId != null) {
    // Try to update Firestore so the app wakes up with the correct active group AND session
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'activeGroupId': groupId,
          'activeSessionId': sessionId ?? '',
        });
        debugPrint(
          "🚨 Background SOS: Updated activeGroupId to $groupId, session to $sessionId",
        );
      }
    } catch (e) {
      debugPrint("Error updating activeGroupId in background: $e");
    }

    // 🔥 SHOW FULL-SCREEN CALLKIT ALERT (works on lock screen!)
    final senderName =
        message.data['title'] ?? message.notification?.title ?? 'Someone';
    await showSosCallkit(
      callerName: senderName,
      groupId: groupId,
      sessionId: sessionId,
    );
    debugPrint("🚨 Background SOS: CallKit alert triggered!");
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Global system UI style is now managed dynamically in MaterialApp.builder

  await initializeDateFormatting('en', null);
  await initializeDateFormatting('ar', null);

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint("🔴🔴🔴 GLOBAL FLUTTER ERROR 🔴🔴🔴");
    debugPrint(details.exceptionAsString());
    debugPrint(details.stack.toString());
    debugPrint("🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴");
  };

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize FCM Notification Handlers
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 🔥 DIAGNOSTIC FIX: Disable offline persistence entirely to bypass corrupted cache locks
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    debugPrint("✅ Disabled Firestore Persistence. Cache bypassed.");
  } catch (e) {
    debugPrint("Failed to set Firestore settings: $e");
  }

  // 🔥 FIRESTORE DATABASE SURROGATE CLEANER
  try {
    debugPrint("🧹 Scanning database for corrupt UTF-16 surrogates...");
    String sanitizeData(dynamic input) {
      if (input == null) return '';
      String str = input.toString();
      List<int> cleanUnits = [];
      for (int i = 0; i < str.length; i++) {
        int c = str.codeUnitAt(i);
        if (c >= 0xD800 && c <= 0xDBFF) {
          if (i + 1 < str.length) {
            int n = str.codeUnitAt(i + 1);
            if (n >= 0xDC00 && n <= 0xDFFF) {
              cleanUnits.add(c);
              cleanUnits.add(n);
              i++;
            } else {
              cleanUnits.add(0xFFFD);
            }
          } else {
            cleanUnits.add(0xFFFD);
          }
        } else if (c >= 0xDC00 && c <= 0xDFFF) {
          cleanUnits.add(0xFFFD);
        } else {
          cleanUnits.add(c);
        }
      }
      return String.fromCharCodes(cleanUnits);
    }

    final firestore = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final uDoc = await firestore.collection('users').doc(uid).get();
      if (uDoc.exists) {
        final data = uDoc.data()!;
        if (data['name'] != null &&
            sanitizeData(data['name']) != data['name']) {
          await uDoc.reference.update({'name': sanitizeData(data['name'])});
          debugPrint("✅ Repaired corrupt user name in DB!");
        }
      }
    }

    final gQuery = await firestore.collection('groups').get();
    for (var doc in gQuery.docs) {
      final data = doc.data();
      Map<String, dynamic> updates = {};
      if (data['name'] != null && sanitizeData(data['name']) != data['name']) {
        updates['name'] = sanitizeData(data['name']);
      }
      if (data['lastMessage'] != null &&
          sanitizeData(data['lastMessage']) != data['lastMessage']) {
        updates['lastMessage'] = sanitizeData(data['lastMessage']);
      }
      if (data['lastMessageSender'] != null &&
          sanitizeData(data['lastMessageSender']) !=
              data['lastMessageSender']) {
        updates['lastMessageSender'] = sanitizeData(data['lastMessageSender']);
      }
      if (updates.isNotEmpty) {
        await doc.reference.update(updates);
        debugPrint("✅ Repaired corrupt group ${doc.id} in DB!");
      }
    }
    debugPrint("🧹 Database scan complete.");
  } catch (e) {
    debugPrint("Database scan failed: $e");
  }

  // 🎵 GLOBAL AUDIO CONFIG: Ensure sound plays even in silent mode (iOS/macOS)
  AudioPlayer.global.setAudioContext(
    AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playAndRecord,
        options: {
          AVAudioSessionOptions.mixWithOthers,
          AVAudioSessionOptions.defaultToSpeaker,
        },
      ),
      android: const AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
    ),
  );

  await FcmService.instance.initialize();

  // Initialize Google Sign-In
  await GoogleAuthService.instance.initialize();

  // 🔥 CallKit VoIP Push Listener
  FlutterCallkitIncoming.onEvent.listen((event) async {
    if (event == null) return;
    debugPrint('📱 CallKit Event: ${event.event}');
    switch (event.event) {
      case Event.actionCallAccept:
        // User tapped accept on the CallKit screen.
        // 1. End the fake "call" immediately so the phone UI disappears
        // 2. The real SOS overlay (red alarm screen) will take over in the app
        final data = event.body;
        final callId = data['id'];
        if (callId != null) {
          await FlutterCallkitIncoming.endCall(callId);
        }

        final groupId = data['extra']?['groupId'] ?? data['groupId'];
        final sessionId = data['extra']?['sessionId'] ?? data['sessionId'];

        debugPrint(
          '🚨 CallKit ACCEPTED - groupId: $groupId, sessionId: $sessionId',
        );

        if (groupId != null && groupId.toString().isNotEmpty) {
          // Update Firestore so GlobalSosListener picks it up instantly
          LocationService().setActiveSession(groupId, sessionId);

          // Navigate directly to the group chat where SOS overlay will show
          try {
            final doc = await FirebaseFirestore.instance
                .collection('groups')
                .doc(groupId)
                .get();
            if (doc.exists) {
              final docData = doc.data()!;
              docData['id'] = doc.id;
              final group = GroupModel.fromMap(docData);
              // Small delay to ensure app is fully launched
              await Future.delayed(const Duration(milliseconds: 500));
              navigatorKey.currentState?.push(
                MaterialPageRoute(builder: (context) => ChatPage(group: group)),
              );
            }
          } catch (e) {
            debugPrint('❌ Error navigating from CallKit accept: $e');
          }
        }
        break;
      case Event.actionCallDecline:
        // User dismissed the SOS alert
        debugPrint('📱 CallKit SOS Declined/Dismissed');
        // End the call in CallKit
        final declineData = event.body;
        if (declineData['id'] != null) {
          await FlutterCallkitIncoming.endCall(declineData['id']);
        }
        break;
      case Event.actionDidUpdateDevicePushTokenVoip:
        debugPrint("📱 APNs VoIP Token Event Received!");
        try {
          final voipToken = event.body?['deviceToken'];
          if (voipToken != null && voipToken is String) {
            debugPrint("✅ Safely extracted VoIP Token from event: $voipToken");
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid != null) {
              FirebaseFirestore.instance.collection('users').doc(uid).set({
                'voipToken': voipToken,
                'tokenDiagnostics': {'voipToken': voipToken},
              }, SetOptions(merge: true));
              debugPrint("💾 Saved VoIP Token to Firestore Profile.");
            }
          }
        } catch (e) {
          debugPrint("❌ Error parsing VoIP token from event: $e");
        }
        break;
      case Event.actionCallEnded:
        debugPrint('📱 CallKit call ended');
        break;
      default:
        break;
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => WallpaperProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isAr = localeProvider.locale.languageCode == 'ar';

    return MaterialApp(
      title: 'Laween',
      debugShowCheckedModeBanner: false,
      locale: localeProvider.locale,
      themeMode: context.watch<ThemeProvider>().themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          brightness: Brightness.light,
          primary: AppColors.teal,
          secondary: AppColors.tealLight,
          surface: Colors.white,
          error: Colors.redAccent,
        ),
        scaffoldBackgroundColor: const Color(
          0xFFF8F9FB,
        ), // Modern light mode background
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F9FB),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Color(0xFF1A1D2E)),
          titleTextStyle: TextStyle(
            color: Color(0xFF1A1D2E),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.teal,
          unselectedItemColor: Color(0xFF94A3B8),
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          brightness: Brightness.dark,
          primary: AppColors.teal,
          secondary: AppColors.tealLight,
          surface: const Color(0xFF1F1F1F),
          error: Colors.redAccent,
        ),
        scaffoldBackgroundColor: const Color(
          0xFF121212,
        ), // Deep dark mode background
        cardTheme: CardThemeData(
          color: const Color(0xFF2C2C2C),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1F1F1F),
          selectedItemColor: AppColors.teal,
          unselectedItemColor: Color(0xFF94A3B8),
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1F1F1F),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2D3748), width: 1),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF1F1F1F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF1F1F1F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        useMaterial3: true,
      ),
      navigatorKey: navigatorKey,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: isDark
                ? const Color(0xFF121212)
                : const Color(0xFFF8F9FB),
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: GlobalSosListener(child: child!),
          ),
        );
      },
      home: const SplashPage(),
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/forgot_password_verify': (context) => const VerificationPage(),
        '/create_new_password': (context) => const CreateNewPasswordPage(),
        '/login_otp': (context) => const VerificationPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/verification') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => VerificationWizardPage(
              email: args['email'],
              password: args['password'],
              phone: args['phone'],
              name: args['name'],
              acceptedTerms: args['acceptedTerms'] ?? true,
              language: args['language'],
              fcmToken: args['fcmToken'],
            ),
          );
        }
        return null;
      },
    );
  }
}
