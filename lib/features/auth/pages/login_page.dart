import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:laween/l10n/app_localizations.dart';
import 'package:laween/core/providers/locale_provider.dart';
import '../widgets/login_form.dart';

class LoginCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, 80);
    path.quadraticBezierTo(size.width * 0.2, 0, size.width * 0.5, 30);
    path.quadraticBezierTo(size.width * 0.8, 60, size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final loc = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.65,
            child: Image.asset(
              "assets/onboarding_imgs/onboarding_img2.jpg",
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.65,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF006D77).withValues(alpha: 0.8),
                    const Color(0xFF006D77).withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),
          // Header Text
          Positioned(
            top: screenHeight * 0.25,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  loc.loginTitle,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.loginSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Logo and Language Toggle
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: IconButton(
                        icon: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Icon(
                            loc.isAr ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new, 
                            color: Colors.white, 
                            size: 18
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: screenHeight * 0.45,
            child: ClipPath(
              clipper: LoginCurveClipper(),
              child: Container(
                color: Colors.white,
                child: const SingleChildScrollView(
                  physics: ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(32, 80, 32, 32),
                  child: LoginForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
