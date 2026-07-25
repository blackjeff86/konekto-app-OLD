import 'package:flutter/material.dart';

/// As cinco infraestruturas visuais selecionáveis por hotel — cada uma é um
/// sistema fixo (cores/tipografia/raios/nav), não editável por hotel. O que
/// muda por hotel é só [GuestAppTheme] (logo, nome, fotos, endereço).
///
/// Amara Bay, Verde Pousada e Casa Marechal vêm dos sistemas de design
/// gerados no Stitch (ver DESIGN.md de cada um: Amara Bay Resort, Serene
/// Organic Editorial [Verde Trilha] e Casa Marechal Heritage System) — só
/// cor/tipografia/raio, a estrutura das telas continua igual. Konekto
/// Clássico e Konekto Noturno não vêm do Stitch — recriam a identidade
/// visual da marca de antes do rebrand rosa (tinta/dourado de
/// `lib/theme/konekto_brand.dart` e do `colorPalette` legado que ainda
/// existia em hotéis antigos), já que o visual original das duas infras
/// que existiam antes do Stitch (Amara Bay/Verde Pousada com esses nomes)
/// nunca chegou a ser versionado em nenhum lugar do código.
enum GuestInfra { amaraBay, verdePousada, casaMarechal, konektoClassico, konektoNoturno }

/// Tokens fixos de uma infra — nunca lidos de `tenantConfig`, sempre vêm
/// daqui. Ver READMEs de design de cada infra pra origem exata dos valores.
class GuestInfraTokens {
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

  const GuestInfraTokens({
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

/// "Sophisticated Tropical Warmth" — terracota/areia/cream, editorial de
/// resort de praia boutique. Bodoni Moda (títulos) + Plus Jakarta Sans (corpo).
const amaraBayTokens = GuestInfraTokens(
  bg: Color(0xFFFAF9F6),
  card: Colors.white,
  text: Color(0xFF1A1C1A),
  muted: Color(0xFF56423C),
  accent: Color(0xFF9D3D1C),
  accentSoft: Color(0xFFEFDEC0),
  navInactive: Color(0xFF8A726B),
  bottomNavBg: Color(0xF0FAF9F6),
  bottomNavBorder: Color(0x0F1A1C1A),
  headlineFontFamily: 'Bodoni Moda',
  bodyFontFamily: 'Plus Jakarta Sans',
  cardRadius: 15,
  heroRadius: 21,
  pillRadius: 999,
  iconTileRadius: 9.5,
  screenPadding: 22,
  cardShadow: _cardShadow,
);

/// "Serene Editorial" — sage/moss/parchment, pousada de ecoturismo sem
/// pressa. DM Sans (títulos) + Hanken Grotesk (corpo), evita preto puro.
const verdePousadaTokens = GuestInfraTokens(
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

/// "Timeless Heritage" — esmeralda/dourado-envelhecido/cream/bordô, hotel
/// boutique de herança num casarão histórico. Bodoni Moda (títulos) +
/// Source Sans 3 (corpo). Cantos deliberadamente mais retos/estruturados
/// que os outros dois — "conservative and structural", nunca full-pill.
const casaMarechalTokens = GuestInfraTokens(
  bg: Color(0xFFFBF9F5),
  card: Colors.white,
  text: Color(0xFF1B1C1A),
  muted: Color(0xFF404944),
  accent: Color(0xFF064E3B),
  accentSoft: Color(0xFFF7EED1),
  navInactive: Color(0xFF707974),
  bottomNavBg: Color(0xF0FBF9F5),
  bottomNavBorder: Color(0x0F1B1C1A),
  headlineFontFamily: 'Bodoni Moda',
  bodyFontFamily: 'Source Sans 3',
  cardRadius: 10,
  heroRadius: 14,
  pillRadius: 10,
  iconTileRadius: 6,
  screenPadding: 22,
  cardShadow: _cardShadow,
);

/// "Konekto Clássico" — cream/tinta/dourado quente, a identidade da marca
/// de antes do rebrand rosa (paleta idêntica à de `KonektoBrand` em
/// lib/theme/konekto_brand.dart). Playfair Display (títulos) + Inter
/// (corpo) — a mesma dupla tipográfica já usada nas telas de marca.
const konektoClassicoTokens = GuestInfraTokens(
  bg: Color(0xFFF5F3EE),
  card: Colors.white,
  text: Color(0xFF0B0D12),
  muted: Color(0xFF6B6456),
  accent: Color(0xFFB8935F),
  accentSoft: Color(0xFFE4CFA6),
  navInactive: Color(0xFF9099A6),
  bottomNavBg: Color(0xF0F5F3EE),
  bottomNavBorder: Color(0x0F0B0D12),
  headlineFontFamily: 'Playfair Display',
  bodyFontFamily: 'Inter',
  cardRadius: 14,
  heroRadius: 20,
  pillRadius: 999,
  iconTileRadius: 10,
  screenPadding: 22,
  cardShadow: _cardShadow,
);

/// "Konekto Noturno" — a única infra de fundo escuro (as outras quatro são
/// claras): azul-marinho profundo + dourado, a paleta que ainda estava
/// configurada em hotéis antigos (`colorPalette.primary`/`secondary` do
/// tenantConfig legado) antes da infra `amara_bay`/`verde_pousada`
/// existir. Cormorant Garamond (títulos, serifa fina e alta) + Inter
/// (corpo).
const konektoNoturnoTokens = GuestInfraTokens(
  bg: Color(0xFF0D1B2A),
  card: Color(0xFF16283D),
  text: Color(0xFFF5F3EE),
  muted: Color(0xFF9AA5B1),
  accent: Color(0xFFC9A227),
  accentSoft: Color(0xFF3A331A),
  navInactive: Color(0xFF6B7280),
  bottomNavBg: Color(0xF00D1B2A),
  bottomNavBorder: Color(0x1FFFFFFF),
  headlineFontFamily: 'Cormorant Garamond',
  bodyFontFamily: 'Inter',
  cardRadius: 10,
  heroRadius: 14,
  pillRadius: 10,
  iconTileRadius: 6,
  screenPadding: 22,
  cardShadow: _cardShadow,
);

extension GuestInfraTokenResolver on GuestInfra {
  GuestInfraTokens get tokens => switch (this) {
        GuestInfra.amaraBay => amaraBayTokens,
        GuestInfra.verdePousada => verdePousadaTokens,
        GuestInfra.casaMarechal => casaMarechalTokens,
        GuestInfra.konektoClassico => konektoClassicoTokens,
        GuestInfra.konektoNoturno => konektoNoturnoTokens,
      };
}

/// Hotéis antigos sem `infra` setado (dado antes desta feature existir)
/// caem no fallback Verde Pousada — nunca lança erro por chave ausente ou
/// valor desconhecido.
GuestInfra guestInfraFromString(String? raw) => switch (raw) {
      'amara_bay' => GuestInfra.amaraBay,
      'verde_pousada' => GuestInfra.verdePousada,
      'casa_marechal' => GuestInfra.casaMarechal,
      'konekto_classico' => GuestInfra.konektoClassico,
      'konekto_noturno' => GuestInfra.konektoNoturno,
      _ => GuestInfra.verdePousada,
    };

/// Item da navegação inferior — conteúdo fixo, igual nas três infras (só o
/// estilo visual da barra muda, não a lista de abas). O rótulo vem de
/// `AppLocalizations` na hora de renderizar (ver `navItemLabel` em
/// `tenant_home_page.dart`), não daqui — não dá pra ter uma `const` já
/// traduzida.
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
