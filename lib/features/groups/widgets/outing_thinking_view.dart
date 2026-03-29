// lib/features/groups/widgets/outing_thinking_view.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/colors.dart';

class OutingThinkingView extends StatelessWidget {
  final String category;
  final bool isMe;

  const OutingThinkingView({
    super.key,
    required this.category,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer Radar Ring 1
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.teal.withValues(alpha: 0.1), width: 1),
              ),
            ).animate(onPlay: (c) => c.repeat()).scale(
              begin: const Offset(1, 1),
              end: const Offset(1.5, 1.5),
              duration: 2000.milliseconds,
              curve: Curves.easeOut,
            ).fadeOut(duration: 2000.milliseconds),

            // Outer Radar Ring 2
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.teal.withValues(alpha: 0.2), width: 1),
              ),
            ).animate(onPlay: (c) => c.repeat(period: 2000.milliseconds)).scale(
              begin: const Offset(1, 1),
              end: const Offset(1.5, 1.5),
              duration: 2000.milliseconds,
              curve: Curves.easeOut,
            ).fadeOut(duration: 2000.milliseconds),

            // Center Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.location_searching_rounded, color: AppColors.teal, size: 32),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2000.milliseconds, color: Colors.white54),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          "Finding the perfect $category...",
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isMe ? Colors.white : AppColors.darkSlate,
          ),
        ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 1000.milliseconds).then().fadeOut(delay: 1000.milliseconds),
        const SizedBox(height: 8),
        Text(
          "Calculating middle ground for everyone",
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isMe ? Colors.white70 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
