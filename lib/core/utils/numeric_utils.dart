import 'package:flutter/services.dart';

class NumericUtils {
  static TextInputFormatter get digitFormatter => FilteringTextInputFormatter.digitsOnly;

  static String normalize(String input, {bool clean = false}) {
    String normalized = normalizeDigits(input);
    if (clean) {
      // Preserve leading '+' for international phone numbers
      final hasPlus = normalized.startsWith('+');
      String cleaned = normalized.replaceAll(RegExp(r'\D'), '');
      return hasPlus ? '+$cleaned' : cleaned;
    }
    return normalized;
  }

  static String normalizeDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const indic = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

    for (int i = 0; i < 10; i++) {
      input = input.replaceAll(arabic[i], english[i]);
      input = input.replaceAll(indic[i], english[i]);
    }
    return input;
  }
}
