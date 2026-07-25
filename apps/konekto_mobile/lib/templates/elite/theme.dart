import 'package:flutter/material.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Elite — plano Premium/Enterprise. Extraído de
/// `silent_luxury_experience/DESIGN.md` no export
/// `stitch_hospitality_tech_white_label_design.zip` (confirmado batendo com
/// as cores/fonte embutidas em `lite_home/code.html` — o zip nomeia as
/// pastas de tela como `lite_*`, mas o nome oficial do template, aqui e no
/// backend [feature-flags.ts], é `elite`). Paleta "Quiet Luxury":
/// preto/dourado sóbrio sobre creme, cantos quase retos (a exceção entre os
/// 5 — os outros 4 usam a escala 4/8/12/16/24, este usa 2/4/6/8/12).
const eliteTheme = GuestTemplateTheme(
  colors: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF000000),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF1C1B1B),
    onPrimaryContainer: Color(0xFF858383),
    secondary: Color(0xFF775A19),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFED488),
    onSecondaryContainer: Color(0xFF785A1A),
    tertiary: Color(0xFF000000),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF1B1C19),
    onTertiaryContainer: Color(0xFF848480),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    surface: Color(0xFFFEF9EE),
    onSurface: Color(0xFF1D1C15),
    surfaceContainerHighest: Color(0xFFE7E2D8),
    outline: Color(0xFF747878),
    outlineVariant: Color(0xFFC4C7C7),
    inverseSurface: Color(0xFF32302A),
    onInverseSurface: Color(0xFFF5F0E6),
    inversePrimary: Color(0xFFC8C6C5),
    surfaceTint: Color(0xFF5F5E5E),
  ),
  displayFontFamily: 'Playfair Display',
  bodyFontFamily: 'DM Sans',
  radiusSm: 2,
  radiusDefault: 4,
  radiusMd: 6,
  radiusLg: 8,
  radiusXl: 12,
);
