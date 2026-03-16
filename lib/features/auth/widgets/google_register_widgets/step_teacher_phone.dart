//Refactored
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:phone_number/phone_number.dart';
import 'package:device_region/device_region.dart';
import 'package:laween/l10n/app_localizations.dart';

class StepTeacherPhone extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String fullNumber)? onValidNumber;

  const StepTeacherPhone({
    super.key,
    required this.controller,
    this.onValidNumber,
  });

  @override
  State<StepTeacherPhone> createState() => _StepTeacherPhoneState();
}

class _StepTeacherPhoneState extends State<StepTeacherPhone> {
  final PhoneNumberUtil _phoneNumberUtil = PhoneNumberUtil();
  String? _errorText;
  String _initialCountryCode = "US";

  @override
  void initState() {
    super.initState();
    _getInitialCountryCode();
  }

  Future<void> _getInitialCountryCode() async {
    try {
      // 1. Try SIM Card (Best)
      String? countryCode = await DeviceRegion.getSIMCountryCode();

      // 2. Fallback: Device System Region
      if (countryCode == null || countryCode.isEmpty) {
        final locale = WidgetsBinding.instance.platformDispatcher.locale;
        countryCode = locale.countryCode;
      }
      
      if (!mounted) return;

      if (countryCode != null && countryCode.isNotEmpty) {
        setState(() {
          _initialCountryCode = countryCode!.toUpperCase();
        });
      }
    } catch (e) {
      debugPrint("Error getting country code: $e");
    }
  }

  Future<void> _validateAndFormatPhone(String number, String isoCode) async {
    try {
      final isValid = await _phoneNumberUtil.validate(number, regionCode: isoCode);

      if (!mounted) return;

      if (isValid) {
        final parsed = await _phoneNumberUtil.parse(number, regionCode: isoCode);
        setState(() => _errorText = null);
        widget.onValidNumber?.call(parsed.e164);
      } else {
        setState(() => _errorText = AppLocalizations.of(context)!.invalidMobileNumber);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = AppLocalizations.of(context)!.invalidMobileNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.yourPhoneNumber,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        IntlPhoneField(
          initialCountryCode: _initialCountryCode,
          invalidNumberMessage: AppLocalizations.of(context)!.invalidMobileNumber,
          style: const TextStyle(color: Colors.white),
          dropdownTextStyle: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: l10n.phoneNumber,
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            errorText: _errorText,
          ),
          onChanged: (phone) {
            _validateAndFormatPhone(phone.number, phone.countryISOCode);

            // This logic is fine, as it's synchronous and only runs
            // when the widget is mounted and receiving an event.
            if (widget.controller.value.isComposingRangeValid) {
              widget.controller.text = phone.completeNumber;
            }
          },
        ),
      ],
    );
  }
}
