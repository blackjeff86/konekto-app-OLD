import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konekto/theme/guest_infra.dart';

/// Tema resolvido do app do hóspede — combina os tokens fixos da infra
/// escolhida ([GuestInfraTokens], nunca editável por hotel) com os dados
/// específicos do hotel (logo, nome, fotos, endereço) vindos de
/// `tenantConfig`. Passado como parâmetro de construtor explícito pelas
/// telas, no mesmo estilo em que `tenantConfig` já circula hoje — não é
/// `InheritedWidget`/Provider, pra não introduzir um mecanismo de DI novo
/// só por causa desta feature.
class GuestAppTheme {
  final GuestInfra infra;
  final GuestInfraTokens tokens;
  final String hotelName;
  final String? logoUrl;
  final List<String> promoImages;
  final double carouselHeight;
  final String? hotelAddress;

  const GuestAppTheme({
    required this.infra,
    required this.tokens,
    required this.hotelName,
    this.logoUrl,
    this.promoImages = const [],
    this.carouselHeight = 250,
    this.hotelAddress,
  });

  factory GuestAppTheme.fromTenantConfig(Map<String, dynamic> tenantConfig) {
    final infra = guestInfraFromString(tenantConfig['infra'] as String?);
    final hotelInfo = tenantConfig['hotelInfo'] as Map<String, dynamic>? ?? {};
    final promo = hotelInfo['promoImages'] as Map<String, dynamic>? ?? {};
    return GuestAppTheme(
      infra: infra,
      tokens: infra.tokens,
      hotelName: hotelInfo['name'] as String? ?? '',
      logoUrl: hotelInfo['logoUrl'] as String?,
      promoImages: List<String>.from(promo['images'] as List? ?? const []),
      carouselHeight: (promo['carouselHeight'] as num?)?.toDouble() ?? 250,
      hotelAddress: hotelInfo['address'] as String?,
    );
  }

  // --- Atalhos de cor — usados nos widgets migrados no lugar de ler
  // `tenantConfig['colorPalette'][...]` direto. `accent` substitui o antigo
  // "primaryColor" nos pontos de ação/destaque (botões, ícones ativos,
  // preços); `textColor` substitui "primaryColor" nos títulos/headings;
  // `mutedColor` substitui "bodyTextColor".
  Color get bg => tokens.bg;
  Color get cardBg => tokens.card;
  Color get textColor => tokens.text;
  Color get mutedColor => tokens.muted;
  Color get accent => tokens.accent;
  Color get accentSoft => tokens.accentSoft;
  Color get borderColor => tokens.muted.withValues(alpha: 0.25);

  TextStyle headline({double fontSize = 24, FontWeight fontWeight = FontWeight.w700, Color? color}) {
    return GoogleFonts.getFont(tokens.headlineFontFamily, fontSize: fontSize, fontWeight: fontWeight, color: color ?? tokens.text);
  }

  TextStyle body({double fontSize = 15, FontWeight fontWeight = FontWeight.w400, Color? color, double? height, FontStyle? fontStyle}) {
    return GoogleFonts.getFont(
      tokens.bodyFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? tokens.text,
      height: height,
      fontStyle: fontStyle,
    );
  }
}
