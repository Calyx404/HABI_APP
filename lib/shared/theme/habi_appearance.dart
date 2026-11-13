import 'package:flutter/material.dart';

class HabiAppearance extends ChangeNotifier {
  HabiAppearance._();

  static final HabiAppearance instance = HabiAppearance._();

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void setDarkMode(bool value) {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
  }
}
