import 'package:flutter/material.dart';
import 'package:laween/l10n/app_localizations.dart';
import 'package:laween/core/theme/colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FinishVerificationStep extends StatelessWidget {
  const FinishVerificationStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        // Success Icon Animation
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.check_circle_rounded,
              color: Colors.green.shade600,
              size: 64,
            ),
          ),
        ).animate().scale(
              duration: 600.ms,
              curve: Curves.elasticOut,
            ).fadeIn(),
        
        const SizedBox(height: 24),
        
        Text(
          l10n.allVerified,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
        
        const SizedBox(height: 12),
        
        Text(
          "Your identity has been confirmed. Tap the button below to complete your registration.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black.withOpacity(0.5),
            fontSize: 15,
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
        
        const SizedBox(height: 10),
      ],
    );
  }
}
