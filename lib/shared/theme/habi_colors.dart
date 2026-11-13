import 'package:flutter/material.dart';

import 'habi_appearance.dart';

/// HABI's evergreen, woven-neutral palette.
class HabiColors {
  HabiColors._();

  static const teal = Color(0xFF17665E);
  static const deepTeal = Color(0xFF103A36);
  static const mint = Color(0xFF8AD0C1);
  static const terracotta = Color(0xFF9E4D35);
  static const terracottaLight = Color(0xFFF0A084);
  static const wovenGold = Color(0xFFC7973D);
  static const goldDark = Color(0xFF755314);
  static const gold = wovenGold;
  static const error = Color(0xFFB3261E);
  static const errorLight = Color(0xFFFFB4AB);
  static const success = Color(0xFF2F765E);
  static const warning = Color(0xFF8B5A13);

  static const lightBackground = Color(0xFFF4F7F5);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFEEF3F0);
  static const darkBackground = Color(0xFF0D1715);
  static const darkSurface = Color(0xFF14211E);
  static const darkSurfaceVariant = Color(0xFF1B2B27);
  static const darkRaised = Color(0xFF233631);

  // Kept for screens still being migrated; new views should use ColorScheme.
  static const ivory = lightBackground;
  static const loom = Color(0xFFE2EAE5);
  static const text = Color(0xFF172320);
  static const secondaryText = Color(0xFF52635D);
  static bool get isDarkMode => HabiAppearance.instance.isDarkMode;
  static Color get ink => text;
  static Color get navy => isDarkMode ? darkBackground : lightBackground;
  static Color get navyMid => isDarkMode ? darkSurface : lightSurface;
  static Color get navyLight => isDarkMode ? darkRaised : teal;
  static Color get cream => isDarkMode ? const Color(0xFFEAF2EE) : text;
  static Color get tan => isDarkMode ? const Color(0xFFB3C4BD) : secondaryText;
}
