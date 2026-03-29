import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:laween/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false, // Handle inset manually for cleaner layout
      body: Stack(
        children: [
          // 1. Immersive Background with Sophisticated Tint
          Positioned.fill(
            child: Image.asset(
              "assets/onboarding_imgs/onboarding_img2.jpg",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black,
                  ],
                  stops: const [0.0, 0.4, 0.85],
                ),
              ),
            ),
          ),

          // 2. Modern Header (Top Anchored & Centered)
          Positioned(
            top: 130, // Adjusted down as requested
            left: 40,
            right: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  loc.loginTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.0,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 12), // Compact bar spacing
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16), // Compact subtitle spacing
                Text(
                  loc.loginSubtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // 3. The "Frosted Pane" (Bottom Anchored Auth Area)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(48)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  padding: EdgeInsets.only(
                    left: 28,
                    right: 28,
                    top: 12, // Ultra-compact height
                    bottom: MediaQuery.of(context).viewInsets.bottom + 40,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(48)),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 0.5,
                    ),
                  ),
                  child: const LoginForm(),
                ),
              ),
            ),
          ),

          // 4. Back Button (Floats at very top)
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: Icon(
                loc.isAr ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
                color: Colors.white.withValues(alpha: 0.5),
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
