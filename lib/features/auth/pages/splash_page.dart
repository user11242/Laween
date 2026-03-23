import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';
import '../../../core/services/biometric_service.dart';
import 'onboarding_page.dart';
import '../../home/pages/home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Allow the animations to start, then route
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Enforce a minimum display time for the splash screen so the user can enjoy the "wow" animation
    await Future.delayed(const Duration(milliseconds: 2800));
    
    if (!mounted) return;

    // 2. Determine where to route the user
    Widget nextScreen = const OnboardingPage(); // Default

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User is logged in, check app lock
      final isLocked = await BiometricService().isAppLocked();
      
      if (!isLocked) {
        // Not locked, check profile
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (doc.exists) {
            nextScreen = const HomePage();
          }
        } catch (e) {
          debugPrint("Splash page Firestore error: \$e");
        }
      }
    }

    // 3. Smooth transition to the next screen
    if (mounted) {
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => nextScreen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set system status bar color for the splash screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, 
      ),
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.tealGradient,
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // --- Cinematic Background Orbs ---
            Positioned(
              top: -100,
              left: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.lightGold.withValues(alpha: 0.15),
                  boxShadow: [
                    BoxShadow(color: AppColors.lightGold.withValues(alpha: 0.15), blurRadius: 40, spreadRadius: 10)
                  ],
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .move(begin: const Offset(0, 0), end: const Offset(50, 50), duration: 4.seconds, curve: Curves.easeInOutSine),
            ),
            
            Positioned(
              bottom: -50,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(color: Colors.white.withValues(alpha: 0.1), blurRadius: 50, spreadRadius: 10)
                  ],
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .move(begin: const Offset(0, 0), end: const Offset(-80, -40), duration: 5.seconds, curve: Curves.easeInOut),
            ),
            
            // --- Foreground Main Sequence ---
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. The 3D Spin-in & Shimmer Logo
                Image.asset(
                  'assets/logo/Laween_transparent_iphone.png',
                  width: 140,
                  height: 140,
                  fit: BoxFit.contain,
                ).animate()
                 // Scale from zero with an elastic bounce
                 .scale(begin: const Offset(0, 0), end: const Offset(1.0, 1.0), duration: 1200.ms, curve: Curves.elasticOut)
                 // Spin in as it scales
                 .rotate(begin: 0.5, end: 0, duration: 1000.ms, curve: Curves.easeOutBack)
                 // After it lands, sweep a beautiful shimmer across it
                 .then(delay: 200.ms)
                 .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.8), angle: 0.5)
                 // And add a very slow, continuous floating effect
                 .then()
                 .slideY(begin: 0, end: -0.03, duration: 2.seconds, curve: Curves.easeInOutSine)
                 .then()
                 .slideY(begin: -0.03, end: 0, duration: 2.seconds, curve: Curves.easeInOutSine),
                
                const SizedBox(height: 32),
                
                // 2. The Clean Text Reveal
                Text(
                  "Laween",
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 3.0,
                    height: 1.0,
                  ),
                ).animate()
                 // Start hidden
                 .fadeIn(delay: 800.ms, duration: 800.ms)
                 // Slight slide up
                 .slideY(begin: 0.2, end: 0, delay: 800.ms, duration: 800.ms, curve: Curves.easeOutQuart)
                 // Shimmer sweeps right after the logo shimmer
                 .then(delay: 100.ms)
                 .shimmer(duration: 1200.ms, color: AppColors.lightGold, angle: 1.0),
                 
                 const SizedBox(height: 8),
                 
                 // 3. The Cinematic Blur-in Subtitle
                 Directionality(
                   textDirection: TextDirection.ltr,
                   child: Text(
                    "Where do we go next?",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 1.0,
                    ),
                   ),
                 ).animate()
                 // Cinematic Blur-in reveal
                 .fadeIn(delay: 1600.ms, duration: 1000.ms)
                 .blur(begin: const Offset(10, 0), end: Offset.zero, delay: 1600.ms, duration: 1000.ms, curve: Curves.easeOut),

              ],
            ),
          ],
        ),
      ),
    );
  }
}
