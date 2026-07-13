import 'package:flutter/material.dart';

/// アプリのデザインや配色を定義するファイル
/// ライトモードとダークモードのテーマデータを管理しており、引数として受け取ったサイズ倍率（textScale）を文字サイズやボタンに掛け合わせることでアプリ全体を一括拡大
class AppTheme {
  static const Color primary = Color(0xFF2D6A4F);
  static const Color primaryLight = Color(0xFF52B788);
  static const Color accent = Color(0xFFD4A017);
  static const Color surface = Color(0xFFF8F5F0);
  static const Color onSurface = Color(0xFF1C1C1E);
  static const Color muted = Color(0xFF8A8A8E);
  static const Color danger = Color(0xFFD62828);
  static const Color trackColor = Color(0xFFE07B39);

  // ── MAP FAB COLORS ────────────────────────────────────────────────
  static const Color pinAddButton = Color(0xFF2D6A4F);      // ピン追加ボタン
  static const Color trackRecordButton = Color(0xFFD62828);  // 移動記録開始（赤）
  static final Color trackStopButton = Colors.red[700]!;    // 移動記録停止（濃い赤）
  static const Color locationFollowButton = Colors.blue;    // 現在地追従中（青）
  static const Color locationUnfollowButton = Colors.white; // 現在地未追従（白）
  static const Color zoomButton = Colors.white;             // ズームボタン（白）

  static ThemeData getLight(double textScale) {
    return ThemeData(
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
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18 * textScale,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
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
          borderSide: BorderSide(color: primary.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryLight.withValues(alpha: 0.15),
        selectedColor: primary,
        labelStyle: TextStyle(fontSize: 12 * textScale),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(64 * textScale, 40 * textScale),
          padding: EdgeInsets.symmetric(
            horizontal: 16 * textScale,
            vertical: 8 * textScale,
          ),
          textStyle: TextStyle(fontSize: 14 * textScale),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(fontSize: 14 * textScale),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: 16 * textScale),
        bodyMedium: TextStyle(fontSize: 14 * textScale),
        labelLarge: TextStyle(fontSize: 14 * textScale),
      ),
    );
  }

  static ThemeData getDark(double textScale) {
    return ThemeData(
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
      appBarTheme: AppBarTheme(
        titleTextStyle: TextStyle(
          fontSize: 18 * textScale,
        ),
      ),
      chipTheme: ChipThemeData(
        labelStyle: TextStyle(fontSize: 12 * textScale),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(64 * textScale, 40 * textScale),
          textStyle: TextStyle(fontSize: 14 * textScale),
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: 16 * textScale),
        bodyMedium: TextStyle(fontSize: 14 * textScale),
        labelLarge: TextStyle(fontSize: 14 * textScale),
      ),
    );
  }
}