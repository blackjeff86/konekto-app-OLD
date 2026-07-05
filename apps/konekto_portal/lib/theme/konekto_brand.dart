import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identidade visual do portal — duplicado (não compartilhado) a partir de
/// apps/konekto_mobile/lib/theme/konekto_brand.dart. Sem extração pra um
/// package comum ainda (deferido no plano original); mantenha os dois em
/// sincronia manualmente se os tokens de marca mudarem.
///
/// Paleta alinhada com apps/konekto_site (tema escuro é a identidade
/// oficial da marca, não só da landing page).
class KonektoBrand {
  KonektoBrand._();

  static const Color ink = Color(0xFF0B0D12);
  static const Color surface = Color(0xFF12151C);
  static const Color surfaceAlt = Color(0xFF171B23);
  static const Color border = Color(0x17FFFFFF);
  static const Color borderStrong = Color(0x29FFFFFF);
  static const Color gold = Color(0xFFB8935F);
  static const Color goldLight = Color(0xFFE4CFA6);
  static const Color cream = Color(0xFFF5F3EE);
  static const Color slate = Color(0xFF9099A6);
  static const Color slateSoft = Color(0xFF6B7280);

  static TextStyle display({
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w700,
    Color color = cream,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static TextStyle eyebrow({Color color = goldLight, double fontSize = 12}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: color,
      letterSpacing: 2.2,
    );
  }

  static TextStyle body({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w400,
    Color color = slate,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }
}

/// Marca geométrica da Konekto (dois quadrados arredondados sobrepostos) —
/// mesma marca usada em apps/konekto_site/assets/logo/icon-mark-*.svg.
class KonektoMark extends StatelessWidget {
  final double size;
  final Color outlineColor;
  final Color fillColor;

  const KonektoMark({
    super.key,
    this.size = 32,
    this.outlineColor = KonektoBrand.goldLight,
    this.fillColor = KonektoBrand.gold,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(
            left: size * 0.12,
            top: size * 0.12,
            width: size * 0.56,
            height: size * 0.56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: outlineColor, width: size * 0.06),
                borderRadius: BorderRadius.circular(size * 0.16),
              ),
            ),
          ),
          Positioned(
            left: size * 0.52,
            top: size * 0.52,
            width: size * 0.34,
            height: size * 0.34,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(size * 0.10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

