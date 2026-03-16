import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../l10n/app_localizations.dart';

class GoogleHintDialog extends StatelessWidget {
  final VoidCallback onContinue;

  const GoogleHintDialog({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Dialog(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.login, color: AppColors.white, size: 48),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.continueRegistrationWithGoogle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.black87,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Image.asset(
                  "assets/icons/circle_google_icon.png",
                  height: 24,
                  width: 24,
                ),
                label: Text(
                  AppLocalizations.of(context)!.continueWithGoogle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onPressed: onContinue, // ✅ no Navigator.pop here
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  AppLocalizations.of(context)!.maybeLater,
                  style: const TextStyle(color: AppColors.secondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
