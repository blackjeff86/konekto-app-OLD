import 'package:flutter/material.dart';

class AppTheme {
  final AppColorPalette colors;
  final AppTypography typography;

  AppTheme({required this.colors, required this.typography});

  factory AppTheme.fromJson(Map<String, dynamic> json) {
    final colorsJson = json['colors'] as Map<String, dynamic>;
    final typographyJson = json['typography'] as Map<String, dynamic>;
    return AppTheme(
      colors: AppColorPalette.fromJson(colorsJson),
      typography: AppTypography.fromJson(typographyJson),
    );
  }
}

class AppColorPalette {
  final Color primary;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;

  AppColorPalette({
    required this.primary,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
  });

  factory AppColorPalette.fromJson(Map<String, dynamic> json) {
    return AppColorPalette(
      primary: Color(int.parse(json['primary'].substring(1), radix: 16) | 0xFF000000),
      accent: Color(int.parse(json['accent'].substring(1), radix: 16) | 0xFF000000),
      textPrimary: Color(int.parse(json['text_primary'].substring(1), radix: 16) | 0xFF000000),
      textSecondary: Color(int.parse(json['text_secondary'].substring(1), radix: 16) | 0xFF000000),
    );
  }
}

class AppTypography {
  final String fontFamily;
  final Map<String, dynamic> sizes;

  AppTypography({required this.fontFamily, required this.sizes});

  factory AppTypography.fromJson(Map<String, dynamic> json) {
    return AppTypography(
      fontFamily: json['font_family'],
      sizes: json['sizes'],
    );
  }
}