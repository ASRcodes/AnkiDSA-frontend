import 'package:flutter/material.dart';

class AppColors {
  static const paper = Color(0xFFF7F6F0),
      surface = Color(0xFFFFFEFA),
      green = Color(0xFF234F40),
      dark = Color(0xFF213E35),
      muted = Color(0xFF6D786F),
      line = Color(0xFFE0E2D8),
      sage = Color(0xFFE5EBDE),
      clay = Color(0xFFAE6243);
}

TextStyle editorial(double size, {Color color = AppColors.dark}) => TextStyle(
    fontFamily: 'Lora',
    fontSize: size,
    height: 1.2,
    letterSpacing: -size * 0.025,
    color: color);
ThemeData appTheme() {
  final scheme = ColorScheme.fromSeed(
          seedColor: AppColors.green, surface: AppColors.surface)
      .copyWith(
          primary: AppColors.green,
          onPrimary: Colors.white,
          secondary: AppColors.clay,
          onSurface: AppColors.dark,
          outlineVariant: AppColors.line);
  return ThemeData(
      useMaterial3: true,
      fontFamily: 'DMSans',
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.paper,
      textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'DMSans',
          bodyColor: AppColors.dark,
          displayColor: AppColors.dark),
      appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.paper,
          surfaceTintColor: Colors.transparent,
          elevation: 0),
      dividerTheme: const DividerThemeData(color: AppColors.line, space: 1),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.green, width: 1.5)),
          labelStyle: const TextStyle(color: AppColors.muted, fontSize: 14)),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)))),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              side: const BorderSide(color: AppColors.line),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)))),
      snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.dark,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
}
