import 'package:flutter/material.dart';

class AppTheme {
  static const Color uberBlue = Color(0xFF276EF1);
  static const Color uberBlack = Color(0xFF000000);
  static const Color uberWhite = Color(0xFFFFFFFF);
  static const Color uberGrey = Color(0xFFEEEEEE);
  static const Color uberDarkGrey = Color(0xFF333333);

  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: uberBlack,
      scaffoldBackgroundColor: uberWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: uberWhite,
        foregroundColor: uberBlack,
        elevation: 0,
      ),
      colorScheme: const ColorScheme.light(
        primary: uberBlack,
        secondary: uberBlue,
        surface: uberGrey,
        onSecondary: uberWhite,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: uberBlack),
        bodyMedium: TextStyle(color: uberBlack),
        titleLarge: TextStyle(color: uberBlack),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: uberBlack,
          foregroundColor: uberWhite,
        ),
      ),
      cardTheme: CardTheme(
        color: uberWhite,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: uberBlue,
        linearTrackColor: uberGrey,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: uberWhite,
      scaffoldBackgroundColor: uberBlack,
      appBarTheme: const AppBarTheme(
        backgroundColor: uberBlack,
        foregroundColor: uberWhite,
        elevation: 0,
      ),
      colorScheme: const ColorScheme.dark(
        primary: uberWhite,
        secondary: uberBlue,
        surface: uberDarkGrey,
        onSecondary: uberWhite,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: uberWhite),
        bodyMedium: TextStyle(color: uberWhite),
        titleLarge: TextStyle(color: uberWhite),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: uberWhite,
          foregroundColor: uberBlack,
        ),
      ),
      cardTheme: CardTheme(
        color: uberDarkGrey,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: uberBlue,
        linearTrackColor: uberDarkGrey,
      ),
      useMaterial3: true,
    );
  }
}
