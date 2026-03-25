import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/colors.dart';
import '../widgets/register_form.dart';
import '../../../l10n/app_localizations.dart';

class SignupHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(size.width / 2, size.height + 20, size.width, size.height - 50);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header & Avatar Stack
            SizedBox(
              height: screenHeight * 0.28 + 44,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Header
                  ClipPath(
                    clipper: SignupHeaderClipper(),
                    child: Container(
                      height: screenHeight * 0.28,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.teal,
                        image: DecorationImage(
                          image: AssetImage('assets/onboarding_imgs/onboarding_img2.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.teal.withValues(alpha: 0.9),
                              AppColors.teal.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.chevron_left,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    AppLocalizations.of(context)!.createAccount,
                                    style: AppLocalizations.of(context)!.isAr
                                        ? GoogleFonts.cairo(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          )
                                        : GoogleFonts.nunito(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Profile Icon Placeholder Overlapping
                  Positioned(
                    bottom: 0,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.teal.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade200, width: 1),
                            ),
                            child: Icon(
                              Icons.add_a_photo_outlined,
                              size: 38,
                              color: AppColors.teal.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            ),
                            child: const Icon(
                              Icons.add_circle,
                              size: 26,
                              color: AppColors.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              AppLocalizations.of(context)!.welcome,
              style: AppLocalizations.of(context)!.isAr
                  ? GoogleFonts.cairo(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.teal,
                      letterSpacing: -0.5,
                    )
                  : GoogleFonts.nunito(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.teal,
                      letterSpacing: -0.5,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.welcomeSubtitle,
              textAlign: TextAlign.center,
              style: AppLocalizations.of(context)!.isAr
                  ? GoogleFonts.cairo(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    )
                  : GoogleFonts.nunito(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
            ),
            
            const SizedBox(height: 32),
            
            // Form
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: RegisterForm(),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

