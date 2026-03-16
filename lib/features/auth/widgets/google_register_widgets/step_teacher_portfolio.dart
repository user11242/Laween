import 'package:flutter/material.dart';
import 'package:laween/l10n/app_localizations.dart';
import '../../widgets/auth_text_field.dart';

class StepTeacherPortfolio extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final Function(String)? onChanged;
  final VoidCallback? onPaste;

  const StepTeacherPortfolio({
    super.key, 
    required this.controller,
    this.errorText,
    this.onChanged,
    this.onPaste,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.portfolioLink,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: controller,
          hint: l10n.portfolioHint,
          icon: Icons.link,
          onChanged: onChanged,
          errorText: errorText,
          keyboardType: TextInputType.url,
          isSuccess: errorText == null && controller.text.isNotEmpty,
          onPaste: onPaste,
        ),
      ],
    );
  }
}
