import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:laween/l10n/app_localizations.dart';
import 'package:laween/core/providers/locale_provider.dart';
import 'package:laween/features/auth/pages/login_page.dart';
import 'package:laween/features/auth/pages/register_page.dart';
import 'package:laween/features/auth/pages/google_register_wizard.dart';
import 'package:laween/features/auth/widgets/link_account_dialog.dart';
import 'package:laween/features/auth/data/services/auth_service.dart';
import 'package:laween/core/theme/colors.dart';
import 'package:laween/core/message/app_messenger.dart';
import 'package:laween/core/services/biometric_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  bool _isGoogleLoading = false;
  final AuthService _authService = AuthService();
  
  String _localizeError(String error, AppLocalizations l10n) {
    if (error.contains("ACCOUNT_EXISTS_DIFFERENT_CREDENTIAL")) {
       return l10n.isAr ? "هذا الحساب مسجل بالفعل بطريقة دخول أخرى. يرجى استخدام البريد الإلكتروني وكلمة المرور." : "This account is already registered with a different sign-in method. Please use email and password.";
    }
    if (error.toLowerCase().contains("canceled") || error.toLowerCase().contains("cancel")) return "";
    return error;
  }

  @override
  void initState() {
    super.initState();
    // 🧙 Check if we have a "Ghost" user (LoggedIn but NEEDS_ROLE) on start
    // This handles the case where AuthWrapper stayed on Onboarding but user is authed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingGoogleUser();
    });
  }

  Future<void> _checkExistingGoogleUser() async {
    // 🛡️ Ensure we don't auto-login if the app is currently locked by Face ID.
    final isLocked = await BiometricService().isAppLocked();
    if (isLocked) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final isGoogle = user.providerData.any((p) => p.providerId == 'google.com');
      if (isGoogle) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        
        if (!mounted) return;

        if (doc.exists) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        } else {
          _showRegisterWizard();
        }
      }
    }
  }

  void _showRegisterWizard() {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, __) => const GoogleRegisterWizard(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    if (_isGoogleLoading) return;
    final loc = AppLocalizations.of(context, listen: false)!;
    setState(() => _isGoogleLoading = true);

    try {
      final result = await _authService.loginWithGoogle();
      
      if (!mounted) return;

      if (result == null) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else if (result == "NEEDS_PROFILE") {
        _showRegisterWizard();
      } else if (result == "ACCOUNT_EXISTS_DIFFERENT_CREDENTIAL") {
        final email = _authService.googleAuth.pendingEmail;
        if (email != null) {
          final linked = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => LinkAccountDialog(email: email),
          );
          
          if (linked == true && mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          }
        }
      } else if (result != "NEEDS_PROFILE") {
        final localizedError = _localizeError(result, loc);
        if (localizedError.isNotEmpty) {
          AppMessenger.showSnackBar(
            context,
            title: loc.error,
            message: localizedError,
            type: MessengerType.error,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      AppMessenger.showSnackBar(
        context,
        title: loc.error,
        message: e.toString(),
        type: MessengerType.error,
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/onboarding_imgs/onboarding_img1.jpg',
              fit: BoxFit.cover,
            ),
          ),
          
          // Gradient Overlay to make text readable (darkened as requested)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.65),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),
          
          // Language Switcher
          Positioned(
            top: 60,
            right: 24,
            child: GestureDetector(
              onTap: () {
                Provider.of<LocaleProvider>(context, listen: false).toggleLanguage();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.language, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      loc.isAr ? 'English' : 'عربي',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Text(
                    loc.onboardingTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.onboardingSubtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Google Button
                  ElevatedButton(
                    onPressed: _isGoogleLoading ? null : _handleGoogleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: _isGoogleLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 18,
                                  ),
                                  children: const [
                                    TextSpan(text: 'G', style: TextStyle(color: Color(0xFF4285F4))),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                loc.joinWithGoogle,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Email Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal, // Teal color matched from design
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.email, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          loc.joinWithEmail,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Sign In Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        loc.alreadyHaveAccount,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          );
                        },
                        child: Text(
                          loc.signIn,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFF4A261), // Orange matched from design
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
