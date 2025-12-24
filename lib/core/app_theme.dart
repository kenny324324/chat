import 'package:flutter/material.dart';

class AppColors {
  static const Color skinPink = Color(0xFFFFEBEB);
  static const Color creamYellow = Color(0xFFFFEBD1);
  static const Color powderBlue = Color(0xFFDDEFFF);
  static const Color palePurple = Color(0xFFF3E8FF);
  static const Color darkGrey = Color(0xFF333333);
  
  static const Color shadowPink = Color(0xFFFFD6D6);
}

class AppTheme {
  static ThemeData getTheme(String? fontFamily) {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColors.skinPink,
      primaryColor: AppColors.darkGrey,
      
      // 移除全域水波紋動畫
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.skinPink,
        primary: AppColors.darkGrey,
        surface: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.darkGrey),
        bodyMedium: TextStyle(color: AppColors.darkGrey),
        titleLarge: TextStyle(color: AppColors.darkGrey, fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: TextStyle(color: AppColors.darkGrey.withOpacity(0.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkGrey,
          foregroundColor: Colors.white,
          elevation: 0,
          splashFactory: NoSplash.splashFactory, // 確保按鈕也被設定
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      ),
      // 針對其他按鈕類型也一併設定，確保萬無一失
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          highlightColor: Colors.transparent,
        ),
      ),
    );
  }

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: AppColors.shadowPink.withOpacity(0.25),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}
