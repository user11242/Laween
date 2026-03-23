import 'package:flutter/material.dart';

class AppColors {
  // --- 1. Core Brand Colors ---
  static const Color primary = Color(0xFF1F1F1F); // Dark Background
  static const Color teal = Color(0xFF006D77);     // Primary Brand Blue/Teal
  static const Color accentGold = Color(0xFFD4AF37); // Gold Accent
  static const Color lightGold = Color(0xFFEEE593); // Lighter Gold/Text code
  
  // Aliases for compatibility
  static const Color textColor = lightGold;
  static const Color secondary = teal;
  
  // --- 2. Functional Colors ---
  static const Color background = primary;
  static const Color cardBackground = Color(0xFF2C2C2C);
  
  // --- 3. Text & Neutral Colors ---
  static const Color white = Colors.white;
  static const Color white70 = Colors.white70;
  static const Color white54 = Colors.white54;
  static const Color textLight = white70; // Added for compatibility
  static const Color white38 = Colors.white38;
  static const Color black = Colors.black;
  static const Color black87 = Colors.black87;
  static const Color grey = Colors.grey;
  static const Color slate = Color(0xFF94A3B8);      // Neutral Slate
  static const Color darkSlate = Color(0xFF2D3748);  // Text/Header Slate
  static const Color lightSlate = Color(0xFFF1F5F9); // Input/BG Slate

  // --- 4. Gradients ---
  static const List<Color> goldGradient = [lightGold, accentGold];
  static const List<Color> tealGradient = [Color(0xFF83C5BE), teal]; // Lighter teal to primary teal
  static const List<Color> titleGradientReversed = [teal, Color(0xFF83C5BE)];
}
