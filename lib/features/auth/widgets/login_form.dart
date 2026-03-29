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
  final _authService = AuthService();
  final _biometricService = BiometricService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    final available = await _biometricService.isBiometricAvailable();
    if (mounted) {
      setState(() {
        _isBiometricAvailable = available;
      });
    }
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
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.useEmailAndPassword,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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
        AppMessenger.showSnackBar(
          context,
          title: l10n.error,
          message: result,
          type: MessengerType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        AppMessenger.showSnackBar(
          context,
          title: l10n.error,
          message: e.toString(),
          type: MessengerType.error,
        );
      }
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
          message: l10n.isAr ? "لم يتم العثور على بيانات مسجلة. يرجى تسجيل الدخول يدوياً أولاً." : "No saved credentials found. Please log in manually first.",
          type: MessengerType.error,
        );
      } else {
        AppMessenger.showSnackBar(
          context,
          title: l10n.error,
          message: result,
          type: MessengerType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        AppMessenger.showSnackBar(
          context,
          title: l10n.error,
          message: e.toString(),
          type: MessengerType.error,
        );
      }
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
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
                child: const Center(
                  child: Icon(Icons.fingerprint, color: AppColors.teal, size: 40),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.isAr ? "تفعيل تسجيل الدخول بالبصمة؟" : "Enable Biometric Login?",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.isAr 
                  ? "هل تريد استخدام بصمة الإصبع أو الوجه لتسجيل الدخول في المرات القادمة؟" 
                  : "Would you like to use Face ID or Fingerprint for faster login next time?",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        l10n.isAr ? "ليس الآن" : "Not now",
                        style: GoogleFonts.inter(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          l10n.isAr ? "تفعيل" : "Enable",
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    });
  }

  Future<void> _handleContinue() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final l10n = AppLocalizations.of(context, listen: false)!;

    if (email.isEmpty || password.isEmpty) {
      AppMessenger.showSnackBar(
        context,
        title: l10n.error,
        message: l10n.pleaseEnterEmailAndPassword,
        type: MessengerType.error,
      );
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
        AppMessenger.showSnackBar(
          context,
          title: l10n.error,
          message: result,
          type: MessengerType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        AppMessenger.showSnackBar(
          context,
          title: l10n.error,
          message: e.toString(),
          type: MessengerType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildGlassInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    FocusNode? focusNode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.outfit(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w400),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
        // 1. Email Input
        _buildGlassInput(
          controller: _emailController,
          focusNode: _emailFocusNode,
          label: l10n.email,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        
        const SizedBox(height: 8),
        
        // 2. Password Input
        _buildGlassInput(
          controller: _passwordController,
          label: l10n.password,
          icon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white.withValues(alpha: 0.2),
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // 3. Forgot Password
        Align(
          alignment: l10n.isAr ? Alignment.bottomLeft : Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pushNamed(context, '/forgot_password'),
            child: Text(
              l10n.forgotPasswordQ,
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 4. Continue Button (Solid Premium)
        Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF00BFA5),
                Color(0xFF00897B),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00BFA5).withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: _isLoading 
              ? const SizedBox(
                  width: 24, 
                  height: 24, 
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
              : Text(
                  l10n.continueText, 
                  style: GoogleFonts.outfit(
                    fontSize: 17, 
                    fontWeight: FontWeight.w700, 
                    color: Colors.white,
                    letterSpacing: 0.5,
                  )
                ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        Center(
          child: Text(
            l10n.isAr ? "أو عبر" : "OR CONTINUE WITH",
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.5), // Prominent white as requested
              fontSize: 10, 
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),

        const SizedBox(height: 16),
        
        // 5. Social Login Pill Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMinimalSocialItem(
              onPressed: _handleBiometricLogin,
              child: Platform.isIOS 
                ? CustomPaint(
                    size: const Size(22, 22),
                    painter: FaceIdPainter(
                      color: _isBiometricAvailable ? Colors.white : Colors.white.withValues(alpha: 0.1),
                    ),
                  )
                : Icon(
                    Icons.fingerprint_rounded, 
                    size: 24, 
                    color: _isBiometricAvailable ? Colors.white : Colors.white.withValues(alpha: 0.1),
                  ),
            ),
            const SizedBox(width: 40),
            _buildMinimalSocialItem(
              onPressed: _handleGoogleLogin,
              padding: EdgeInsets.zero, // Make logo cover the circle
              child: ClipOval(
                child: Image.asset(
                  'assets/google_logo.jpg',
                  height: 54, // Match container size
                  width: 54,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMinimalSocialItem({required VoidCallback onPressed, required Widget child, EdgeInsets? padding}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(27),
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: child,
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

    canvas.drawPath(Path()
      ..moveTo(cornerSize, 0)
      ..lineTo(0, 0)
      ..lineTo(0, cornerSize), paint);
    
    canvas.drawPath(Path()
      ..moveTo(w - cornerSize, 0)
      ..lineTo(w, 0)
      ..lineTo(w, cornerSize), paint);
    
    canvas.drawPath(Path()
      ..moveTo(0, h - cornerSize)
      ..lineTo(0, h)
      ..lineTo(cornerSize, h), paint);
    
    canvas.drawPath(Path()
      ..moveTo(w - cornerSize, h)
      ..lineTo(w, h)
      ..lineTo(w, h - cornerSize), paint);

    canvas.drawCircle(Offset(w * 0.35, h * 0.4), 1.5, paint..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(w * 0.65, h * 0.4), 1.5, paint..style = PaintingStyle.fill);
    
    paint.style = PaintingStyle.stroke;
    canvas.drawPath(Path()
      ..moveTo(w * 0.5, h * 0.45)
      ..lineTo(w * 0.5, h * 0.6)
      ..lineTo(w * 0.45, h * 0.65), paint);

    final rect = Rect.fromLTWH(w * 0.3, h * 0.55, w * 0.4, h * 0.2);
    canvas.drawArc(rect, 0.2, 2.7, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
