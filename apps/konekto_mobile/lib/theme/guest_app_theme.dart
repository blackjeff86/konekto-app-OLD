import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens visuais fixos das telas compartilhadas do app do hóspede
/// (Serviços, Reservas, Perfil, Avisos, Meus Pedidos, Info do Hotel, Conta
/// da estadia etc.) — nunca editáveis por hotel, nunca variam por template.
///
/// Essas telas são funcionalidade, não identidade visual de marca: existem
/// por conta própria e continuam iguais não importa qual dos 5 templates
/// (Aura/Bosque/Elite/Pulse/Horizon) o hotel escolheu pra Home — só a Home
/// troca de cara por template (ver `lib/templates/<nome>/home_screen.dart`).
/// Antes desta decisão, essas telas trocavam de visual junto com 5
/// infraestruturas antigas (Amara Bay/Verde Pousada/Casa Marechal/Konekto
/// Clássico/Konekto Noturno, arquivadas em `legacy-templates/`) — os
/// valores abaixo são os da antiga "Verde Pousada" (o fallback padrão de
/// sempre), agora fixos em vez de um entre cinco.
class GuestSharedTokens {
  final Color bg;
  final Color card;
  final Color text;
  final Color muted;
  final Color accent;
  final Color accentSoft;
  final Color navInactive;
  final Color bottomNavBg;
  final Color bottomNavBorder;
  final String headlineFontFamily;
  final String bodyFontFamily;
  final double cardRadius;
  final double heroRadius;
  final double pillRadius;
  final double iconTileRadius;
  final double screenPadding;
  final List<BoxShadow> cardShadow;

  const GuestSharedTokens({
    required this.bg,
    required this.card,
    required this.text,
    required this.muted,
    required this.accent,
    required this.accentSoft,
    required this.navInactive,
    required this.bottomNavBg,
    required this.bottomNavBorder,
    required this.headlineFontFamily,
    required this.bodyFontFamily,
    required this.cardRadius,
    required this.heroRadius,
    required this.pillRadius,
    required this.iconTileRadius,
    required this.screenPadding,
    required this.cardShadow,
  });
}

const _cardShadow = [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))];

const guestSharedTokens = GuestSharedTokens(
  bg: Color(0xFFF9FAF2),
  card: Colors.white,
  text: Color(0xFF191C18),
  muted: Color(0xFF444840),
  accent: Color(0xFF45553C),
  accentSoft: Color(0xFFDCE5D3),
  navInactive: Color(0xFF757870),
  bottomNavBg: Color(0xF0F9FAF2),
  bottomNavBorder: Color(0x0F191C18),
  headlineFontFamily: 'DM Sans',
  bodyFontFamily: 'Hanken Grotesk',
  cardRadius: 15,
  heroRadius: 21,
  pillRadius: 999,
  iconTileRadius: 9.5,
  screenPadding: 22,
  cardShadow: _cardShadow,
);

/// Item da navegação inferior — conteúdo fixo, igual em qualquer template
/// (só o estilo visual da barra usa [GuestSharedTokens], não a lista de
/// abas). O rótulo vem de `AppLocalizations` na hora de renderizar (ver
/// `navItemLabel` em `tenant_home_page.dart`), não daqui.
class GuestNavItem {
  final IconData icon;
  final String route;
  const GuestNavItem(this.icon, this.route);
}

const kGuestNavItems = [
  GuestNavItem(Icons.home_outlined, 'home'),
  GuestNavItem(Icons.grid_view_outlined, 'services'),
  GuestNavItem(Icons.event_note_outlined, 'bookings'),
  GuestNavItem(Icons.person_outline, 'profile'),
];

/// Tema resolvido das telas compartilhadas do app do hóspede — combina os
/// tokens fixos ([guestSharedTokens]) com os dados específicos do hotel
/// (logo, nome, fotos, endereço) vindos de `tenantConfig`. Passado como
/// parâmetro de construtor explícito pelas telas, no mesmo estilo em que
/// `tenantConfig` já circula hoje — não é `InheritedWidget`/Provider, pra
/// não introduzir um mecanismo de DI novo só por causa disso.
class GuestAppTheme {
  final GuestSharedTokens tokens;
  final String hotelName;
  final String? logoUrl;
  final List<String> promoImages;
  final double carouselHeight;
  final String? hotelAddress;

  const GuestAppTheme({
    required this.tokens,
    required this.hotelName,
    this.logoUrl,
    this.promoImages = const [],
    this.carouselHeight = 250,
    this.hotelAddress,
  });

  factory GuestAppTheme.fromTenantConfig(Map<String, dynamic> tenantConfig) {
    final hotelInfo = tenantConfig['hotelInfo'] as Map<String, dynamic>? ?? {};
    final promo = hotelInfo['promoImages'] as Map<String, dynamic>? ?? {};
    return GuestAppTheme(
      tokens: guestSharedTokens,
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
