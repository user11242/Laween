import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/numeric_utils.dart';
import '../../../../core/message/app_messenger.dart';
import '../../data/services/auth_service.dart';
import '../material_pin_field.dart';

class UniversalOtpStep extends StatefulWidget {
  final String destination;
  final VoidCallback onVerified;
  final bool isLight;

  const UniversalOtpStep({
    super.key,
    required this.destination,
    required this.onVerified,
    this.isLight = false,
  });

  @override
  UniversalOtpStepState createState() => UniversalOtpStepState();
}

class UniversalOtpStepState extends State<UniversalOtpStep> {
  final AuthService _authService = AuthService();
  final TextEditingController otpController = TextEditingController();

  String? _verificationId;
  int? _resendToken;
  String? _generatedEmailOtp;
  DateTime? _otpExpiry;
  int _resendCooldown = 0;
  Timer? _timer;
  bool isLoading = false;

  bool get _isEmail => widget.destination.contains('@');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendOtp();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    if (_timer?.isActive ?? false) return;
    setState(() => _resendCooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 0) {
        timer.cancel();
        setState(() {});
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _sendOtp() async {
    final l10n = AppLocalizations.of(context, listen: false)!;
    if (widget.destination.isEmpty || isLoading) return;
    setState(() => isLoading = true);
    try {
      if (_isEmail) {
        _generatedEmailOtp = (Random().nextInt(900000) + 100000).toString();
        _otpExpiry = DateTime.now().add(const Duration(minutes: 10));
        await _authService.sendEmailOtp(widget.destination, _generatedEmailOtp!);
        _startCooldown();
        if (!mounted) return;
        AppMessenger.showSnackBar(context, title: l10n.otpSent, message: l10n.checkInbox, type: MessengerType.success);
      } else {
        await _authService.startPhoneVerification(
          phone: widget.destination,
          codeSent: (id, token) {
            if (mounted) {
              setState(() {
                _verificationId = id;
                _resendToken = token;
                isLoading = false;
              });
              _startCooldown();
              AppMessenger.showSnackBar(context, title: l10n.smsSent, message: l10n.checkMessages, type: MessengerType.success);
            }
          },
          forceResendingToken: _resendToken,
          onError: (err) {
            AppMessenger.showSnackBar(context, title: l10n.smsError, message: err, type: MessengerType.error);
            if (mounted) setState(() => isLoading = false);
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppMessenger.showSnackBar(context, title: l10n.error, message: e.toString(), type: MessengerType.error);
    } finally {
      if (_isEmail && mounted) setState(() => isLoading = false);
    }
  }

  Future<bool> verifyAndSubmit() async {
    if (isLoading) return false;
    final l10n = AppLocalizations.of(context, listen: false)!;
    final rawCode = otpController.text.trim();
    final smsCode = NumericUtils.normalize(rawCode);

    if (smsCode.length != 6) {
      AppMessenger.showSnackBar(context, title: l10n.inputError, message: l10n.enter6Digits, type: MessengerType.error);
      return false;
    }

    setState(() => isLoading = true);
    try {
      bool success = false;
      if (_isEmail) {
        if (_otpExpiry != null && DateTime.now().isAfter(_otpExpiry!)) {
          AppMessenger.showSnackBar(context, title: l10n.error, message: "OTP code has expired.", type: MessengerType.error);
          setState(() => isLoading = false);
          return false;
        }
        success = (smsCode == _generatedEmailOtp);
      } else {
        if (_verificationId == null) {
          AppMessenger.showSnackBar(context, title: l10n.error, message: l10n.idMissing, type: MessengerType.error);
          return false;
        }
        final cred = await _authService.verifySmsCode(verificationId: _verificationId!, smsCode: smsCode);
        success = (cred != null);
      }

      if (success) {
        widget.onVerified();
        return true;
      } else {
        if (!mounted) return false;
        AppMessenger.showSnackBar(context, title: l10n.incorrectCode, message: l10n.pleaseTryAgain, type: MessengerType.error);
        return false;
      }
    } catch (e) {
      if (!mounted) return false;
      AppMessenger.showSnackBar(context, title: l10n.error, message: e.toString(), type: MessengerType.error);
      return false;
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Destination Icon & Text
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.getSurfaceElevated(context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isEmail ? Icons.email_outlined : Icons.phone_android_rounded,
                  color: AppColors.teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEmail ? l10n.verifyEmail : l10n.verifyPhone,
                      style: TextStyle(
                        color: AppColors.getTextSecondary(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      NumericUtils.normalize(widget.destination),
                      style: TextStyle(
                        color: AppColors.getTextPrimary(context),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1),

        const SizedBox(height: 32),

        // OTP Input Fields
        Directionality(
          textDirection: TextDirection.ltr,
          child: MaterialPinField(
            length: 6,
            controller: otpController,
            isLight: widget.isLight,
            onChanged: (v) {
              if (v.length == 6) verifyAndSubmit();
            },
          ),
        ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),

        const SizedBox(height: 32),

        // Resend Timer / Button
        if (isLoading)
          const SizedBox(
            height: 48,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
            ),
          )
        else
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _resendCooldown > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: AppColors.getTextSecondary(context)),
                        const SizedBox(width: 8),
                        Text(
                          l10n.resendIn(_resendCooldown),
                          style: TextStyle(
                            color: AppColors.getTextSecondary(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : TextButton.icon(
                    onPressed: _sendOtp,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(l10n.resendCode),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }
}
