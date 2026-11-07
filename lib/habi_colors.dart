import 'package:flutter/material.dart';

import 'habi_appearance.dart';

/// Colors adapt to the global appearance setting.
class HabiColors {
  static const Color ink = Color(0xFF0A1428);
  static const Color _navyDark = Color(0xFF0A1428);
  static const Color _navyMidDark = Color(0xFF101F42);
  static const Color _navyLightDark = Color(0xFF182B58);
  static const Color _creamDark = Color(0xFFF4E8D0);
  static const Color _tanDark = Color(0xFFC8B48C);
  static const Color _goldDarkMode = Color(0xFFD6AA52);
  static const Color _beige = Color(0xFFE8D5B9);
  static const Color _beigeSurface = Color(0xFFF3E4CF);
  static const Color _beigeDeep = Color(0xFFE2CFB1);
  static const Color _navyText = Color(0xFF132544);
  static const Color _mutedNavyText = Color(0xFF34445D);

  static bool get isDarkMode => HabiAppearance.instance.isDarkMode;
  static Color get navy => isDarkMode ? _navyDark : _beige;
  static Color get navyMid => isDarkMode ? _navyMidDark : _beigeSurface;
  static Color get navyLight => isDarkMode ? _navyLightDark : _beigeDeep;
  static Color get gold => isDarkMode ? _goldDarkMode : goldDark;
  static const Color goldDark = Color(0xFFB98A30);
  static Color get cream => isDarkMode ? _creamDark : _navyText;
  static Color get tan => isDarkMode ? _tanDark : _mutedNavyText;
}
