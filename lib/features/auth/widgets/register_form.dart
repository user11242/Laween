import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/colors.dart';
import '../../../features/auth/data/services/auth_service.dart';
import '../../../core/message/app_messenger.dart';
import '../../../core/utils/numeric_utils.dart';
import '../../../l10n/app_localizations.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phone_number/phone_number.dart' as lib_phone;
import 'dart:async';
import '../pages/verification_wizard_page.dart';
import '../pages/terms_of_service_page.dart';
import '../pages/privacy_policy_page.dart';
import 'package:flutter/gestures.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  String _currentCountryCode = 'JO';
  final lib_phone.PhoneNumberUtil _phoneUtil = lib_phone.PhoneNumberUtil();
  
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();
  
  bool _acceptedTerms = false;
  bool _isPasswordObscured = true;
  bool _isConfirmObscured = true;
  bool _isLoading = false;
  String _fullPhoneNumber = '';

  // Real-time validation states
  bool _isNameChecking = false;
  String? _nameError;
  bool _isNameValid = false;

  bool _isEmailChecking = false;
  String? _emailError;
  bool _isEmailValid = false;

  bool _isPhoneChecking = false;
  String? _phoneError;
  bool _isPhoneValid = false;

  bool _isPasswordValid = false;
  String? _passwordError;
  bool _isConfirmValid = false;
  String? _confirmError;

  // Debouncers
  Timer? _nameTimer;
  Timer? _emailTimer;
  Timer? _phoneTimer;
  Timer? _passwordShakeTimer;
  Timer? _confirmShakeTimer;

  // Shaking controllers
  late AnimationController _nameControllerAnimate;
  late AnimationController _emailControllerAnimate;
  late AnimationController _phoneControllerAnimate;
  late AnimationController _passwordControllerAnimate;
  late AnimationController _confirmControllerAnimate;

  TapGestureRecognizer? _termsRecognizer;
  TapGestureRecognizer? _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _nameControllerAnimate = AnimationController(vsync: this, duration: 400.ms);
    _emailControllerAnimate = AnimationController(vsync: this, duration: 400.ms);
    _phoneControllerAnimate = AnimationController(vsync: this, duration: 400.ms);
    _passwordControllerAnimate = AnimationController(vsync: this, duration: 400.ms);
    _confirmControllerAnimate = AnimationController(vsync: this, duration: 400.ms);

    _nameFocusNode.addListener(() {
      if (!_nameFocusNode.hasFocus && _nameController.text.isNotEmpty) {
        _nameTimer?.cancel();
        _validateName();
      }
    });
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus && _emailController.text.isNotEmpty) {
        _emailTimer?.cancel();
        _validateEmail();
      }
    });
    _phoneFocusNode.addListener(() {
      if (!_phoneFocusNode.hasFocus && _phoneController.text.isNotEmpty) {
        _phoneTimer?.cancel();
        _validatePhone();
      }
    });
    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus && _passwordController.text.isNotEmpty) {
        _passwordShakeTimer?.cancel();
        _validatePassword();
      }
    });
    _confirmFocusNode.addListener(() {
      if (!_confirmFocusNode.hasFocus && _confirmPasswordController.text.isNotEmpty) {
        _confirmShakeTimer?.cancel();
        _validateConfirmPassword();
      }
    });
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    _passwordShakeTimer?.cancel();
    _confirmShakeTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameTimer?.cancel();
    _emailTimer?.cancel();
    _phoneTimer?.cancel();
    _nameControllerAnimate.dispose();
    _emailControllerAnimate.dispose();
    _phoneControllerAnimate.dispose();
    _passwordControllerAnimate.dispose();
    _confirmControllerAnimate.dispose();
    _termsRecognizer?.dispose();
    _privacyRecognizer?.dispose();
    super.dispose();
  }

  Future<void> _validateName() async {
    final value = _nameController.text;
    if (value.isEmpty || !mounted) return;
    final l10n = AppLocalizations.of(context, listen: false)!;
    setState(() { _isNameChecking = true; _nameError = null; _isNameValid = false; });
    if (value.length < 3 || value.length > 30 || !RegExp(r'[a-zA-Z\u0600-\u06FF]').hasMatch(value)) {
      if (mounted) setState(() { _isNameChecking = false; _nameError = l10n.invalidUsername; });
      return;
    }
    final isTaken = await _authService.isNameTaken(value);
    if (mounted) {
      setState(() { _isNameChecking = false; if (isTaken) _nameError = l10n.nameTaken; else _isNameValid = true; });
    }
  }

  void _onNameChanged(String value) {
    _nameTimer?.cancel();
    setState(() { _nameError = null; _isNameValid = false; });
    _nameTimer = Timer(const Duration(seconds: 2), _validateName);
  }

  Future<void> _validateEmail() async {
    final value = _emailController.text;
    if (value.isEmpty || !mounted) return;
    final l10n = AppLocalizations.of(context, listen: false)!;
    setState(() { _isEmailChecking = true; _emailError = null; _isEmailValid = false; });
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      if (mounted) setState(() { _isEmailChecking = false; _emailError = l10n.invalidEmail; });
      return;
    }
    final isTaken = await _authService.isEmailTaken(value);
    if (mounted) {
      setState(() { _isEmailChecking = false; if (isTaken) _emailError = l10n.emailTaken; else _isEmailValid = true; });
    }
  }

  void _onEmailChanged(String value) {
    _emailTimer?.cancel();
    setState(() { _emailError = null; _isEmailValid = false; });
    _emailTimer = Timer(const Duration(seconds: 2), _validateEmail);
  }

  Future<void> _validatePhone() async {
    if (_fullPhoneNumber.isEmpty || !mounted) return;
    final l10n = AppLocalizations.of(context, listen: false)!;
    setState(() { _isPhoneChecking = true; _phoneError = null; _isPhoneValid = false; });
    try {
      if (_fullPhoneNumber.length < 8) {
        if (mounted) setState(() { _isPhoneChecking = false; _phoneError = l10n.invalidMobileNumber; });
        return;
      }
      bool isValidFormat = false;
      try { isValidFormat = await _phoneUtil.validate(_fullPhoneNumber, regionCode: _currentCountryCode); } catch (_) { isValidFormat = false; }
      if (!mounted) return;
      if (!isValidFormat) {
        setState(() { _isPhoneChecking = false; _phoneError = l10n.invalidMobileNumber; });
        return;
      }
      final isTaken = await _authService.isPhoneTaken(_fullPhoneNumber);
      if (mounted) {
        setState(() { _isPhoneChecking = false; if (isTaken) _phoneError = l10n.phoneTaken; else _isPhoneValid = true; });
      }
    } catch (e) {
      if (mounted) setState(() { _isPhoneChecking = false; _phoneError = null; });
    }
  }

  void _onPhoneChanged(dynamic phone) {
    if (phone == null) return;
    final value = phone.number as String;
    final normalized = NumericUtils.normalizeDigits(value);
    if (normalized != value) {
       _phoneController.value = _phoneController.value.copyWith(text: normalized, selection: TextSelection.collapsed(offset: normalized.length));
    }
    try { _fullPhoneNumber = phone.completeNumber as String; } catch (e) { _fullPhoneNumber = ''; }
    _phoneTimer?.cancel();
    setState(() { _phoneError = null; _isPhoneValid = false; });
    _phoneTimer = Timer(const Duration(seconds: 2), _validatePhone);
  }

  void _validatePassword() {
    final value = _passwordController.text;
    if (value.isEmpty || !mounted) return;
    final l10n = AppLocalizations.of(context, listen: false)!;
    final hasUpper = value.contains(RegExp(r'[A-Z]'));
    final hasNumber = value.contains(RegExp(r'[0-9]'));
    final hasSymbol = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    setState(() {
      if (value.length >= 8 && hasUpper && hasNumber && hasSymbol) {
        _isPasswordValid = true;
        _passwordError = null;
      } else {
        _isPasswordValid = false;
        _passwordError = l10n.weakPassword;
      }
      if (_confirmPasswordController.text.isNotEmpty) _validateConfirmPassword();
    });
  }

  void _onPasswordChanged(String value) {
    _passwordShakeTimer?.cancel();
    setState(() { _passwordError = null; _isPasswordValid = false; });
    if (value.isNotEmpty) {
      _passwordShakeTimer = Timer(const Duration(seconds: 2), _validatePassword);
    }
  }

  void _validateConfirmPassword() {
    final value = _confirmPasswordController.text;
    if (value.isEmpty || !mounted) return;
    final l10n = AppLocalizations.of(context, listen: false)!;
    setState(() {
      if (value == _passwordController.text && _isPasswordValid) {
        _isConfirmValid = true;
        _confirmError = null;
      } else {
        _isConfirmValid = false;
        _confirmError = l10n.passwordsDoNotMatch;
      }
    });
  }

  void _onConfirmPasswordChanged(String value) {
    _confirmShakeTimer?.cancel();
    setState(() { _confirmError = null; _isConfirmValid = false; });
    if (value.isNotEmpty) {
      _confirmShakeTimer = Timer(const Duration(seconds: 2), _validateConfirmPassword);
    }
  }

  String _localizeError(String error, AppLocalizations l10n) {
    if (error.contains("Username is already taken")) return l10n.nameTaken;
    if (error.contains("Email is already registered")) return l10n.emailTaken;
    if (error.contains("Phone number is already in use")) return l10n.phoneTaken;
    if (error.contains("weak-password")) return l10n.weakPassword;
    if (error.contains("email-already-in-use")) return l10n.emailTaken;
    return error;
  }

  Future<void> _handleContinue() async {
    final l10n = AppLocalizations.of(context, listen: false)!;
    
    // 1. Check UX elements (terms, name, email, etc.)
    bool hasError = false;
    
    if (!_acceptedTerms) {
      AppMessenger.showSnackBar(context, title: l10n.termsRequired, message: l10n.acceptTermsToFinish, type: MessengerType.error);
      return; 
    }

    if (!_isNameValid) { _nameControllerAnimate.forward(from: 0); hasError = true; }
    if (!_isEmailValid) { _emailControllerAnimate.forward(from: 0); hasError = true; }
    if (!_isPhoneValid) { _phoneControllerAnimate.forward(from: 0); hasError = true; }
    if (!_isPasswordValid) { _passwordControllerAnimate.forward(from: 0); hasError = true; }
    if (!_isConfirmValid) { _confirmControllerAnimate.forward(from: 0); hasError = true; }

    if (hasError) {
      AppMessenger.showSnackBar(context, title: l10n.error, message: l10n.pleaseTryAgain, type: MessengerType.error);
      return;
    }

    // 2. Perform Pre-Registration Check (uniqueness)
    setState(() => _isLoading = true);
    final preCheckError = await _authService.preRegistrationCheck(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _fullPhoneNumber,
    );

    if (preCheckError != null) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppMessenger.showSnackBar(context, title: l10n.error, message: _localizeError(preCheckError, l10n), type: MessengerType.error);
      }
      return;
    }

    // 3. Move to Verification Step (Popup Wizard)
    if (mounted) {
      setState(() => _isLoading = false);
      
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => VerificationWizardPage(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _fullPhoneNumber,
          name: _nameController.text.trim(),
          acceptedTerms: _acceptedTerms,
        ),
      );

      if (result == true && mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    }
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? errorText,
    bool isLoading = false,
    bool isSuccess = false,
    Function(String)? onChanged,
    TextInputType keyboardType = TextInputType.text,
    AnimationController? controllerAnimate,
    FocusNode? focusNode,
  }) {
    final bool isAr = AppLocalizations.of(context)!.isAr;
    return Animate(
      controller: controllerAnimate,
      autoPlay: false,
      target: errorText != null ? 1 : 0,
      effects: [ShakeEffect(duration: 400.ms, hz: 6)],
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: errorText != null 
                  ? Colors.red.withOpacity(0.08) 
                  : Colors.black.withOpacity(0.03),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          onChanged: onChanged,
          keyboardType: keyboardType,
          style: isAr
              ? GoogleFonts.cairo(fontSize: 16, color: errorText != null ? Colors.red : Colors.black87)
              : GoogleFonts.nunito(fontSize: 16, color: errorText != null ? Colors.red : Colors.black87),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: isAr
                ? GoogleFonts.cairo(color: errorText != null ? Colors.red : Colors.grey.shade500, fontSize: 14)
                : GoogleFonts.nunito(color: errorText != null ? Colors.red : Colors.grey.shade500, fontSize: 14),
            hintStyle: isAr
                ? GoogleFonts.cairo(color: Colors.grey.shade400, fontSize: 14)
                : GoogleFonts.nunito(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, color: errorText != null ? Colors.red : AppColors.teal, size: 20),
            suffixIcon: isLoading 
              ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)))
              : (isSuccess ? const Icon(Icons.check_circle, color: Colors.green, size: 20) : suffixIcon),
            filled: true,
            fillColor: Colors.transparent, // Background now handled by wrapper
            contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: errorText != null ? Colors.red.withOpacity(0.5) : Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: errorText != null ? Colors.red : AppColors.teal.withOpacity(0.4), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            errorText: errorText,
            errorStyle: isAr ? const TextStyle(color: Colors.red, fontSize: 12) : const TextStyle(color: Colors.red, fontSize: 12),
            errorMaxLines: 3,
          ),
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
        // Full Name Input
        _buildTextField(
          controller: _nameController,
          focusNode: _nameFocusNode,
          label: l10n.fullName,
          icon: Icons.person_outline,
          onChanged: _onNameChanged,
          errorText: _nameError,
          isLoading: _isNameChecking,
          isSuccess: _isNameValid,
          controllerAnimate: _nameControllerAnimate,
        ),
        const SizedBox(height: 16),

        // Email Input
        _buildTextField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          label: l10n.email,
          icon: Icons.email_outlined,
          onChanged: _onEmailChanged,
          errorText: _emailError,
          isLoading: _isEmailChecking,
          isSuccess: _isEmailValid,
          controllerAnimate: _emailControllerAnimate,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),

        // Phone Input
        Animate(
          controller: _phoneControllerAnimate,
          autoPlay: false,
          target: _phoneError != null ? 1 : 0,
          effects: [ShakeEffect(duration: 400.ms, hz: 6)],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _phoneError != null 
                          ? Colors.red.withOpacity(0.08) 
                          : Colors.black.withOpacity(0.03),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: IntlPhoneField(
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  invalidNumberMessage: l10n.invalidMobileNumber,
                  autovalidateMode: AutovalidateMode.disabled,
                  initialCountryCode: 'JO', // Default
                  onChanged: _onPhoneChanged,
                  onCountryChanged: (country) => setState(() {
                    _currentCountryCode = country.code;
                    _isPhoneValid = false;
                    _isPhoneChecking = false;
                    _phoneError = null;
                  }),
                  decoration: InputDecoration(
                    labelText: l10n.phoneNumber,
                    labelStyle: l10n.isAr 
                        ? GoogleFonts.cairo(color: _phoneError != null ? Colors.red : Colors.grey.shade500, fontSize: 14)
                        : GoogleFonts.nunito(color: _phoneError != null ? Colors.red : Colors.grey.shade500, fontSize: 14),
                    prefixIcon: Icon(Icons.phone_outlined, color: _phoneError != null ? Colors.red : AppColors.teal, size: 20),
                    suffixIcon: _isPhoneChecking 
                      ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)))
                      : (_isPhoneValid ? const Icon(Icons.check_circle, color: Colors.green, size: 20) : null),
                    filled: true,
                    fillColor: Colors.transparent, // Inherit white container
                    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: _phoneError != null ? Colors.red.withOpacity(0.5) : Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: _phoneError != null ? Colors.red : AppColors.teal.withOpacity(0.4), width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    errorText: _phoneError,
                    errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
                    errorMaxLines: 3,
                    counterText: '',
                  ),
                  style: l10n.isAr
                      ? GoogleFonts.cairo(fontSize: 16, color: _phoneError != null ? Colors.red : Colors.black87)
                      : GoogleFonts.nunito(fontSize: 16, color: _phoneError != null ? Colors.red : Colors.black87),
                ),
              ),
              Align(
                alignment: l10n.isAr ? Alignment.centerLeft : Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, right: 12, left: 12),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _phoneController,
                    builder: (context, value, child) {
                      int maxLen = _currentCountryCode == 'JO' ? 9 : 10;
                      return Text(
                        '${value.text.length}/$maxLen',
                        style: TextStyle(
                          fontSize: 12, 
                          color: Colors.grey.shade500,
                          fontFamily: GoogleFonts.nunito().fontFamily,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Password Input
        _buildTextField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          label: l10n.password,
          icon: Icons.lock_outline,
          obscureText: _isPasswordObscured,
          onChanged: _onPasswordChanged,
          errorText: _passwordError,
          isSuccess: _isPasswordValid,
          controllerAnimate: _passwordControllerAnimate,
          suffixIcon: IconButton(
            icon: Icon(_isPasswordObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
            onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
          ),
        ),
        const SizedBox(height: 16),
        
        // Confirm Password Input
        _buildTextField(
          controller: _confirmPasswordController,
          focusNode: _confirmFocusNode,
          label: l10n.confirmPassword,
          icon: Icons.lock_clock_outlined,
          obscureText: _isConfirmObscured,
          onChanged: _onConfirmPasswordChanged,
          errorText: _confirmError,
          isSuccess: _isConfirmValid,
          controllerAnimate: _confirmControllerAnimate,
          suffixIcon: IconButton(
            icon: Icon(_isConfirmObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
            onPressed: () => setState(() => _isConfirmObscured = !_isConfirmObscured),
          ),
        ),
        const SizedBox(height: 24),
        
        // Terms & Conditions
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _acceptedTerms,
                activeColor: AppColors.teal,
                side: BorderSide(color: Colors.grey.shade400),
                onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: l10n.isAr 
                      ? GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade700) 
                      : GoogleFonts.nunito(fontSize: 14, color: Colors.grey.shade700),
                  children: [
                    TextSpan(text: l10n.iAccept),
                    TextSpan(
                      text: l10n.termsAndConditions,
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: _termsRecognizer ??= TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TermsOfServicePage(),
                            ),
                          );
                        },
                    ),
                    TextSpan(
                      text: l10n.and,
                    ),
                    TextSpan(
                      text: l10n.privacyPolicy,
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: _privacyRecognizer ??= TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PrivacyPolicyPage(),
                            ),
                          );
                        },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Continue Button
        Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [AppColors.teal, Color(0xFF00796B)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withOpacity(0.4),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: (_isLoading || _isNameChecking || _isEmailChecking || _isPhoneChecking) ? null : _handleContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: _isLoading 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  l10n.continueText,
                  style: l10n.isAr 
                      ? GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)
                      : GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                ),
          ),
        ),
      ],
    );
  }
}
