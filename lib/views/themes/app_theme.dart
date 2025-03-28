import 'package:flutter/material.dart';
import 'package:flutter_v2_android/config/app_config.dart';

/// 应用主题配置
class AppTheme {
  /// 获取亮色主题
  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppConfig.primaryColor,
      colorScheme: ColorScheme.light(
        primary: AppConfig.primaryColor,
        secondary: AppConfig.secondaryColor,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppConfig.primaryColor,
        ),
      ),
      cardTheme: const CardTheme(
        elevation: 2,
        shadowColor: Colors.black26,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 16.0, color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 14.0, color: Colors.black87),
        titleLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.black87),
        titleMedium: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  /// 获取暗色主题
  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppConfig.primaryColor,
      colorScheme: ColorScheme.dark(
        primary: AppConfig.primaryColor,
        secondary: AppConfig.secondaryColor,
        surface: const Color(0xFF1E1E1E),
        background: const Color(0xFF121212),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppConfig.primaryColor,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.grey[850],
        elevation: 2,
        shadowColor: Colors.black45,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 16.0, color: Colors.white70),
        bodyMedium: TextStyle(fontSize: 14.0, color: Colors.white70),
        titleLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),
        titleMedium: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
} 