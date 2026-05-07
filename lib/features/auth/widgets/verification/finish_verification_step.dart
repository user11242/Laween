import 'package:flutter/material.dart';
import 'package:laween/l10n/app_localizations.dart';
import '../../../../core/theme/colors.dart';

class FinishVerificationStep extends StatelessWidget {
  const FinishVerificationStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.allVerified,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.getTextPrimary(context),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
