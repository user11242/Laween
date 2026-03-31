import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:laween/features/auth/data/services/fcm_service.dart';
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
import 'package:laween/core/theme/colors.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize FCM Notification Handlers
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FcmService.instance.initialize();

  // Initialize Google Sign-In
  await GoogleAuthService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => LocaleProvider())],
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.teal),
        useMaterial3: true,
      ),
      builder: (context, child) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
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
