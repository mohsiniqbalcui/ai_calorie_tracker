import 'package:flutter/material.dart';

/// Brand palette: forest green, soft mint, warm off-white, charcoal text.
class AppColors {
  static const forest = Color(0xFF2E6B47);
  static const forestDark = Color(0xFF8FD6A8); // primary on dark surfaces
  static const mint = Color(0xFFDDF3E4);
  static const mintDark = Color(0xFF1F3B2B);

  static const offWhite = Color(0xFFFAF8F3);
  static const white = Colors.white;
  static const charcoal = Color(0xFF1F2A24);
  static const muted = Color(0xFF66736B);
  static const line = Color(0xFFE6E8E3);

  static const darkBackground = Color(0xFF101512);
  static const darkSurface = Color(0xFF18201B);
  static const darkLine = Color(0xFF263029);
  static const darkText = Color(0xFFEAF1EC);
  static const darkMuted = Color(0xFF9AA8A0);
}

/// Semantic nutrition colors, used for the same nutrient everywhere.
class MacroColors {
  static const protein = Color(0xFF22A06B);
  static const carbs = Color(0xFFF2A93B);
  static const fat = Color(0xFFE5604D);
  static const calories = Color(0xFFFF7A29);
  static const water = Color(0xFF3B9BE8);
}
