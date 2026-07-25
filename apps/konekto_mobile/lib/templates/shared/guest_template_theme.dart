import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta + tipografia de um dos 5 templates White Label (Aura/Bosque/
/// Elite/Pulse/Horizon) — extraído 1:1 do front-matter `colors`/`typography`
/// de cada `DESIGN.md` do export `stitch_hospitality_tech_white_label_design.zip`.
///
/// O Stitch já gera paleta no formato Material 3 (`primary`,
/// `primary-container`, `on-surface-variant` etc.), então em vez de inventar
/// uma classe de tokens nova (como o `GuestInfraTokens` dos 5 templates
/// antigos), usamos o [ColorScheme] nativo do Flutter — cada campo aqui tem
/// o equivalente direto no token do Stitch (`primaryContainer` =
/// `primary-container`, e assim por diante).
///
/// Ainda não conectado a nenhuma tela — essa é só a etapa de extração
/// (Fase 3, Task 7). As Homes/telas comuns desses templates (Task 8+) usam
/// isso como base quando forem migradas.
class GuestTemplateTheme {
  final ColorScheme colors;

  /// Fonte de destaque (títulos, hero) — ex: `Literata` no Bosque,
  /// `Playfair Display` no Elite/Horizon, `Montserrat` no Pulse.
  final String displayFontFamily;

  /// Fonte de corpo/UI — ex: `Plus Jakarta Sans`, `DM Sans`, `Inter`,
  /// `Work Sans`, conforme o template.
  final String bodyFontFamily;

  /// Escala de `border-radius` do `rounded` do Stitch (em px, antes de
  /// converter pra `rem`/logical pixels — todos os 5 templates usam a mesma
  /// escala: sm/default/md/lg/xl/full).
  final double radiusSm;
  final double radiusDefault;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;

  const GuestTemplateTheme({
    required this.colors,
    required this.displayFontFamily,
    required this.bodyFontFamily,
    required this.radiusSm,
    required this.radiusDefault,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
  });

  TextStyle display({double fontSize = 32, FontWeight fontWeight = FontWeight.w600, Color? color}) {
    return GoogleFonts.getFont(displayFontFamily, fontSize: fontSize, fontWeight: fontWeight, color: color ?? colors.onSurface);
  }

  TextStyle body({double fontSize = 16, FontWeight fontWeight = FontWeight.w400, Color? color, double? height}) {
    return GoogleFonts.getFont(bodyFontFamily, fontSize: fontSize, fontWeight: fontWeight, color: color ?? colors.onSurface, height: height);
  }

  TextStyle labelCaps({double fontSize = 12, FontWeight fontWeight = FontWeight.w600, Color? color}) {
    return GoogleFonts.getFont(
      bodyFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? colors.onSurfaceVariant,
      letterSpacing: 1.2,
    );
  }
}
