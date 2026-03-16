// lib/core/theme/colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Existing Colors (unchanged)
  static const Color primary = Color(0xFF1F1F1F); // Your main dark background
  static const Color background = primary;
  static const Color textColor = Color(
    0xFFEEE593,
  ); // Your existing text color (light gold/yellow)
  static const Color secondary = Colors.white70;
  static const Color black = Colors.black;
  static const Color accentBrown = Color(0xFF8B4513);
  static const Color white = Colors.white;
  static const Color white70 = Colors.white70;
  static const Color white54 = Colors.white54;
  static const Color white38 = Colors.white38;
  static const Color black87 = Colors.black87;

  // Existing Gradients (unchanged)
  static const List<Color> titleGradient = [textColor, accentBrown];
  static const List<Color> titleGradientReversed = [accentBrown, textColor];

  // New Colors for Dashboard (added)
  // Re-evaluating based on your existing `textColor` which is also a light gold/yellow
  // I will make `accentGold` a slightly richer, more vibrant gold to differentiate from `textColor` if needed,
  // or align it if `textColor` is meant to be the primary gold accent.
  // For consistency with the dashboard design, I'll define `accentGold` as the primary gold for interactive elements.

  static const Color cardBackground = Color(
    0xFF2C2C2C,
  ); // Slightly lighter dark for cards
  static const Color accentGold = Color(
    0xFFD4AF37,
  ); // A rich gold accent for buttons/active states
  static const Color goldGradientStart = Color(
    0xFFE0C17E,
  ); // Lighter gold for gradients
  static const Color goldGradientEnd = Color(
    0xFFB58C28,
  ); // Darker gold for gradients

  // Adjusting text colors to align with your new `textColor` and the dashboard design
  static const Color textLight = Colors
      .white70; // For secondary text (can be same as `secondary` if preferred)
  static const Color textPrimary =
      Colors.white; // For primary text (can be same as `white` if preferred)

  // You might consider if `textColor` (EEE593) should be used instead of `accentGold` or `goldGradientStart` in some places,
  // depending on how you want to unify your gold tones across the app.
  // For now, `accentGold` is specifically for the dashboard's interactive gold.
}
