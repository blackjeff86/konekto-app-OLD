import 'package:flutter/material.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Pulse — plano Premium/Enterprise. Extraído de `pulse_tech_luxury/DESIGN.md`
/// no export `stitch_hospitality_tech_white_label_design.zip`. Único
/// template escuro por padrão ("void" preto/grafite + dourado) — dark mode
/// não é um extra aqui, é a identidade visual em si (ver `## Colors`:
/// "Pure Black para fundos primários, Deep Graphite pra superfícies").
const pulseTheme = GuestTemplateTheme(
  colors: ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFF2CA50),
    onPrimary: Color(0xFF3C2F00),
    primaryContainer: Color(0xFFD4AF37),
    onPrimaryContainer: Color(0xFF554300),
    secondary: Color(0xFFADC6FF),
    onSecondary: Color(0xFF002E69),
    secondaryContainer: Color(0xFF4B8EFF),
    onSecondaryContainer: Color(0xFF00285C),
    tertiary: Color(0xFFBFCDFF),
    onTertiary: Color(0xFF082B72),
    tertiaryContainer: Color(0xFF97B0FF),
    onTertiaryContainer: Color(0xFF254188),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF16130B),
    onSurface: Color(0xFFEAE1D4),
    surfaceContainerHighest: Color(0xFF38342B),
    outline: Color(0xFF99907C),
    outlineVariant: Color(0xFF4D4635),
    inverseSurface: Color(0xFFEAE1D4),
    onInverseSurface: Color(0xFF343027),
    inversePrimary: Color(0xFF735C00),
    surfaceTint: Color(0xFFE9C349),
  ),
  displayFontFamily: 'Montserrat',
  bodyFontFamily: 'Inter',
  radiusSm: 4,
  radiusDefault: 8,
  radiusMd: 12,
  radiusLg: 16,
  radiusXl: 24,
);
