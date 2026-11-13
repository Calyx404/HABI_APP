import 'package:flutter/material.dart';

import 'habi_colors.dart';

class HabiSpacing {
  HabiSpacing._();
  static const double xxs = 2;
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double xxl = 32;
  static const double section = 40;
}

class HabiRadius {
  HabiRadius._();
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 30;
  static const double pill = 999;
}

class HabiTypography {
  HabiTypography._();
  static const String displayFontFamily = 'KumarOne';
  static const String? fontFamily = null;
}

class HabiShadows {
  HabiShadows._();
  static const card = [
    BoxShadow(color: Color(0x0A102B29), blurRadius: 20, offset: Offset(0, 7)),
  ];
  static const floating = [
    BoxShadow(color: Color(0x2110201E), blurRadius: 26, offset: Offset(0, 12)),
  ];
}

class HabiAnimationConfig {
  HabiAnimationConfig._();
  static const duration = Duration(milliseconds: 240);
  static const emphasized = Duration(milliseconds: 360);
  static const curve = Curves.easeOutCubic;
}

class HabiTheme {
  HabiTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: isDark ? HabiColors.mint : HabiColors.teal,
          brightness: brightness,
          primary: isDark ? HabiColors.mint : HabiColors.teal,
          onPrimary: isDark ? HabiColors.deepTeal : Colors.white,
          secondary: isDark
              ? HabiColors.terracottaLight
              : HabiColors.terracotta,
          onSecondary: isDark ? HabiColors.deepTeal : Colors.white,
          surface: isDark ? HabiColors.darkSurface : HabiColors.lightSurface,
          error: isDark ? HabiColors.errorLight : HabiColors.error,
        ).copyWith(
          surfaceContainerLowest: isDark
              ? HabiColors.darkBackground
              : HabiColors.lightBackground,
          surfaceContainerLow: isDark
              ? HabiColors.darkSurface
              : HabiColors.lightSurface,
          surfaceContainer: isDark
              ? HabiColors.darkSurfaceVariant
              : HabiColors.lightSurfaceVariant,
          surfaceContainerHigh: isDark
              ? HabiColors.darkRaised
              : const Color(0xFFE9EFEC),
          surfaceContainerHighest: isDark
              ? const Color(0xFF2B3B37)
              : const Color(0xFFE0E8E4),
          outline: isDark ? const Color(0xFF60736D) : const Color(0xFFB6C3BD),
          outlineVariant: isDark
              ? const Color(0xFF354641)
              : const Color(0xFFD9E1DC),
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? HabiColors.darkBackground
          : HabiColors.lightBackground,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
    );
    final text = base.textTheme;

    return base.copyWith(
      textTheme: text.copyWith(
        displayLarge: text.displayLarge?.copyWith(
          fontFamily: HabiTypography.displayFontFamily,
          fontSize: 28,
          height: 1.24,
          fontWeight: FontWeight.w400,
          letterSpacing: -.4,
        ),
        headlineLarge: text.headlineLarge?.copyWith(
          fontFamily: HabiTypography.displayFontFamily,
          fontSize: 22,
          height: 1.3,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontFamily: HabiTypography.displayFontFamily,
          fontSize: 19,
          height: 1.35,
          fontWeight: FontWeight.w400,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -.25,
        ),
        titleMedium: text.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: text.bodyLarge?.copyWith(fontSize: 16, height: 1.45),
        bodyMedium: text.bodyMedium?.copyWith(fontSize: 14, height: 1.45),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: text.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HabiRadius.md),
          side: BorderSide(color: scheme.outlineVariant.withAlpha(150)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HabiRadius.sm),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 10.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: HabiSpacing.lg,
          vertical: HabiSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HabiRadius.sm),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HabiRadius.sm),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HabiRadius.sm),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HabiRadius.sm),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HabiRadius.sm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HabiRadius.sm),
          ),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? HabiColors.darkRaised : HabiColors.deepTeal,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HabiRadius.sm),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
