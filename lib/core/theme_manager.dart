import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
  // Singleton
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  static const String _fontFamilyKey = 'selected_font_family';
  String? _currentFontFamily;
  bool _isInitialized = false;

  String? get currentFontFamily => _currentFontFamily;
  bool get isInitialized => _isInitialized;

  // 初始化時從本地儲存讀取字體設定
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final savedFont = prefs.getString(_fontFamilyKey);
    
    // 如果沒有儲存過設定,savedFont 會是 null,這樣就會使用預設字體(粉圓體)
    // 或者如果之前儲存的是空字串(舊的系統預設),也改為使用粉圓體
    if (savedFont == null || savedFont.isEmpty) {
      _currentFontFamily = 'OpenHuninn';
    } else {
      _currentFontFamily = savedFont;
    }
    _isInitialized = true;
    notifyListeners();
  }

  // 設定字體並儲存到本地
  Future<void> setFontFamily(String? fontFamily) async {
    if (_currentFontFamily != fontFamily) {
      _currentFontFamily = fontFamily;
      
      final prefs = await SharedPreferences.getInstance();
      if (fontFamily == null) {
        // 如果選擇系統預設,儲存空字串以區分「未設定過」和「選擇系統預設」
        await prefs.setString(_fontFamilyKey, '');
      } else {
        await prefs.setString(_fontFamilyKey, fontFamily);
      }
      
      notifyListeners();
    }
  }
}
