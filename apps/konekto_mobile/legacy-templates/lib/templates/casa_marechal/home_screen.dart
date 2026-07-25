import 'package:flutter/material.dart';
import 'package:konekto/l10n/app_localizations.dart';
import 'package:konekto/templates/shared/guest_home_content_params.dart';
import 'package:konekto/templates/shared/widgets/expandable_card.dart';
import 'package:konekto/templates/shared/widgets/header_icon_button.dart';
import 'package:konekto/templates/shared/widgets/tenant_logo.dart';
import 'package:konekto/theme/guest_app_theme.dart';
import 'package:konekto/widgets/tenant_image.dart';

/// Casa Marechal: heranca classica — badge de quarto centralizado, saudacao
/// serifada centralizada com friso dourado, grade de acessos com bordas
/// finas (sem sombra/preenchimento, ao contrario da Amara Bay), carrossel
/// de fotos em cartoes emoldurados ("Destaques da Casa" — reaproveita as
/// mesmas promoImages configuradas pelo hotel, sem inventar um catalogo de
/// "experiencias" que o backend nao modela) e um banner de destaque solido
/// levando pra Servicos (no lugar da recomendacao fixa do concierge do
/// mockup, que nao tem dado real por tras).
class CasaMarechalHomeContent extends StatelessWidget {
  final GuestHomeContentParams params;

  const CasaMarechalHomeContent({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = params.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            TenantLogo(
              theme: theme,
              tenantId: params.tenantId,
              size: 44,
              borderRadius: BorderRadius.circular(theme.tokens.iconTileRadius),
              fallbackIcon: Icons.villa_outlined,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(theme.hotelName, style: theme.headline()),
                  Text(
                    l10n.casaMarechalTag,
                    style: theme.body(fontSize: 10, fontWeight: FontWeight.w600, color: theme.mutedColor).copyWith(letterSpacing: 2),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: HeaderIconButton(
                theme: theme,
                icon: Icons.notifications_outlined,
                onTap: () => params.onOpenNotices(context),
                badgeCount: params.notificationCount,
              ),
            ),
            HeaderIconButton(theme: theme, icon: Icons.person_outline, onTap: () {}),
          ],
        ),
        const SizedBox(height: 28),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(color: theme.accent, borderRadius: BorderRadius.circular(theme.tokens.pillRadius)),
                child: Text(
                  l10n.roomNumberLabel(params.roomNumber).toUpperCase(),
                  style: theme.body(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white).copyWith(letterSpacing: 1.5),
                ),
              ),
              const SizedBox(height: 18),
              Text(l10n.homeWelcomeName(params.userName), textAlign: TextAlign.center, style: theme.headline(fontSize: 26)),
              const SizedBox(height: 16),
              Container(width: 64, height: 1, color: theme.accent.withValues(alpha: 0.35)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _CasaQuickAction(title: l10n.quickTileServices, icon: Icons.room_service_outlined, theme: theme, onTap: params.onNavigateToServices),
            _CasaQuickAction(title: l10n.quickTileHistory, icon: Icons.history, theme: theme, onTap: () => params.onOpenMyOrders(context)),
            _CasaQuickAction(title: l10n.quickTileMap, icon: Icons.map_outlined, theme: theme, onTap: () => params.onOpenHotelInfo(context)),
            _CasaQuickAction(title: l10n.quickTileNotices, icon: Icons.campaign_outlined, theme: theme, onTap: () => params.onOpenNotices(context)),
          ],
        ),
        const SizedBox(height: 28),
        ExpandableCard(
          roomNumber: params.roomNumber,
          wifiNetworkName: params.wifiNetworkName,
          wifiPassword: params.wifiPassword,
          theme: theme,
          icon: Icons.villa_outlined,
        ),
        if (theme.promoImages.isNotEmpty) ...[
          const SizedBox(height: 32),
          Text(l10n.casaFeaturedTitle, style: theme.headline(fontSize: 19)),
          const SizedBox(height: 4),
          Text(l10n.casaFeaturedSubtitle, style: theme.body(fontSize: 12.5, color: theme.mutedColor, fontStyle: FontStyle.italic)),
          const SizedBox(height: 18),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: theme.promoImages.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) => _CasaExperienceCard(
                imageUrl: theme.promoImages[index],
                hotelId: params.tenantId,
                theme: theme,
                badge: index == 0 ? l10n.casaMarechalTag : null,
              ),
            ),
          ),
        ],
        const SizedBox(height: 32),
        _CasaConciergeBanner(
          theme: theme,
          onTap: params.onNavigateToServices,
          title: l10n.casaConciergeTitle,
          subtitle: l10n.casaConciergeSubtitle,
          cta: l10n.casaConciergeCta,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

/// Acesso rapido da Casa Marechal: contorno fino sem preenchimento/sombra
/// (ao contrario do `_QuickTile` da Amara Bay), rotulo em caixa alta —
/// reflete o `borderRadius` quase reto e a paleta esmeralda/dourada do
/// design system do Stitch.
class _CasaQuickAction extends StatelessWidget {
  final String title;
  final IconData icon;
  final GuestAppTheme theme;
  final VoidCallback onTap;

  const _CasaQuickAction({required this.title, required this.icon, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - theme.tokens.screenPadding * 2 - 12) / 2,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.accent.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(theme.tokens.iconTileRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.accent, size: 26),
            const SizedBox(height: 10),
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.body(fontSize: 10.5, fontWeight: FontWeight.w700, color: theme.textColor).copyWith(letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cartao emoldurado do carrossel "Destaques da Casa" — reaproveita as
/// mesmas `promoImages` que a Amara Bay usa no hero cheio de tela, so que em
/// cartoes menores com moldura fina (ao inves de um carrossel full-bleed),
/// pra bater com a estetica de galeria do mockup Casa Marechal do Stitch.
class _CasaExperienceCard extends StatelessWidget {
  final String imageUrl;
  final String hotelId;
  final GuestAppTheme theme;
  final String? badge;

  const _CasaExperienceCard({required this.imageUrl, required this.hotelId, required this.theme, this.badge});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(border: Border.all(color: theme.accent.withValues(alpha: 0.25))),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: TenantImage(imageUrl: imageUrl, hotelId: hotelId, fit: BoxFit.cover),
            ),
            if (badge != null)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: theme.accent,
                  child: Text(
                    badge!,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Banner solido levando pra Servicos — substitui a "recomendacao fixa do
/// concierge" do mockup (evento datado sem contrapartida real no backend)
/// por uma chamada honesta pra funcionalidade que de fato existe.
class _CasaConciergeBanner extends StatelessWidget {
  final GuestAppTheme theme;
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final String cta;

  const _CasaConciergeBanner({
    required this.theme,
    required this.onTap,
    required this.title,
    required this.subtitle,
    required this.cta,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: theme.accent, borderRadius: BorderRadius.circular(theme.tokens.cardRadius)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.headline(fontSize: 20, color: Colors.white)),
            const SizedBox(height: 10),
            Text(subtitle, style: theme.body(fontSize: 13, color: Colors.white.withValues(alpha: 0.85), height: 1.4)),
            const SizedBox(height: 18),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cta.toUpperCase(),
                  style: theme.body(fontSize: 12, fontWeight: FontWeight.w700, color: theme.accentSoft).copyWith(letterSpacing: 1.2),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward, size: 16, color: theme.accentSoft),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
