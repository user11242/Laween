import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:laween/l10n/app_localizations.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../../core/message/app_messenger.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/numeric_utils.dart';

class UniversalOtpStep extends StatefulWidget {
  final String destination;
  final VoidCallback onVerified;

  const UniversalOtpStep({
    super.key,
    required this.destination,
    required this.onVerified,
  });

  @override
  UniversalOtpStepState createState() => UniversalOtpStepState();
}

class UniversalOtpStepState extends State<UniversalOtpStep> {
  final AuthService _authService = AuthService();
  late PinInputController otpController;

  String? _verificationId;
  int? _resendToken;
  String? _generatedEmailOtp;
  int _resendCooldown = 0;
  Timer? _timer;
  bool isLoading = false;

  bool get _isEmail => widget.destination.contains('@');

  @override
  void initState() {
    super.initState();
    otpController = PinInputController();
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
    
    debugPrint("DEBUG: verifyAndSubmit called for ${widget.destination} with code: $smsCode");

    if (smsCode.length != 6) {
      AppMessenger.showSnackBar(context, title: l10n.inputError, message: l10n.enter6Digits, type: MessengerType.error);
      return false;
    }

    setState(() => isLoading = true);
    try {
      bool success = false;
      if (_isEmail) {
        debugPrint("DEBUG: Comparing email OTP: $smsCode vs $_generatedEmailOtp");
        success = (smsCode == _generatedEmailOtp);
      } else {
        if (_verificationId == null) {
          debugPrint("DEBUG: Error: _verificationId is null for phone OTP");
          AppMessenger.showSnackBar(context, title: l10n.error, message: l10n.idMissing, type: MessengerType.error);
          return false;
        }
        debugPrint("DEBUG: Verifying phone OTP for ID: $_verificationId");
        final cred = await _authService.verifySmsCode(verificationId: _verificationId!, smsCode: smsCode);
        success = (cred != null);
      }

      debugPrint("DEBUG: Verification result: $success");
      if (success) {
        widget.onVerified();
        return true;
      } else {
        if (!mounted) return false;
        AppMessenger.showSnackBar(context, title: l10n.incorrectCode, message: l10n.pleaseTryAgain, type: MessengerType.error);
        return false;
      }
    } catch (e) {
      debugPrint("DEBUG: OTP verification exception: $e");
      if (!mounted) return false;
      AppMessenger.showSnackBar(context, title: l10n.error, message: l10n.verificationFailed, type: MessengerType.error);
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
        Text(
          l10n.enterCodeSentTo(NumericUtils.normalize(widget.destination)),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
        ),
        const SizedBox(height: 30),
        Directionality(
          textDirection: TextDirection.ltr,
          child: MaterialPinField(
            length: 6,
            pinController: otpController,
            keyboardType: TextInputType.number,
            theme: MaterialPinTheme(
              shape: MaterialPinShape.outlined,
              borderRadius: BorderRadius.circular(10),
              cellSize: const Size(40, 50),
              borderColor: Colors.white.withValues(alpha: 0.3),
              focusedBorderColor: AppColors.accentGold,
              filledBorderColor: AppColors.accentGold,
              fillColor: Colors.white.withValues(alpha: 0.05),
              focusedFillColor: AppColors.accentGold.withValues(alpha: 0.2),
              filledFillColor: AppColors.accentGold.withValues(alpha: 0.1),
              textStyle: const TextStyle(color: Colors.white),
            ),
            inputFormatters: [NumericUtils.digitFormatter],
            onChanged: (v) {
              if (v.length == 6) verifyAndSubmit();
            },
          ),
        ),
        TextButton(
          onPressed: (isLoading || _resendCooldown > 0) ? null : _sendOtp,
          child: Text(
            _resendCooldown > 0 ? l10n.resendIn(_resendCooldown) : l10n.resendCode,
            style: TextStyle(color: _resendCooldown > 0 ? Colors.grey : AppColors.secondary),
          ),
        ),
      ],
    );
  }
}
