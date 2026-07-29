import 'package:flutter/material.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Horizon — plano Premium/Enterprise. Extraído de `horizon_identity/DESIGN.md`
/// no export `stitch_hospitality_tech_white_label_design.zip`. Paleta "resort
/// costeiro" (azul-oceano + laranja-pôr-do-sol).
///
/// Tratado como "em breve" no catálogo por ora (`templatesOfPlan` no backend
/// não inclui `horizon` ainda — ver `apps/sevvn_api/lib/feature-flags.ts`),
/// mas ao contrário do que se pensava antes de abrir este export, o zip TEM
/// telas reais pra ele (home, room_service, concierge_chat, onboarding,
/// splash, loyalty_rewards, experiences_directory, wallet_billing — 8 no
/// total, não só a splash). Vale confirmar com o usuário se Horizon deve
/// virar um 5º template real na Fase 3 em vez de placeholder da Task 11.
const horizonTheme = GuestTemplateTheme(
  colors: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF005D90),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF0077B6),
    onPrimaryContainer: Color(0xFFF3F7FF),
    secondary: Color(0xFF885200),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFE9D00),
    onSecondaryContainer: Color(0xFF653C00),
    tertiary: Color(0xFF5A5A4B),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF737263),
    onTertiaryContainer: Color(0xFFFBF8E5),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    surface: Color(0xFFFCF8FB),
    onSurface: Color(0xFF1B1B1D),
    surfaceContainerHighest: Color(0xFFE4E2E4),
    outline: Color(0xFF707881),
    outlineVariant: Color(0xFFBFC7D1),
    inverseSurface: Color(0xFF303032),
    onInverseSurface: Color(0xFFF3F0F2),
    inversePrimary: Color(0xFF94CCFF),
    surfaceTint: Color(0xFF006399),
  ),
  displayFontFamily: 'Playfair Display',
  bodyFontFamily: 'Plus Jakarta Sans',
  radiusSm: 4,
  radiusDefault: 8,
  radiusMd: 12,
  radiusLg: 16,
  radiusXl: 24,
);

