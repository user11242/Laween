import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
                  color: const Color(0xFF1F1F1F),
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
                    backgroundColor: const Color(0xFF006D77),
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
    final l10n = AppLocalizations.of(context, listen: false)!;
    setState(() => _isLoading = true);

    try {
      final result = await _authService.loginWithGoogle();
      if (!mounted) return;

      if (result == "student" || result == "teacher" || result == "admin") {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else if (result == "ACCOUNT_EXISTS_DIFFERENT_CREDENTIAL") {
        final email = _authService.googleAuth.pendingEmail;
        if (email != null) {
          final role = await showDialog<String>(
            context: context,
            barrierDismissible: false,
            builder: (context) => LinkAccountDialog(email: email),
          );
          
          if (role != null && mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          }
        }
      } else if (result != null && result != "NEEDS_ROLE") {
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
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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
                  color: const Color(0xFF006D77).withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.fingerprint, color: Color(0xFF006D77), size: 40),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.isAr ? "تفعيل تسجيل الدخول بالبصمة؟" : "Enable Biometric Login?",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F1F1F),
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
                          backgroundColor: const Color(0xFF006D77),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email Input
        TextFormField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.inter(fontSize: 16),
          decoration: InputDecoration(
            labelText: l10n.email,
            labelStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF006D77)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Password Input
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: GoogleFonts.inter(fontSize: 16),
          decoration: InputDecoration(
            labelText: l10n.password,
            labelStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF006D77)),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        // Continue Button
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleContinue,
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
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
              : Text(
                  l10n.continueText, 
                  style: GoogleFonts.inter(
                    fontSize: 16, 
                    fontWeight: FontWeight.w600, 
                    color: Colors.white
                  )
                ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Forgot Password
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/forgot_password');
            },
            child: Text(
              l10n.forgotPasswordQ,
              style: GoogleFonts.inter(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Face ID / Google Divider
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.loginWithFaceId,
                style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Icons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _handleBiometricLogin,
              icon: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomPaint(
                    size: const Size(36, 36),
                    painter: FaceIdPainter(
                      color: _isBiometricAvailable ? const Color(0xFF006D77) : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            IconButton(
              onPressed: _handleGoogleLogin,
              icon: const FaIcon(
                FontAwesomeIcons.google,
                size: 28,
                color: Color(0xFF4285F4), // Official Google Blue
              ),
            ),
          ],
        ),
      ],
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

    // Corner brackets
    // Top-left
    canvas.drawPath(Path()
      ..moveTo(cornerSize, 0)
      ..lineTo(0, 0)
      ..lineTo(0, cornerSize), paint);
    
    // Top-right
    canvas.drawPath(Path()
      ..moveTo(w - cornerSize, 0)
      ..lineTo(w, 0)
      ..lineTo(w, cornerSize), paint);
    
    // Bottom-left
    canvas.drawPath(Path()
      ..moveTo(0, h - cornerSize)
      ..lineTo(0, h)
      ..lineTo(cornerSize, h), paint);
    
    // Bottom-right
    canvas.drawPath(Path()
      ..moveTo(w - cornerSize, h)
      ..lineTo(w, h)
      ..lineTo(w, h - cornerSize), paint);

    // Simplified Face (eyes, nose, smile)
    // Eyes
    canvas.drawCircle(Offset(w * 0.35, h * 0.4), 1.5, paint..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(w * 0.65, h * 0.4), 1.5, paint..style = PaintingStyle.fill);
    
    // Nose
    paint.style = PaintingStyle.stroke;
    canvas.drawPath(Path()
      ..moveTo(w * 0.5, h * 0.45)
      ..lineTo(w * 0.5, h * 0.6)
      ..lineTo(w * 0.45, h * 0.65), paint);

    // Smile
    final rect = Rect.fromLTWH(w * 0.3, h * 0.55, w * 0.4, h * 0.2);
    canvas.drawArc(rect, 0.2, 2.7, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
