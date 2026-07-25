import 'package:flutter/material.dart';
import 'package:konekto/l10n/app_localizations.dart';
import 'package:konekto/templates/shared/guest_home_content_params.dart';
import 'package:konekto/templates/shared/widgets/expandable_card.dart';
import 'package:konekto/templates/shared/widgets/header_icon_button.dart';
import 'package:konekto/templates/shared/widgets/image_carousel.dart';
import 'package:konekto/templates/shared/widgets/tenant_logo.dart';
import 'package:konekto/theme/guest_app_theme.dart';

/// Amara Bay: header centralizado, hero com carrossel de fotos, texto de
/// boas-vindas genérico, cartão de quarto/wifi elevado, grade 2x2 de
/// acesso rápido. Também usada pelo Konekto Clássico (sem mockup próprio do
/// Stitch) — só a `heroTag` muda entre as duas.
class AmaraBayHomeContent extends StatelessWidget {
  final GuestHomeContentParams params;
  final String heroTag;

  const AmaraBayHomeContent({super.key, required this.params, required this.heroTag});

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
              borderRadius: BorderRadius.circular(12),
              fallbackIcon: Icons.door_front_door_outlined,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(theme.hotelName, style: theme.headline()),
                  Text(
                    heroTag,
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
        const SizedBox(height: 16),
        if (theme.promoImages.isNotEmpty) ...[
          ImageCarousel(imageUrls: theme.promoImages, height: theme.carouselHeight, hotelId: params.tenantId, theme: theme),
          const SizedBox(height: 20),
        ],
        Text(l10n.homeWelcomeName(params.userName), style: theme.headline()),
        const SizedBox(height: 4),
        Text(l10n.homeCheckinMessage, style: theme.body(color: theme.mutedColor)),
        const SizedBox(height: 24),
        ExpandableCard(
          roomNumber: params.roomNumber,
          wifiNetworkName: params.wifiNetworkName,
          wifiPassword: params.wifiPassword,
          theme: theme,
        ),
        const SizedBox(height: 24),
        Text(l10n.homeOurServices, style: theme.headline(fontSize: 18)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _QuickTile(title: l10n.quickTileServices, icon: Icons.room_service_outlined, theme: theme, onTap: params.onNavigateToServices),
            _QuickTile(title: l10n.quickTileHistory, icon: Icons.history, theme: theme, onTap: () => params.onOpenMyOrders(context)),
            _QuickTile(title: l10n.quickTileMap, icon: Icons.map_outlined, theme: theme, onTap: () => params.onOpenHotelInfo(context)),
            _QuickTile(title: l10n.quickTileNotices, icon: Icons.campaign_outlined, theme: theme, onTap: () => params.onOpenNotices(context)),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final GuestAppTheme theme;
  final VoidCallback onTap;

  const _QuickTile({required this.title, required this.icon, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - theme.tokens.screenPadding * 2 - 12) / 2,
        height: 116,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardBg,
          border: Border.all(color: theme.borderColor),
          borderRadius: BorderRadius.circular(theme.tokens.cardRadius),
          boxShadow: theme.tokens.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, color: theme.accentSoft),
              child: Icon(icon, color: theme.accent, size: 22),
            ),
            const SizedBox(height: 10),
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.headline(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
