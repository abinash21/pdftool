import 'package:flutter/material.dart';

class AppTheme {
  static const primaryPink = Color(0xFFFF1F5A);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryPink,
      brightness: Brightness.light,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryPink,
      brightness: Brightness.dark,
    ),
  );
}
