import 'package:flutter/material.dart';
import '../../presentation/cubit/settings_cubit.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

export 'app_colors.dart';
export 'app_spacing.dart';

/// One design language for both UI modes. Simple sits on a warm off-white
/// canvas with soft cards; Pro uses a white canvas with hairline borders.
class AppTheme {
  static ThemeData build(UiMode mode, Brightness brightness) {
    final pro = mode == UiMode.pro;
    final dark = brightness == Brightness.dark;

    final base = ColorScheme.fromSeed(
        seedColor: AppColors.forest, brightness: brightness);
    final scheme = base.copyWith(
      primary: dark ? AppColors.forestDark : AppColors.forest,
      onPrimary: dark ? AppColors.darkBackground : Colors.white,
      primaryContainer: dark ? AppColors.mintDark : AppColors.mint,
      onPrimaryContainer: dark ? AppColors.darkText : AppColors.forest,
      surface: dark ? AppColors.darkSurface : Colors.white,
      onSurface: dark ? AppColors.darkText : AppColors.charcoal,
      onSurfaceVariant: dark ? AppColors.darkMuted : AppColors.muted,
      surfaceContainerLowest: dark ? AppColors.darkBackground : Colors.white,
      surfaceContainerLow:
          dark ? AppColors.darkSurface : const Color(0xFFF5F4EF),
      surfaceContainerHighest:
          dark ? const Color(0xFF222C26) : const Color(0xFFEEF0EA),
      outlineVariant: dark ? AppColors.darkLine : AppColors.line,
    );

    final background = dark
        ? AppColors.darkBackground
        : (pro ? Colors.white : AppColors.offWhite);
    final cardColor = dark ? AppColors.darkSurface : Colors.white;
    final line = dark ? AppColors.darkLine : AppColors.line;

    final text = Typography.material2021(platform: TargetPlatform.android)
        .black
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: c == Colors.transparent
              ? BorderSide.none
              : BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w800, color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark
            ? Colors.white.withValues(alpha: 0.06)
            : (pro ? const Color(0xFFF5F6F3) : Colors.white),
        border: border(Colors.transparent),
        enabledBorder: border(pro || dark ? Colors.transparent : line),
        focusedBorder: border(scheme.primary, 1.6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, Heights.button),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.md)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, Heights.button),
          side: BorderSide(color: line),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.md)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, Heights.button),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.md)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        extendedTextStyle:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md + 2)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        height: 68,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              size: 24,
              color: s.contains(WidgetState.selected)
                  ? scheme.primary
                  : scheme.onSurfaceVariant,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontSize: 12,
              fontWeight: s.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: s.contains(WidgetState.selected)
                  ? scheme.primary
                  : scheme.onSurfaceVariant,
            )),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.pill)),
        side: BorderSide(color: line),
        backgroundColor: cardColor,
        selectedColor: scheme.primaryContainer,
        labelStyle:
            TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
        showCheckmark: false,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(Radii.lg + 6))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.lg)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md)),
      ),
      dividerTheme: DividerThemeData(color: line, space: 1),
    );
  }
}
