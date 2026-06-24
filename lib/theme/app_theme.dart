import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Colors.transparent;
  // 테마 색상 변경에 영향받지 않는 고정 강조색 (흰색 모달 전용)
  static const Color fixedAccent = Color(0xFF4A6B8A);
  static const Color surface = Color(0xFF121212);
  static const Color surfaceVariant = Color(0xFF1A1A1A);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color champagneGold = Color(0xFFD4AF37);
  static const Color champagneGoldLight = Color(0xFFE8C84A);
  static const Color champagneGoldDark = Color(0xFFB8960C);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textHint = Color(0xFF535353);
  static const Color divider = Color(0xFF282828);
  static const Color iconColor = Color(0xFFCCCCCC);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0A0A0A),
      Color(0xFF0D0D0D),
      Color(0xFF0F0D12),
      Color(0xFF130D1A),
    ],
    stops: [0.0, 0.5, 0.75, 1.0],
  );

  static LinearGradient dynamicBackgroundGradient(Color primaryColor) {
    // 상단 왼쪽: 테마색 자연스럽게
    final top = Color.fromRGBO(
      (primaryColor.red * 0.55).toInt().clamp(0, 255),
      (primaryColor.green * 0.55).toInt().clamp(0, 255),
      (primaryColor.blue * 0.55).toInt().clamp(0, 255),
      1.0,
    );
    // 중간: 테마색 살짝 보이기 시작
    final mid = Color.fromRGBO(
      (primaryColor.red * 0.45).toInt().clamp(0, 255),
      (primaryColor.green * 0.45).toInt().clamp(0, 255),
      (primaryColor.blue * 0.45).toInt().clamp(0, 255),
      1.0,
    );
    // 하단: 테마색 밝게
    final bottom = Color.fromRGBO(
      (primaryColor.red * 0.80).toInt().clamp(0, 255),
      (primaryColor.green * 0.80).toInt().clamp(0, 255),
      (primaryColor.blue * 0.80).toInt().clamp(0, 255),
      1.0,
    );
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.fromRGBO(
          (primaryColor.red * 0.85).toInt().clamp(0, 255),
          (primaryColor.green * 0.85).toInt().clamp(0, 255),
          (primaryColor.blue * 0.85).toInt().clamp(0, 255),
          1.0,
        ),
        Color.fromRGBO(
          (primaryColor.red * 0.70).toInt().clamp(0, 255),
          (primaryColor.green * 0.70).toInt().clamp(0, 255),
          (primaryColor.blue * 0.70).toInt().clamp(0, 255),
          1.0,
        ),
        Color.fromRGBO(
          (primaryColor.red * 0.95).toInt().clamp(0, 255),
          (primaryColor.green * 0.95).toInt().clamp(0, 255),
          (primaryColor.blue * 0.95).toInt().clamp(0, 255),
          1.0,
        ),
      ],
      stops: const [0.0, 0.25, 1.0],
    );
  }

  static ThemeData buildTheme(Color primaryColor) {
    final primaryLight = Color.lerp(primaryColor, Colors.white, 0.2)!;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryLight,
        surface: surface,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Color.fromRGBO(
          (primaryColor.red * 0.95).toInt().clamp(0, 255),
          (primaryColor.green * 0.95).toInt().clamp(0, 255),
          (primaryColor.blue * 0.95).toInt().clamp(0, 255),
          1.0,
        ),
        selectedItemColor: Colors.white,
        unselectedItemColor: textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 0.5,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withOpacity(0.2),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withOpacity(0.1),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      iconTheme: const IconThemeData(color: iconColor),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 14),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 13),
        bodySmall: TextStyle(color: textHint, fontSize: 12),
      ),
    );
  }

  static ThemeData get darkTheme => buildTheme(champagneGold);
}