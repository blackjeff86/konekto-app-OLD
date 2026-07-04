import 'package:flutter/material.dart';

Color hexToColor(String hexCode) {
  // Remove o '#' se ele existir
  final String hex = hexCode.replaceAll('#', '');
  
  // Analisa o código hexadecimal
  // O + 0xFF000000 garante que a opacidade seja 100% (FF)
  return Color(int.parse(hex, radix: 16) + 0xFF000000);
}