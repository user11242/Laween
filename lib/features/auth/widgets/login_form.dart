import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/colors.dart';
import '../../../features/auth/widgets/link_account_dialog.dart';
import '../../../features/auth/data/services/auth_service.dart';
import '../../../core/message/app_messenger.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/services/biometric_service.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _authService = AuthService();
  final _biometricService = BiometricService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isBiometricAvailable = false;
  bool _emailFocused = false;
  bool _passwordFocused = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _emailFocusNode.addListener(
        () => setState(() => _emailFocused = _emailFocusNode.hasFocus));
    _passwordFocusNode.addListener(
        () => setState(() => _passwordFocused = _passwordFocusNode.hasFocus));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    final available = await _biometricService.isBiometricAvailable();
    if (mounted) setState(() => _isBiometricAvailable = available);
  }

  void _showFaceIdUnavailableDialog() {
    final l10n = AppLocalizations.of(context, listen: false)!;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.grey, size: 24),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.error_outline, color: Colors.red, size: 40),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                l10n.faceIdUnavailableTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.faceIdUnavailableMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _emailFocusNode.requestFocus();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.useEmailAndPassword,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;
    await _performGoogleLogin(silent: false);
  }

  Future<void> _performGoogleLogin({bool silent = false}) async {
    final l10n = AppLocalizations.of(context, listen: false)!;
    setState(() => _isLoading = true);
    try {
      final result = await _authService.loginWithGoogle(silent: silent);
      if (silent && result == "SILENT_SIGN_IN_FAILED") {
        await _performGoogleLogin(silent: false);
        return;
      }
      if (!mounted) return;
      if (result == null) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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
        if (result == "CANCELED") return;
        AppMessenger.showSnackBar(context, title: l10n.error, message: result, type: MessengerType.error);
      }
    } catch (e) {
      if (mounted) AppMessenger.showSnackBar(context, title: l10n.error, message: e.toString(), type: MessengerType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (_isLoading) return;
    final l10n = AppLocalizations.of(context, listen: false)!;
    final isEnabled = await _biometricService.isBiometricEnabled();
    if (!isEnabled) {
      _showFaceIdUnavailableDialog();
      return;
    }
    final authenticated = await _biometricService.authenticate(
      reason: l10n.isAr ? "قم بتسجيل الدخول باستخدام البصمة" : "Authenticate to log in to Laween",
    );
    if (!authenticated) return;
    setState(() => _isLoading = true);
    try {
      final result = await _authService.loginWithBiometrics();
      if (!mounted) return;
      if (result == null) {
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else if (result == "SOCIAL_LOGIN_REQUIRED") {
        await _performGoogleLogin(silent: true);
      } else if (result == "NO_SAVED_CREDENTIALS") {
        AppMessenger.showSnackBar(
          context,
          title: l10n.error,
          message: l10n.isAr
              ? "لم يتم العثور على بيانات مسجلة. يرجى تسجيل الدخول يدوياً أولاً."
              : "No saved credentials found. Please log in manually first.",
          type: MessengerType.error,
        );
      } else {
        AppMessenger.showSnackBar(context, title: l10n.error, message: result, type: MessengerType.error);
      }
    } catch (e) {
      if (mounted) AppMessenger.showSnackBar(context, title: l10n.error, message: e.toString(), type: MessengerType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEnableBiometricDialog(String email, String password) {
    final l10n = AppLocalizations.of(context, listen: false)!;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Icon(Icons.fingerprint, color: AppColors.teal, size: 40)),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.isAr ? "تفعيل تسجيل الدخول بالبصمة؟" : "Enable Biometric Login?",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.isAr
                    ? "هل تريد استخدام بصمة الإصبع أو الوجه لتسجيل الدخول في المرات القادمة؟"
                    : "Would you like to use Face ID or Fingerprint for faster login next time?",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        l10n.isAr ? "ليس الآن" : "Not now",
                        style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          await _biometricService.saveCredentials(email, password);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          AppMessenger.showSnackBar(
                            context,
                            title: l10n.isAr ? "تم التفعيل" : "Enabled",
                            message: l10n.isAr ? "تم تفعيل تسجيل الدخول بالبصمة بنجاح" : "Biometric login enabled successfully",
                            type: MessengerType.success,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
                        ),
                        child: Text(
                          l10n.isAr ? "تفعيل" : "Enable",
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    });
  }

  Future<void> _handleContinue() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final l10n = AppLocalizations.of(context, listen: false)!;

    if (email.isEmpty || password.isEmpty) {
      AppMessenger.showSnackBar(context, title: l10n.error, message: l10n.pleaseEnterEmailAndPassword, type: MessengerType.error);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _authService.loginWithEmail(email, password);
      if (!mounted) return;
      if (result == null) {
        final biometricEnabled = await _biometricService.isBiometricEnabled();
        if (!mounted) return;
        if (!biometricEnabled && _isBiometricAvailable) {
          _showEnableBiometricDialog(email, password);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } else {
        AppMessenger.showSnackBar(context, title: l10n.error, message: result, type: MessengerType.error);
      }
    } catch (e) {
      if (mounted) AppMessenger.showSnackBar(context, title: l10n.error, message: e.toString(), type: MessengerType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Premium light-themed input field with focus animation
  Widget _buildModernInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    FocusNode? focusNode,
    bool isFocused = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isFocused ? const Color(0xFFF0FAFA) : const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused
              ? AppColors.teal.withValues(alpha: 0.4)
              : const Color(0xFFE8ECF0),
          width: isFocused ? 1.5 : 1.0,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.06),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.outfit(
          fontSize: 15,
          color: const Color(0xFF1A1D2E),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: GoogleFonts.outfit(
            color: const Color(0xFFADB5C2),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(
              icon,
              color: isFocused ? AppColors.teal : const Color(0xFFADB5C2),
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 44),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 1. Email ──
        _buildModernInput(
          controller: _emailController,
          focusNode: _emailFocusNode,
          label: l10n.email,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          isFocused: _emailFocused,
        ),
        const SizedBox(height: 14),

        // ── 2. Password ──
        _buildModernInput(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          label: l10n.password,
          icon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          isFocused: _passwordFocused,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: _passwordFocused ? AppColors.teal.withValues(alpha: 0.6) : const Color(0xFFBFC5D2),
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 4),

        // ── 3. Forgot Password ──
        Align(
          alignment: l10n.isAr ? Alignment.centerLeft : Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pushNamed(context, '/forgot_password'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            ),
            child: Text(
              l10n.forgotPasswordQ,
              style: GoogleFonts.outfit(
                color: AppColors.teal,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── 4. Continue Button ──
        Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF00BFA5), AppColors.teal],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.continueText,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 28),

        // ── 5. Divider ──
        Row(
          children: [
            Expanded(child: Divider(color: const Color(0xFFE8ECF0), thickness: 1, endIndent: 16)),
            Text(
              l10n.isAr ? "أو عبر" : "or",
              style: GoogleFonts.outfit(
                color: const Color(0xFFADB5C2),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(child: Divider(color: const Color(0xFFE8ECF0), thickness: 1, indent: 16)),
          ],
        ),
        const SizedBox(height: 24),

        // ── 6. Social Login Row ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Biometric
            _SocialLoginButton(
              onPressed: _handleBiometricLogin,
              child: Platform.isIOS
                  ? CustomPaint(
                      size: const Size(22, 22),
                      painter: FaceIdPainter(
                        color: _isBiometricAvailable
                            ? const Color(0xFF1A1D2E)
                            : const Color(0xFFD0D4DC),
                      ),
                    )
                  : Icon(
                      Icons.fingerprint_rounded,
                      size: 24,
                      color: _isBiometricAvailable
                          ? const Color(0xFF1A1D2E)
                          : const Color(0xFFD0D4DC),
                    ),
              label: l10n.isAr ? "البصمة" : "Face ID",
            ),
            const SizedBox(width: 16),

            // Google
            _SocialLoginButton(
              onPressed: _handleGoogleLogin,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/google_logo.jpg',
                  height: 24,
                  width: 24,
                  fit: BoxFit.cover,
                ),
              ),
              label: "Google",
            ),
          ],
        ),
      ],
    );
  }
}

/// Reusable social login button with label
class _SocialLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final String label;

  const _SocialLoginButton({
    required this.onPressed,
    required this.child,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          splashColor: AppColors.teal.withValues(alpha: 0.08),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8ECF0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                child,
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3A3F50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FaceIdPainter extends CustomPainter {
  final Color color;
  FaceIdPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final cornerSize = w * 0.25;

    canvas.drawPath(
      Path()
        ..moveTo(cornerSize, 0)
        ..lineTo(0, 0)
        ..lineTo(0, cornerSize),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w - cornerSize, 0)
        ..lineTo(w, 0)
        ..lineTo(w, cornerSize),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, h - cornerSize)
        ..lineTo(0, h)
        ..lineTo(cornerSize, h),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w - cornerSize, h)
        ..lineTo(w, h)
        ..lineTo(w, h - cornerSize),
      paint,
    );

    canvas.drawCircle(Offset(w * 0.35, h * 0.4), 1.5, paint..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(w * 0.65, h * 0.4), 1.5, paint..style = PaintingStyle.fill);

    paint.style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.5, h * 0.45)
        ..lineTo(w * 0.5, h * 0.6)
        ..lineTo(w * 0.45, h * 0.65),
      paint,
    );
    final rect = Rect.fromLTWH(w * 0.3, h * 0.55, w * 0.4, h * 0.2);
    canvas.drawArc(rect, 0.2, 2.7, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
