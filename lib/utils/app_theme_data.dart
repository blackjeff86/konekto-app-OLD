// lib/utils/app_theme_data.dart

import 'package:flutter/material.dart';

class AppThemeData {
  final Color primary;
  final Color onPrimary;
  final Color accent;
  final Color primaryText;
  final Color secondaryText;
  final Color background;
  final Color cardBackground;
  final Color buttonBackground;
  final Color borderColor;
  final Color success;
  final Color warning;
  final Color error;
  final Color onError;
  final Color shadowColor;
  final Color buttonText;
  final String splashScreenIconPath;

  // Novo grupo para variantes transparentes
  final Color cardTransparent;
  final Color cardWhite70;
  final Color cardBlack50;

  const AppThemeData({
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.primaryText,
    required this.secondaryText,
    required this.background,
    required this.cardBackground,
    required this.buttonBackground,
    required this.borderColor,
    required this.success,
    required this.warning,
    required this.error,
    required this.onError,
    required this.shadowColor,
    required this.buttonText,
    required this.splashScreenIconPath,
    required this.cardTransparent,
    required this.cardWhite70,
    required this.cardBlack50,
  });

  factory AppThemeData.fromJson(Map<String, dynamic> json) {
    Color hexToColor(String? hexCode) {
      if (hexCode == null) {
        return Colors.transparent; // padrão para valores ausentes
      }

      String formattedHex = hexCode.toUpperCase();

      if (formattedHex.startsWith('0X')) {
        formattedHex = formattedHex.substring(2);
      } else if (formattedHex.startsWith('#')) {
        formattedHex = formattedHex.substring(1);
      }

      if (formattedHex.length == 6) {
        formattedHex = 'FF$formattedHex';
      }

      final int hexValue = int.parse(formattedHex, radix: 16);
      return Color(hexValue);
    }

    final transparentVariants = json['transparentVariants'] ?? {};

    return AppThemeData(
      primary: hexToColor(json['primary']),
      onPrimary: hexToColor(json['onPrimary'] ?? '0xFFFFFFFF'),
      accent: hexToColor(json['accent']),
      primaryText: hexToColor(json['primaryText']),
      secondaryText: hexToColor(json['secondaryText']),
      background: hexToColor(json['background']),
      cardBackground: hexToColor(json['cardBackground']),
      buttonBackground: hexToColor(json['buttonBackground']),
      borderColor: hexToColor(json['borderColor']),
      success: hexToColor(json['success']),
      warning: hexToColor(json['warning']),
      error: hexToColor(json['error']),
      onError: hexToColor(json['onError'] ?? '0xFFFFFFFF'),
      shadowColor: hexToColor(json['shadowColor']),
      buttonText: hexToColor(json['buttonText']),
      splashScreenIconPath: json['splashScreenIconPath'] ?? 'assets/images/icons/default_icon.png',
      cardTransparent: hexToColor(transparentVariants['cardTransparent']),
      cardWhite70: hexToColor(transparentVariants['cardWhite70']),
      cardBlack50: hexToColor(transparentVariants['cardBlack50']),
    );
  }
}
