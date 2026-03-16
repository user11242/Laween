import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:laween/l10n/app_localizations.dart';
import 'package:laween/core/message/app_messenger.dart';
// For LoginCurveClipper if needed, but I'll define a header clipper

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5, size.height - 30);
    path.quadraticBezierTo(size.width * 0.75, size.height - 60, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _phoneController = TextEditingController();
  final String _initialCountryCode = 'JO';
  String _fullPhoneNumber = '';
  bool _isLoading = false;

  void _verify() {
    final l10n = AppLocalizations.of(context, listen: false)!;
    if (_phoneController.text.isEmpty) {
      AppMessenger.showSnackBar(
        context,
        title: l10n.error,
        message: l10n.enterPhoneError,
        type: MessengerType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    // Mock API call
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
        // Navigate to OTP page
        Navigator.pushNamed(context, '/forgot_password_verify', arguments: _fullPhoneNumber);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Stack(
              children: [
                ClipPath(
                  clipper: HeaderCurveClipper(),
                  child: Container(
                    height: screenHeight * 0.25,
                    width: double.infinity,
                    color: const Color(0xFF006D77),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Transform.flip(
                                flipX: l10n.isAr,
                                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            l10n.resetPassword,
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Central Graphic
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Circular background for the icon
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFF006D77).withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                      // Dot pattern around the icon (simulated)
                      Positioned(
                        top: 20, right: 10,
                        child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF006D77), shape: BoxShape.circle)),
                      ),
                      Positioned(
                        bottom: 30, left: 15,
                        child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF006D77), shape: BoxShape.circle)),
                      ),
                      // The Icon/Graphic
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD166).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.mail_outline, size: 50, color: Color(0xFFFFD166)),
                      ),
                      // Floating dots near graphics
                      Positioned(
                        top: 0, left: 0,
                        child: _buildDecorativeDots(const Color(0xFF006D77)),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    l10n.resetYourPassword,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.resetPasswordDesc,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Phone Input
                  Align(
                    alignment: l10n.isAr ? Alignment.centerRight : Alignment.centerLeft,
                    child: Text(
                      l10n.phoneNumber,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  IntlPhoneField(
                    controller: _phoneController,
                    initialCountryCode: _initialCountryCode,
                    onChanged: (phone) => _fullPhoneNumber = phone.completeNumber,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFF006D77)),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Send Code Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006D77),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              l10n.sendCode,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      l10n.backToLogin,
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Bottom decorative dots
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildDecorativeDots(const Color(0xFF006D77)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeDots(Color color) {
    return Column(
      children: [
        Row(
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          ],
        ),
        const SizedBox(height: 8),
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ],
    );
  }
}
