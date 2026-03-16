import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:laween/l10n/app_localizations.dart';
import 'package:laween/core/message/app_messenger.dart';
import 'forgot_password_page.dart'; // To reuse HeaderCurveClipper
import 'dart:async';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  late PinInputController _otpController;
  bool _isLoading = false;
  late String _phoneNumber;
  int _secondsRemaining = 150; // 2:30
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _otpController = PinInputController();
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _phoneNumber = (ModalRoute.of(context)?.settings.arguments as String?) ?? "+96212345678";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  String _getFormattedTime() {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  void _verify() {
    final l10n = AppLocalizations.of(context, listen: false)!;
    if (_otpController.text.length != 6) {
      AppMessenger.showSnackBar(
        context,
        title: l10n.error,
        message: l10n.enter6Digits,
        type: MessengerType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    // Mock API call
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        // Navigate to Create New Password
        Navigator.pushNamed(context, '/create_new_password');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;

    // Mask phone number
    String maskedPhone = _phoneNumber;
    if (_phoneNumber.length > 7) {
      maskedPhone = "${_phoneNumber.substring(0, 5)}******${_phoneNumber.substring(_phoneNumber.length - 2)}";
    }

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
                            l10n.verification,
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
                  // Decorative dots top left
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildDecorativeDots(const Color(0xFF006D77)),
                  ),

                  // Central Graphic
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFF006D77).withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFF006D77).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.phonelink_ring_outlined, size: 50, color: Color(0xFF006D77)),
                      ),
                      // Dot pattern around
                      Positioned(
                        bottom: 40, right: 10,
                        child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF006D77), shape: BoxShape.circle)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  Text(
                    l10n.enterOtp,
                    style: GoogleFonts.inter(
                      fontSize: 40,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${l10n.weSentCodeTo} $maskedPhone",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),

                  const SizedBox(height: 48),

                  MaterialPinField(
                    length: 6,
                    pinController: _otpController,
                    keyboardType: TextInputType.number,
                    theme: MaterialPinTheme(
                      shape: MaterialPinShape.outlined,
                      borderRadius: BorderRadius.circular(12),
                      cellSize: const Size(50, 56),
                      fillColor: Colors.grey.shade50,
                      focusedFillColor: Colors.white,
                      filledFillColor: Colors.white,
                      borderColor: Colors.grey.shade300,
                      focusedBorderColor: const Color(0xFF006D77),
                      filledBorderColor: const Color(0xFF006D77),
                      textStyle: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF006D77),
                      ),
                    ),
                    onChanged: (value) {},
                  ),

                  const SizedBox(height: 32),

                  Text(
                    l10n.resendCodeIn(_getFormattedTime()),
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Continue Button
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
                              l10n.continueText,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
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
