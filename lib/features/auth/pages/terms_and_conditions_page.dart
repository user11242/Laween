import 'package:flutter/material.dart';
import 'package:laween/l10n/app_localizations.dart';
import '../../../../core/theme/colors.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: Text(
          l10n.termsAndConditions,
          style: TextStyle(color: AppColors.getTextPrimary(context)),
        ),
        backgroundColor: AppColors.getSurface(context),
        iconTheme: IconThemeData(color: AppColors.getTextPrimary(context)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          l10n.termsAndConditionsContent,
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
