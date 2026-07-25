import 'package:flutter/material.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Bosque — plano Essential. Extraído de `bosque/DESIGN.md` no export
/// `stitch_hospitality_tech_white_label_design.zip`. Paleta verde-floresta
/// ("Biophilic Design") — ver `## Colors`: "Bosque: tons terrosos, ambiente
/// de wellness/natureza".
const bosqueTheme = GuestTemplateTheme(
  colors: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF173124),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF2D4739),
    onPrimaryContainer: Color(0xFF98B5A3),
    secondary: Color(0xFF77574B),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFFD4C4),
    onSecondaryContainer: Color(0xFF7A594D),
    tertiary: Color(0xFF422401),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF5C3A13),
    onTertiaryContainer: Color(0xFFD5A474),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    surface: Color(0xFFFBF9F5),
    onSurface: Color(0xFF1B1C1A),
    surfaceContainerHighest: Color(0xFFE4E2DE),
    outline: Color(0xFF727973),
    outlineVariant: Color(0xFFC2C8C2),
    inverseSurface: Color(0xFF30312E),
    onInverseSurface: Color(0xFFF2F0ED),
    inversePrimary: Color(0xFFB0CDBB),
    surfaceTint: Color(0xFF496455),
  ),
  displayFontFamily: 'Literata',
  bodyFontFamily: 'Plus Jakarta Sans',
  radiusSm: 4,
  radiusDefault: 8,
  radiusMd: 12,
  radiusLg: 16,
  radiusXl: 24,
);
