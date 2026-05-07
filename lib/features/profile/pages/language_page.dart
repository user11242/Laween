import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:laween/core/providers/locale_provider.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLanguageCode = localeProvider.locale.languageCode;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getBackground(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.getTextPrimary(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.selectLanguage,
          style: GoogleFonts.inter(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildLanguageOption(
              context: context,
              title: l10n.english,
              subtitle: "English",
              isSelected: currentLanguageCode == 'en',
              onTap: () => localeProvider.setLocale(const Locale('en')),
            ),
            const SizedBox(height: 16),
            _buildLanguageOption(
              context: context,
              title: l10n.arabic,
              subtitle: "العربية",
              isSelected: currentLanguageCode == 'ar',
              onTap: () => localeProvider.setLocale(const Locale('ar')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.teal.withValues(alpha: 0.05)
              : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.teal : AppColors.getDivider(context),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.teal : AppColors.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.teal, size: 28)
            else
              Icon(
                Icons.circle_outlined,
                color: AppColors.getDivider(context),
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
