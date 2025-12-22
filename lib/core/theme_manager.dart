import 'package:flutter/material.dart';

class ThemeManager extends ChangeNotifier {
  // Singleton
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  String? _currentFontFamily = 'AppFont'; // 預設使用宇文天穹體

  String? get currentFontFamily => _currentFontFamily;

  void setFontFamily(String? fontFamily) {
    if (_currentFontFamily != fontFamily) {
      _currentFontFamily = fontFamily;
      notifyListeners();
    }
  }
}
