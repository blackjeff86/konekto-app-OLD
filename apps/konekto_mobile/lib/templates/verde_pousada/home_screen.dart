import 'package:flutter/material.dart';
import 'package:konekto/l10n/app_localizations.dart';
import 'package:konekto/templates/shared/guest_home_content_params.dart';
import 'package:konekto/templates/shared/widgets/expandable_card.dart';
import 'package:konekto/templates/shared/widgets/notification_count_badge.dart';
import 'package:konekto/templates/shared/widgets/tenant_logo.dart';
import 'package:konekto/theme/guest_app_theme.dart';

/// Verde Pousada: editorial, sem hero/carrossel — header simples, saudação
/// com o nome do hóspede em destaque, acordeão fino de wifi/quarto, serviços
/// em lista vertical (não grade). Também usada pelo Konekto Noturno (sem
/// mockup próprio do Stitch) — layout idêntico, só o tema muda.
class VerdePousadaHomeContent extends StatelessWidget {
  final GuestHomeContentParams params;

  const VerdePousadaHomeContent({super.key, required this.params});

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
              size: 40,
              borderRadius: BorderRadius.circular(theme.tokens.iconTileRadius),
              fallbackIcon: Icons.layers_outlined,
              filled: false,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(theme.hotelName, style: theme.headline(fontSize: 17))),
            GestureDetector(
              onTap: () => params.onOpenNotices(context),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.notifications_outlined, color: theme.mutedColor),
                  if (params.notificationCount > 0)
                    Positioned(top: -2, right: -2, child: NotificationCountBadge(count: params.notificationCount, theme: theme)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Icon(Icons.person_outline, color: theme.mutedColor),
          ],
        ),
        const SizedBox(height: 40),
        Text(
          l10n.homeWelcomeBack,
          style: theme.body(fontSize: 11, fontWeight: FontWeight.w600, color: theme.mutedColor).copyWith(letterSpacing: 1.1),
        ),
        const SizedBox(height: 6),
        Text(params.userName, style: theme.headline(fontSize: 28)),
        const SizedBox(height: 6),
        Text(l10n.homeCheckinRoom(params.roomNumber), style: theme.body(color: theme.mutedColor)),
        const SizedBox(height: 36),
        ExpandableCard(
          title: l10n.roomWifiDetailsShort,
          icon: Icons.home_outlined,
          flat: true,
          roomNumber: params.roomNumber,
          wifiNetworkName: params.wifiNetworkName,
          wifiPassword: params.wifiPassword,
          theme: theme,
        ),
        const SizedBox(height: 32),
        Text(l10n.homeOurServices, style: theme.headline(fontSize: 18)),
        const SizedBox(height: 8),
        _VerdeServiceRow(title: l10n.quickTileServices, icon: Icons.room_service_outlined, theme: theme, onTap: params.onNavigateToServices),
        _VerdeServiceRow(title: l10n.quickTileHistory, icon: Icons.history, theme: theme, onTap: () => params.onOpenMyOrders(context)),
        _VerdeServiceRow(title: l10n.quickTileMap, icon: Icons.map_outlined, theme: theme, onTap: () => params.onOpenHotelInfo(context)),
        _VerdeServiceRow(
          title: l10n.quickTileNotices,
          icon: Icons.campaign_outlined,
          theme: theme,
          onTap: () => params.onOpenNotices(context),
          isLast: true,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _VerdeServiceRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final GuestAppTheme theme;
  final VoidCallback onTap;
  final bool isLast;

  const _VerdeServiceRow({required this.title, required this.icon, required this.theme, required this.onTap, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: theme.borderColor))),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.accent),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: theme.body(fontWeight: FontWeight.w600))),
            Icon(Icons.chevron_right, color: theme.mutedColor),
          ],
        ),
      ),
    );
  }
}
