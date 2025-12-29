import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 字體大小枚舉
enum FontSize {
  small(0.9, '小'),
  medium(1.0, '中'),
  large(1.1, '大');

  final double scale;
  final String displayName;

  const FontSize(this.scale, this.displayName);
}

class ThemeManager extends ChangeNotifier {
  // Singleton
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  static const String _fontFamilyKey = 'selected_font_family';
  static const String _fontSizeKey = 'selected_font_size';
  
  String? _currentFontFamily;
  FontSize _currentFontSize = FontSize.medium;
  bool _isInitialized = false;

  String? get currentFontFamily => _currentFontFamily;
  FontSize get currentFontSize => _currentFontSize;
  double get currentTextScaleFactor => _currentFontSize.scale;
  bool get isInitialized => _isInitialized;

  // 初始化時從本地儲存讀取字體設定
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final savedFont = prefs.getString(_fontFamilyKey);
    final savedFontSizeIndex = prefs.getInt(_fontSizeKey);
    
    // 如果沒有儲存過設定,savedFont 會是 null,這樣就會使用預設字體(粉圓體)
    // 或者如果之前儲存的是空字串(舊的系統預設),也改為使用粉圓體
    if (savedFont == null || savedFont.isEmpty) {
      _currentFontFamily = 'OpenHuninn';
    } else {
      _currentFontFamily = savedFont;
    }
    
    // 讀取字體大小設定，預設為中
    if (savedFontSizeIndex != null && savedFontSizeIndex >= 0 && savedFontSizeIndex < FontSize.values.length) {
      _currentFontSize = FontSize.values[savedFontSizeIndex];
    } else {
      _currentFontSize = FontSize.medium;
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

  // 設定字體大小並儲存到本地
  Future<void> setFontSize(FontSize fontSize) async {
    if (_currentFontSize != fontSize) {
      _currentFontSize = fontSize;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_fontSizeKey, fontSize.index);
      
      notifyListeners();
    }
  }
}
