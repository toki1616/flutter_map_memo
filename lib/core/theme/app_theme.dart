import 'package:flutter/material.dart';

/// アプリのデザインや配色を定義するファイル
/// ライトモードとダークモードのテーマデータを管理しており、カードの形状や入力フォームの枠線、ボタンの色などをMaterial3のデザイン規約に基づいて一括設定
class AppTheme {
  static const Color primary = Color(0xFF2D6A4F);
  static const Color primaryLight = Color(0xFF52B788);
  static const Color accent = Color(0xFFD4A017);
  static const Color surface = Color(0xFFF8F5F0);
  static const Color onSurface = Color(0xFF1C1C1E);
  static const Color muted = Color(0xFF8A8A8E);
  static const Color danger = Color(0xFFD62828);
  static const Color trackColor = Color(0xFFE07B39);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: primary,
          onPrimary: Colors.white,
          secondary: accent,
          onSecondary: Colors.white,
          error: danger,
          onError: Colors.white,
          surface: surface,
          onSurface: onSurface,
        ),
        scaffoldBackgroundColor: surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
        // ✅ 修正: CardTheme → CardThemeData
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primary.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: primaryLight.withOpacity(0.15),
          selectedColor: primary,
          labelStyle: const TextStyle(fontSize: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: primaryLight,
          onPrimary: Colors.black,
          secondary: accent,
          onSecondary: Colors.black,
          error: danger,
          onError: Colors.white,
          surface: Color(0xFF1C1C1E),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF1C1C1E),
      );
}
