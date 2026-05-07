import 'package:flutter/material.dart';

class AppColors {
  // --- 1. Core Brand Colors (Fixed for both modes) ---
  static const Color primary = Color(0xFF1F1F1F); // Legacy constant
  static const Color teal = Color(0xFF006D77); // Primary Brand Blue/Teal
  static const Color tealLight = Color(0xFF83C5BE); // Light Teal
  static const Color accentGold = Color(0xFFD4AF37); // Gold Accent
  static const Color lightGold = Color(0xFFEEE593); // Lighter Gold/Text code

  // Aliases for compatibility
  static const Color textColor = lightGold;
  static const Color secondary = teal;

  // --- 2. Legacy Functional Colors (Keep for compilation, migrate later) ---
  static const Color backgroundLegacy =
      primary; // Renamed locally if possible, but keep background if used
  static const Color background = primary;
  static const Color cardBackground = Color(0xFF2C2C2C);

  // --- 3. Legacy Text & Neutral Colors ---
  static const Color white = Colors.white;
  static const Color white70 = Colors.white70;
  static const Color white54 = Colors.white54;
  static const Color textLight = white70;
  static const Color white38 = Colors.white38;
  static const Color black = Colors.black;
  static const Color black87 = Colors.black87;
  static const Color grey = Colors.grey;
  static const Color slate = Color(0xFF94A3B8); // Neutral Slate
  static const Color darkSlate = Color(0xFF2D3748); // Text/Header Slate
  static const Color lightSlate = Color(0xFFF1F5F9); // Input/BG Slate

  // --- 4. Brand Gradients ---
  static const List<Color> goldGradient = [lightGold, accentGold];
  static const List<Color> tealGradient = [Color(0xFF83C5BE), teal];
  static const List<Color> titleGradientReversed = [teal, Color(0xFF83C5BE)];

  // --- 5. User Colors ---
  static Color getUserColor(String uid) {
    final List<Color> colors = [
      teal,
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.pinkAccent,
      Colors.orangeAccent,
      Colors.indigoAccent,
      Colors.cyan,
      Colors.tealAccent.shade700,
    ];
    return colors[uid.hashCode % colors.length];
  }

  // ===========================================================================
  // PHASE 2: CONTEXT-AWARE THEME HELPERS
  // Use these methods for all adaptive UI elements instead of the static colors
  // ===========================================================================

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color getBackground(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color getSurface(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getSurfaceElevated(BuildContext context) {
    return isDark(context) ? const Color(0xFF2C2C2C) : Colors.white;
  }

  static Color getTextPrimary(BuildContext context) {
    return isDark(context) ? Colors.white : const Color(0xFF1A1D2E);
  }

  static Color getTextSecondary(BuildContext context) {
    return isDark(context) ? const Color(0xFF94A3B8) : const Color(0xFF8E95A9);
  }

  static Color getTextMuted(BuildContext context) {
    return isDark(context) ? Colors.white38 : Colors.black38;
  }

  static Color getBorder(BuildContext context) {
    return isDark(context) ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0);
  }

  static Color getDivider(BuildContext context) {
    return isDark(context) ? Colors.white12 : Colors.black12;
  }

  static Color getShadow(BuildContext context) {
    return isDark(context)
        ? Colors.black54
        : Colors.black.withValues(alpha: 0.06);
  }

  static Color getBottomNavBackground(BuildContext context) {
    return isDark(context) ? const Color(0xFF1F1F1F) : Colors.white;
  }

  static Color getInputBackground(BuildContext context) {
    return isDark(context) ? const Color(0xFF1F1F1F) : const Color(0xFFF1F5F9);
  }

  // --- Chat Specific Helpers ---
  static Color getChatBubbleOther(BuildContext context) {
    return isDark(context) ? const Color(0xFF2C2C2C) : Colors.white;
  }

  static Color getSystemMessageBackground(BuildContext context) {
    return isDark(context)
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.05);
  }

  static Color getSystemMessageText(BuildContext context) {
    return isDark(context) ? Colors.white70 : Colors.grey.shade600;
  }
}
