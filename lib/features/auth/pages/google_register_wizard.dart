import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:laween/l10n/app_localizations.dart';
import 'package:laween/features/auth/data/services/auth_service.dart';
import '../../../core/message/app_messenger.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:device_region/device_region.dart';
import 'package:laween/features/auth/pages/terms_and_conditions_page.dart';
import 'package:phone_number/phone_number.dart' as lib_phone;
import '../../../core/utils/numeric_utils.dart';

class GoogleRegisterWizard extends StatefulWidget {
  const GoogleRegisterWizard({super.key});

  @override
  State<GoogleRegisterWizard> createState() => _GoogleRegisterWizardState();
}

class _GoogleRegisterWizardState extends State<GoogleRegisterWizard> {
  final AuthService _authService = AuthService();
  final phoneController = TextEditingController();
  final _phoneUtil = lib_phone.PhoneNumberUtil();
  
  String _localizeError(String error, AppLocalizations l10n) {
    if (error.contains("Not signed in")) return l10n.isAr ? "لم يتم تسجيل الدخول" : "Not signed in";
    return error;
  }

  int _step = 0;
  bool isLoading = false;
  bool _acceptedTerms = false;
  String fullPhoneNumber = "";
  String _initialCountryCode = "JO";
  bool _isStepsInitialized = false;


  @override
  void initState() {
    super.initState();
    _initializeWizard();
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _initializeWizard() async {
    try {
      // 1. Try SIM Card (Best)
      String? countryCode = await DeviceRegion.getSIMCountryCode();

      if (countryCode == null || countryCode.isEmpty) {
        final locale = WidgetsBinding.instance.platformDispatcher.locale;
        countryCode = locale.countryCode;
      }

      if (countryCode != null && countryCode.isNotEmpty) {
        _initialCountryCode = countryCode.toUpperCase();
      }
    } catch (_) {}
    if (mounted) setState(() => _isStepsInitialized = true);
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildPhoneInputStep();
      case 1:
        return _buildTermsStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTermsStep() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.description_outlined, color: Color(0xFF006D77), size: 48),
        const SizedBox(height: 16),
        Text(
          l10n.termsAndConditions,
          style: const TextStyle(color: Color(0xFF006D77), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF006D77).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Checkbox(
                value: _acceptedTerms,
                onChanged: (v) => setState(() => _acceptedTerms = v!),
                activeColor: const Color(0xFF006D77),
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Color(0xFF006D77), fontSize: 13),
                    children: [
                      TextSpan(text: l10n.iAccept),
                      TextSpan(
                        text: l10n.termsAndConditions,
                        style: const TextStyle(
                          color: Color(0xFF006D77),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsAndConditionsPage()));
                          },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInputStep() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.verifyIdentity,
          style: const TextStyle(color: Color(0xFF006D77), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        IntlPhoneField(
          controller: phoneController,
          invalidNumberMessage: l10n.invalidMobileNumber,
          initialCountryCode: _initialCountryCode,
          style: const TextStyle(color: Color(0xFF006D77)),
          inputFormatters: [NumericUtils.digitFormatter],
          textAlign: TextAlign.start,
          dropdownIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF006D77)),
          dropdownTextStyle: const TextStyle(color: Color(0xFF006D77)),
          onChanged: (phone) {
            setState(() {
              // Normalize digits AND clean spaces/dashes for the backend
              fullPhoneNumber = NumericUtils.normalize(phone.completeNumber, clean: true);
            });
          },
          decoration: InputDecoration(
            hintText: l10n.phoneNumber,
            hintStyle: TextStyle(color: const Color(0xFF006D77).withValues(alpha: 0.5)),
            filled: true,
            fillColor: const Color(0xFF006D77).withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFF006D77).withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFF006D77).withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF006D77), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _nextStep() async {
    final l10n = AppLocalizations.of(context, listen: false)!;
    if (isLoading) return;

    if (_step == 0) { // Phone Step
      if (phoneController.text.length < 5) return;

      setState(() => isLoading = true);
      
      // 1. Format Check
      bool isValidFormat = false;
      try {
        isValidFormat = await _phoneUtil.validate(fullPhoneNumber, regionCode: _initialCountryCode);
      } catch (_) {
        isValidFormat = false;
      }

      if (!mounted) return;

      if (!isValidFormat) {
        setState(() => isLoading = false);
        AppMessenger.showSnackBar(context, title: l10n.error, message: l10n.invalidMobileNumber, type: MessengerType.error);
        return;
      }

      // 2. Uniqueness Check
      final isTaken = await _authService.isPhoneTaken(fullPhoneNumber);
      if (mounted) setState(() => isLoading = false);

      if (isTaken) {
        if (mounted) {
          AppMessenger.showSnackBar(context, title: l10n.unavailable, message: l10n.phoneNumberInUse, type: MessengerType.error);
        }
        return;
      }
    }

    if (await _validateCurrentStepInput()) {
      _isFinalStep() ? await _finishWizard() : _stepForward();
    }
  }

  void _stepForward() {
    if (mounted) {
      setState(() {
        _step++;
      });
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() {
        _step--;
      });
    } else {
      _handleCancel();
    }
  }

  Future<void> _handleCancel() async {
    setState(() => isLoading = true);
    await _authService.cleanupGhostAccount();
    if (mounted) {
      setState(() => isLoading = false);
      Navigator.of(context).pop();
    }
  }

  bool _isFinalStep() => _step == 1;

  Future<bool> _validateCurrentStepInput() async {
    final l10n = AppLocalizations.of(context, listen: false)!;
    if (_step == 0 && phoneController.text.isEmpty) {
      AppMessenger.showSnackBar(context, title: l10n.required, message: l10n.enterPhone, type: MessengerType.error);
      return false;
    }
    if (_isFinalStep() && !_acceptedTerms) {
      AppMessenger.showSnackBar(context, title: l10n.termsRequired, message: l10n.acceptTermsToFinish, type: MessengerType.error);
      return false;
    }
    return true;
  }

  Future<void> _finishWizard() async {
    final l10n = AppLocalizations.of(context, listen: false)!;
    final navigator = Navigator.of(context);
    setState(() => isLoading = true);
    
    final result = await _authService.createGoogleUserWithRole(
      phone: fullPhoneNumber,
      portfolio: '',
      acceptedTerms: true,
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    // null = success, non-null string = error message
    if (result == null) {
      // Direct to Home Dashboard
      navigator.pushNamedAndRemoveUntil('/home', (route) => false);
    } else {
      AppMessenger.showSnackBar(context, title: l10n.error, message: _localizeError(result, l10n), type: MessengerType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !isLoading, // Prevent pop if we are currently cleaning up
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // If already popped by something else
        
        // 👻 Cleanup if system back or swipe exits the wizard
        await _authService.cleanupGhostAccount();
        
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(color: Colors.black.withValues(alpha: 0.4)),
            ),
            AnimatedPadding(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                constraints: BoxConstraints(
                  maxWidth: 450,
                  maxHeight: MediaQuery.of(context).size.height * 0.85 - MediaQuery.of(context).viewInsets.bottom,
                ),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95), 
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFF006D77).withValues(alpha: 0.1), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        if (_step > 0)
                          Align(
                            alignment: AlignmentDirectional.topStart,
                            child: Container(
                              decoration: BoxDecoration(color: const Color(0xFF006D77).withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, color: Color(0xFF006D77)),
                                onPressed: _prevStep,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                              ),
                            ),
                          ),
                        Align(
                          alignment: AlignmentDirectional.topEnd,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFF006D77)),
                            onPressed: _handleCancel,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      layoutBuilder: (child, list) => Stack(alignment: Alignment.center, children: [...list, if (child != null) child]),
                      child: Container(
                        key: ValueKey<int>(_step),
                        child: !_isStepsInitialized ? const CircularProgressIndicator(color: Color(0xFF006D77)) : _buildStepContent(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_isFinalStep())
                       const SizedBox(height: 10),
                    _isFinalStep()
                        ? SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF006D77),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              onPressed: isLoading ? null : _nextStep,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      l10n.finish,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                            ),
                          )
                        : Row(
                            children: [
                              const Spacer(),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF006D77),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: isLoading ? null : _nextStep,
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(
                                        l10n.next,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ],
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
