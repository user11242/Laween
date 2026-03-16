import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/auth/data/services/auth_service.dart';
import '../../../core/message/app_messenger.dart';
import '../../../core/utils/numeric_utils.dart';
import '../../../l10n/app_localizations.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phone_number/phone_number.dart' as lib_phone;
import 'dart:async';

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

  // Shaking controllers
  late AnimationController _nameControllerAnimate;
  late AnimationController _emailControllerAnimate;
  late AnimationController _phoneControllerAnimate;
  late AnimationController _passwordControllerAnimate;
  late AnimationController _confirmControllerAnimate;

  @override
  void initState() {
    super.initState();
    _nameControllerAnimate = AnimationController(vsync: this, duration: 400.ms);
    _emailControllerAnimate = AnimationController(vsync: this, duration: 400.ms);
    _phoneControllerAnimate = AnimationController(vsync: this, duration: 400.ms);
    _passwordControllerAnimate = AnimationController(vsync: this, duration: 400.ms);
    _confirmControllerAnimate = AnimationController(vsync: this, duration: 400.ms);
  }

  @override
  void dispose() {
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
    super.dispose();
  }

  void _onNameChanged(String value) {
    if (_nameTimer?.isActive ?? false) _nameTimer!.cancel();
    setState(() {
      _isNameChecking = true;
      _nameError = null;
      _isNameValid = false;
    });

    _nameTimer = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context, listen: false)!;
      
      // 1. Format check: 3-30 chars, not solo numbers or symbols
      if (value.length < 3 || value.length > 30) {
        setState(() { _isNameChecking = false; _nameError = l10n.invalidUsername; });
        return;
      }
      
      final hasAlpha = RegExp(r'[a-zA-Z\u0600-\u06FF]').hasMatch(value);
      if (!hasAlpha) {
         setState(() { _isNameChecking = false; _nameError = l10n.invalidUsername; });
         return;
      }

      // 2. Uniqueness check
      final isTaken = await _authService.isNameTaken(value);
      if (mounted) {
        setState(() {
          _isNameChecking = false;
          if (isTaken) {
            _nameError = l10n.nameTaken;
          } else {
            _isNameValid = true;
          }
        });
      }
    });
  }

  void _onEmailChanged(String value) {
    if (_emailTimer?.isActive ?? false) _emailTimer!.cancel();
    setState(() {
      _isEmailChecking = true;
      _emailError = null;
      _isEmailValid = false;
    });

    _emailTimer = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context, listen: false)!;
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      
      if (!emailRegex.hasMatch(value)) {
        setState(() { _isEmailChecking = false; _emailError = l10n.invalidEmail; });
        return;
      }

      final isTaken = await _authService.isEmailTaken(value);
      if (mounted) {
        setState(() {
          _isEmailChecking = false;
          if (isTaken) {
            _emailError = l10n.emailTaken;
          } else {
            _isEmailValid = true;
          }
        });
      }
    });
  }

  String _currentCountryCode = 'JO';
  final lib_phone.PhoneNumberUtil _phoneUtil = lib_phone.PhoneNumberUtil();

  void _onPhoneChanged(dynamic phone) {
    if (phone == null) return;
    
    final value = phone.number as String;
    final normalized = NumericUtils.normalizeDigits(value);
    
    // Update controller only if digits were normalized to keep cursor stable
    if (normalized != value) {
       _phoneController.value = _phoneController.value.copyWith(
         text: normalized,
         selection: TextSelection.collapsed(offset: normalized.length),
       );
    }

    if (_phoneTimer?.isActive ?? false) _phoneTimer!.cancel();
    setState(() {
      _isPhoneChecking = true;
      _phoneError = null;
      _isPhoneValid = false;
    });

    _phoneTimer = Timer(const Duration(milliseconds: 600), () async {
      try {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context, listen: false)!;
        
        // Use try-catch for completeNumber because some inputs might be malformed
        String fullPhone;
        try {
          fullPhone = phone.completeNumber as String;
          _fullPhoneNumber = fullPhone; // ✅ Store the complete number (with country code)
        } catch (e) {
          if (mounted) setState(() => _isPhoneChecking = false);
          return;
        }

        if (fullPhone.length < 8) {
          if (mounted) setState(() => _isPhoneChecking = false);
          return;
        }

        // 1. DYNAMIC VALIDATION based on selected country
        bool isValidFormat = false;
        try {
          isValidFormat = await _phoneUtil.validate(fullPhone, regionCode: _currentCountryCode);
        } catch (_) {
          isValidFormat = false;
        }

        if (!mounted) return;

        if (!isValidFormat) {
          setState(() {
            _isPhoneChecking = false;
            if (normalized.length >= 5) {
              _phoneError = l10n.invalidMobileNumber;
            }
          });
          return;
        }
        
        // 2. Uniqueness check
        final isTaken = await _authService.isPhoneTaken(fullPhone);
        if (mounted) {
          setState(() {
            _isPhoneChecking = false;
            if (isTaken) {
              _phoneError = l10n.phoneTaken;
            } else {
              _isPhoneValid = true;
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isPhoneChecking = false;
            _phoneError = null; // Don't block the user with obscure errors
          });
        }
      }
    });
  }

  void _onPasswordChanged(String value) {
    final l10n = AppLocalizations.of(context, listen: false)!;
    // 8 chars, 1 capital, 1 number, 1 symbol
    final hasUpper = value.contains(RegExp(r'[A-Z]'));
    final hasNumber = value.contains(RegExp(r'[0-9]'));
    final hasSymbol = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    setState(() {
      if (value.length >= 8 && hasUpper && hasNumber && hasSymbol) {
        _isPasswordValid = true;
        _passwordError = null;
      } else if (value.isNotEmpty) {
        _isPasswordValid = false;
        _passwordError = l10n.weakPassword;
      } else {
        _isPasswordValid = false;
        _passwordError = null;
      }
      // Re-verify confirm password if it's already filled
      if (_confirmPasswordController.text.isNotEmpty) {
        _onConfirmPasswordChanged(_confirmPasswordController.text);
      }
    });
  }

  void _onConfirmPasswordChanged(String value) {
     setState(() {
       final l10n = AppLocalizations.of(context, listen: false)!;
       if (value == _passwordController.text && value.isNotEmpty && _isPasswordValid) {
         _isConfirmValid = true;
         _confirmError = null;
       } else if (value.isNotEmpty) {
         _isConfirmValid = false;
         _confirmError = l10n.passwordsDoNotMatch;
       } else {
         _isConfirmValid = false;
         _confirmError = null;
       }
     });
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
    
    // Check if anything is invalid and trigger shake
    bool hasError = false;
    
    if (!_acceptedTerms) {
      AppMessenger.showSnackBar(context, title: l10n.termsRequired, message: l10n.acceptTermsToFinish, type: MessengerType.error);
      return; // Terms are special
    }

    if (!_isNameValid) { _nameControllerAnimate.forward(from: 0); hasError = true; }
    if (!_isEmailValid) { _emailControllerAnimate.forward(from: 0); hasError = true; }
    if (!_isPhoneValid) { _phoneControllerAnimate.forward(from: 0); hasError = true; }
    if (!_isPasswordValid) { _passwordControllerAnimate.forward(from: 0); hasError = true; }
    if (!_isConfirmValid) { _confirmControllerAnimate.forward(from: 0); hasError = true; }

    if (hasError) {
      AppMessenger.showSnackBar(
        context, 
        title: l10n.error, 
        message: l10n.pleaseTryAgain, 
        type: MessengerType.error
      );
      return;
    }
    
    // Register directly and go to home
    setState(() => _isLoading = true);
    
    try {
      final error = await _authService.registerWithEmail(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _passwordController.text,
        phone: _fullPhoneNumber.isNotEmpty ? _fullPhoneNumber : _phoneController.text.trim(), // ✅ Use full phone
        portfolio: '',
        acceptedTerms: _acceptedTerms,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (error == null) {
        // Success: Go directly to Home
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        AppMessenger.showSnackBar(
          context, 
          title: l10n.error, 
          message: _localizeError(error, l10n), 
          type: MessengerType.error
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      AppMessenger.showSnackBar(
        context, 
        title: l10n.error, 
        message: e.toString(), 
        type: MessengerType.error
      );
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
  }) {
    return Animate(
      controller: controllerAnimate,
      autoPlay: false,
      target: errorText != null ? 1 : 0,
      effects: [ShakeEffect(duration: 400.ms, hz: 6)],
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        onChanged: onChanged,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(fontSize: 16, color: errorText != null ? Colors.red : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: errorText != null ? Colors.red : Colors.grey, fontSize: 14),
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: errorText != null ? Colors.red : const Color(0xFF006D77), size: 20),
          suffixIcon: isLoading 
            ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF006D77))))
            : (isSuccess ? const Icon(Icons.check_circle, color: Colors.green, size: 20) : suffixIcon),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: errorText != null ? Colors.red : Colors.grey.shade300),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: errorText != null ? Colors.red : const Color(0xFF006D77), width: 2),
          ),
          errorText: errorText,
          errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
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
          child: IntlPhoneField(
            controller: _phoneController,
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
              labelStyle: GoogleFonts.inter(color: _phoneError != null ? Colors.red : Colors.grey, fontSize: 14),
              prefixIcon: Icon(Icons.phone_outlined, color: _phoneError != null ? Colors.red : const Color(0xFF006D77), size: 20),
              suffixIcon: _isPhoneChecking 
                ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF006D77))))
                : (_isPhoneValid ? const Icon(Icons.check_circle, color: Colors.green, size: 20) : null),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: _phoneError != null ? Colors.red : Colors.grey.shade300),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: _phoneError != null ? Colors.red : const Color(0xFF006D77), width: 2),
              ),
              errorText: _phoneError,
              errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
            ),
            style: GoogleFonts.inter(fontSize: 16, color: _phoneError != null ? Colors.red : Colors.black87),
          ),
        ),
        const SizedBox(height: 16),
        
        // Password Input
        _buildTextField(
          controller: _passwordController,
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
                activeColor: const Color(0xFF006D77),
                side: BorderSide(color: Colors.grey.shade400),
                onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700),
                  children: [
                    TextSpan(text: l10n.iAccept),
                    TextSpan(
                      text: l10n.termsAndConditions,
                      style: const TextStyle(
                        color: Color(0xFF006D77),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
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
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF006D77).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: (_isLoading || _isNameChecking || _isEmailChecking || _isPhoneChecking) ? null : _handleContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006D77),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: _isLoading 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  l10n.continueText,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
          ),
        ),
      ],
    );
  }
}
