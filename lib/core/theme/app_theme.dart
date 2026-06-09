import 'package:flutter/material.dart';

class AppTheme {
  static const Color _lightBackground = Color(0xFFFAFAFA);
  static const Color _lightPrimary = Colors.black;
  static const Color _darkBackground = Color(0xFF121212);
  static const Color _darkPrimary = Color(0xFFFAFAFA);
  static const Color _accent = Color.fromARGB(255, 96, 154, 255);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: _lightPrimary,
      scaffoldBackgroundColor: _lightBackground,
      colorScheme: const ColorScheme.light(
        primary: _lightPrimary,
        secondary: _accent,
        surface: _lightBackground,
        onPrimary: _lightBackground,
        onSecondary: Colors.white,
        onSurface: _lightPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _lightBackground,
        foregroundColor: _lightPrimary,
        elevation: 0,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: _darkPrimary,
      scaffoldBackgroundColor: _darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimary,
        secondary: _accent,
        surface: _darkBackground,
        onPrimary: _darkBackground,
        onSecondary: Colors.white,
        onSurface: _darkPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkBackground,
        foregroundColor: _darkPrimary,
        elevation: 0,
      ),
      useMaterial3: true,
    );
  }
}
