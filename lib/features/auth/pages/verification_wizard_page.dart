import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laween/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../auth/data/services/auth_service.dart';
import '../widgets/verification/universal_otp_step.dart';
import '../widgets/verification/finish_verification_step.dart';

class VerificationWizardPage extends StatefulWidget {
  final String email;
  final String password;
  final String phone;
  final String name;
  final bool acceptedTerms;
  final String? language;
  final String? fcmToken;

  const VerificationWizardPage({
    super.key,
    required this.email,
    required this.password,
    required this.phone,
    required this.name,
    required this.acceptedTerms,
    this.language,
    this.fcmToken,
  });

  @override
  State<VerificationWizardPage> createState() => _VerificationWizardPageState();
}

class _VerificationWizardPageState extends State<VerificationWizardPage> {
  final AuthService _authService = AuthService();
  GlobalKey<UniversalOtpStepState> _otpKey = GlobalKey<UniversalOtpStepState>();

  int _step = 0;
  bool isLoading = false;

  int get currentStepIndex => _step + 1;
  int get totalStepsCount => 3;

  @override
  void initState() {
    super.initState();
    _step = 0; // Start at OTP step
  }

  void _goToNextStep() {
    setState(() {
      _otpKey = GlobalKey<UniversalOtpStepState>();
      _step++;
    });
  }

  Future<void> _handleCancel() async {
    // Cleanup any ghost account (Auth record without Firestore doc)
    setState(() => isLoading = true);
    await _authService.cleanupGhostAccount();
    if (mounted) {
      setState(() => isLoading = false);
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _handlePrimaryAction() async {
    await _finishRegistration();
  }

  Future<void> _finishRegistration() async {
    debugPrint("DEBUG: _finishRegistration started");
    final navigator = Navigator.of(context);
    setState(() => isLoading = true);

    try {
      final error = await _authService.registerWithEmail(
        name: widget.name,
        email: widget.email,
        password: widget.password,
        confirmPassword: widget.password,
        phone: widget.phone,
        acceptedTerms: widget.acceptedTerms,
        language: widget.language,
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      if (error == null) {
        // ✅ Save FCM Token immediately after successful registration
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          // If we already pre-fetched the token, save it directly
          if (widget.fcmToken != null) {
            await FirebaseFirestore.instance
                .collection("users")
                .doc(currentUser.uid)
                .update({
                  "fcmToken": widget.fcmToken,
                  "lastTokenUpdate": FieldValue.serverTimestamp(),
                });
          } else {
            await _authService.saveUserFcmToken(currentUser.uid);
          }
        }

        navigator.pop(true);
      } else {
        _showDetailedErrorDialog("Registration Error", error);
      }
    } catch (e, stack) {
      if (mounted) setState(() => isLoading = false);
      _showDetailedErrorDialog("Crash in Registration", "$e\n$stack");
    }
  }

  void _showDetailedErrorDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.redAccent)),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey<int>(_step),
        child: _step == 0
            ? UniversalOtpStep(
                key: _otpKey,
                destination: widget.email,
                onVerified: _goToNextStep,
                isLight: true,
              )
            : _step == 1
                ? UniversalOtpStep(
                    key: _otpKey,
                    destination: widget.phone,
                    onVerified: _goToNextStep,
                    isLight: true,
                  )
                : const FinishVerificationStep(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return PopScope(
      canPop: !isLoading,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _authService.cleanupGhostAccount();
        if (context.mounted) Navigator.pop(context, false);
      },
      child: Material(
        type: MaterialType.transparency,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with Progress
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withOpacity(0.03),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.black.withOpacity(0.05),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _step == 2 ? l10n.allDone : l10n.verifyIdentity,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.teal,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.stepOf(currentStepIndex, totalStepsCount),
                                      style: TextStyle(
                                        color: Colors.black.withOpacity(0.4),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 18, color: Colors.black54),
                                  ),
                                  onPressed: _handleCancel,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Progress bar
                            Row(
                              children: List.generate(totalStepsCount, (index) {
                                final bool isCompleted = index < _step;
                                final bool isActive = index == _step;
                                return Expanded(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: EdgeInsets.only(
                                      right: index < totalStepsCount - 1 ? 8 : 0,
                                    ),
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? AppColors.teal
                                          : isActive
                                              ? AppColors.teal.withOpacity(0.3)
                                              : Colors.black.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: _buildStepContent(),
                      ),
                      
                      // Footer (only for final step)
                      if (_step == 2)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: isLoading ? null : _handlePrimaryAction,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      l10n.finishAndRegister,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
