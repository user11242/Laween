import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/colors.dart';
import 'package:laween/l10n/app_localizations.dart';
import 'package:laween/core/message/app_messenger.dart';
import 'forgot_password_page.dart'; // To reuse HeaderCurveClipper

class CreateNewPasswordPage extends StatefulWidget {
  const CreateNewPasswordPage({super.key});

  @override
  State<CreateNewPasswordPage> createState() => _CreateNewPasswordPageState();
}

class _CreateNewPasswordPageState extends State<CreateNewPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordObscured = true;
  bool _isConfirmObscured = true;

  // Validation states for UI
  bool get has8Chars => _passwordController.text.length >= 8;
  bool get hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));

  void _createPassword() {
    final l10n = AppLocalizations.of(context, listen: false)!;
    if (!has8Chars || !hasNumber || !hasUppercase) {
       AppMessenger.showSnackBar(
        context,
        title: l10n.error,
        message: l10n.weakPassword,
        type: MessengerType.error,
      );
      return;
    }
    if (_passwordController.text != _confirmController.text) {
       AppMessenger.showSnackBar(
        context,
        title: l10n.error,
        message: l10n.passwordsDoNotMatch,
        type: MessengerType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    // Mock API call
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
        // Show Success Snackbar as per screenshot
        AppMessenger.showSnackBar(
          context,
          title: l10n.passwordChanged,
          message: l10n.passwordChangedSuccessfully,
          type: MessengerType.success,
        );
        // Navigate to login
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
                    color: AppColors.teal,
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
                  const SizedBox(height: 10),
                   // Decorative dots top left
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildDecorativeDots(AppColors.teal),
                  ),

                  // Central Graphic
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.lock_open_outlined, size: 50, color: AppColors.teal),
                      ),
                      // Dot pattern around
                      Positioned(
                        bottom: 40, right: 10,
                        child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text(
                    l10n.createNewPasswordTitle,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.createNewPasswordSubtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  // New Password Input
                  _buildPasswordField(
                    controller: _passwordController,
                    label: l10n.newPassword,
                    obscured: _isPasswordObscured,
                    onToggle: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                    onChanged: (val) => setState(() {}),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Confirm Password Input
                  _buildPasswordField(
                    controller: _confirmController,
                    label: l10n.confirmPassword,
                    obscured: _isConfirmObscured,
                    onToggle: () => setState(() => _isConfirmObscured = !_isConfirmObscured),
                    onChanged: (val) => setState(() {}),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Requirements Checklist
                  _buildRequirement(l10n.atLeast8Chars, has8Chars),
                  _buildRequirement(l10n.oneNumber, hasNumber),
                  _buildRequirement(l10n.oneUppercase, hasUppercase),

                  const SizedBox(height: 32),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
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
                  
                  const SizedBox(height: 16),
                  
                  TextButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
                    child: Text(
                      l10n.backToLogin,
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscured,
    required VoidCallback onToggle,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscured,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey.shade400,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.teal),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.check_circle_outline,
            size: 20,
            color: isMet ? AppColors.teal : Colors.grey.shade300,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isMet ? const Color(0xFF2D3748) : Colors.grey.shade400,
            ),
          ),
        ],
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
