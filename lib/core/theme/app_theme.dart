import 'package:flutter/material.dart';
import '../../presentation/cubit/settings_cubit.dart';

class MacroColors {
  static const protein = Color(0xFF22A06B);
  static const carbs = Color(0xFFF2A93B);
  static const fat = Color(0xFFE5604D);
  static const calories = Color(0xFFFF7A29);
  static const water = Color(0xFF3B9BE8);
}

class AppTheme {
  static ThemeData build(UiMode mode, Brightness brightness) {
    final pro = mode == UiMode.pro;
    final dark = brightness == Brightness.dark;
    var scheme = ColorScheme.fromSeed(
      seedColor: pro ? const Color(0xFF1D4ED8) : const Color(0xFF2E9E5B),
      brightness: brightness,
    );
    if (pro && !dark) {
      // Clean white surfaces for the professional look.
      scheme = scheme.copyWith(
        surface: Colors.white,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFF8FAFC),
        outlineVariant: const Color(0xFFE5E7EB),
      );
    }
    final radius = pro ? 14.0 : 22.0;
    final background = pro
        ? (dark ? const Color(0xFF0B0F1A) : Colors.white)
        : (dark ? const Color(0xFF111713) : const Color(0xFFF3FAF5));
    final cardColor = dark
        ? (pro ? const Color(0xFF141A2B) : const Color(0xFF1A221D))
        : Colors.white;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      visualDensity: pro ? VisualDensity.compact : VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: !pro,
        foregroundColor: scheme.onSurface,
        shape: pro ? Border(bottom: BorderSide(color: dark ? const Color(0xFF232C45) : const Color(0xFFE5E7EB))) : null,
        titleTextStyle: TextStyle(
          fontSize: pro ? 18 : 20,
          fontWeight: FontWeight.w700,
          letterSpacing: pro ? 0.2 : 0,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: pro
              ? BorderSide(color: dark ? const Color(0xFF232C45) : const Color(0xFFE5E7EB))
              : BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark
            ? Colors.white.withValues(alpha: 0.06)
            : (pro ? const Color(0xFFF3F4F6) : scheme.primary.withValues(alpha: 0.06)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius - 4), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius - 4),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius - 2)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius - 2)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pro ? 16 : 28)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: pro && !dark ? Colors.white : cardColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        height: pro ? 64 : 72,
        indicatorColor: scheme.primary.withValues(alpha: pro ? 0.16 : 0.22),
        labelBehavior: pro
            ? NavigationDestinationLabelBehavior.onlyShowSelected
            : NavigationDestinationLabelBehavior.alwaysShow,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pro ? 10 : 20)),
        side: BorderSide.none,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius + 6))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius + 2)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.5), space: 1),
    );
  }
}
