import 'package:flutter/material.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Aura — plano Essential. Extraído de `elevated_hospitality_suite/DESIGN.md`
/// no export `stitch_hospitality_tech_white_label_design.zip` (confirmado
/// batendo com as cores embutidas em `aura_home/code.html`). Paleta roxa
/// Material 3, luz e "airy" — ver `## Colors` do DESIGN.md: "Aura & Horizon:
/// paletas claras, lembrando lobbies abertos".
///
/// Nota de tipografia: o DESIGN.md original define 3 papéis (display:
/// `Libre Caslon Text`, headline: `Plus Jakarta Sans`, body/labels:
/// `Work Sans`) — [GuestTemplateTheme] só modela 2 (display/body). Ao migrar
/// a Home de verdade (Task 8), usar `Plus Jakarta Sans` explicitamente pra
/// títulos de seção onde o mockup pedir, em vez de só `display`/`body`.
const auraTheme = GuestTemplateTheme(
  colors: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF4F378A),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF6750A4),
    onPrimaryContainer: Color(0xFFE0D2FF),
    secondary: Color(0xFF63597C),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE1D4FD),
    onSecondaryContainer: Color(0xFF645A7D),
    tertiary: Color(0xFF765B00),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFC9A74D),
    onTertiaryContainer: Color(0xFF503D00),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    surface: Color(0xFFFDF7FF),
    onSurface: Color(0xFF1D1B20),
    surfaceContainerHighest: Color(0xFFE6E0E9),
    outline: Color(0xFF7A7582),
    outlineVariant: Color(0xFFCBC4D2),
    inverseSurface: Color(0xFF322F35),
    onInverseSurface: Color(0xFFF5EFF7),
    inversePrimary: Color(0xFFCFBCFF),
    surfaceTint: Color(0xFF6750A4),
  ),
  displayFontFamily: 'Libre Caslon Text',
  bodyFontFamily: 'Work Sans',
  radiusSm: 4,
  radiusDefault: 8,
  radiusMd: 12,
  radiusLg: 16,
  radiusXl: 24,
);
