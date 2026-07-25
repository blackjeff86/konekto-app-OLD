import 'package:flutter/material.dart';
import 'package:konekto/l10n/app_localizations.dart';
import 'package:konekto/templates/shared/guest_template_content_params.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Bosque: cartão de estadia com raio "orgânico" assimétrico (o traço
/// visual mais característico do mockup), grade 2x2 de acesso rápido com
/// ícones circulares brancos, e uma citação atmosférica no rodapé. Adaptado
/// de `bosque_home/code.html`. Igual à Aura, os cartões de "Cabin Temp"/
/// "Check-out" do mockup viram só o quarto + wifi (dado que o app realmente
/// tem); a citação final ("In every walk with nature...") foi mantida
/// porque é decoração pura, não dado — não compromete nada trocar de
/// hóspede pra hóspede.
class BosqueHomeContent extends StatelessWidget {
  final GuestTemplateContentParams params;

  const BosqueHomeContent({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = params.theme;
    final colors = theme.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            CircleAvatar(radius: 20, backgroundColor: colors.secondaryContainer, child: Icon(Icons.person, color: colors.onSecondaryContainer)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.homeWelcomeName(params.userName),
                style: theme.display(fontSize: 22, fontWeight: FontWeight.w600, color: colors.primary),
              ),
            ),
            _RoundBell(theme: theme, count: params.notificationCount, onTap: () => params.onOpenNotices(context)),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(12),
            ),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.roomNumberLabel(params.roomNumber), style: theme.display(fontSize: 22, fontWeight: FontWeight.w600, color: colors.primary)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.wifi, color: colors.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.wifiNetworkLabel(params.wifiNetworkName), style: theme.body(fontSize: 12, color: colors.onSurfaceVariant)),
                        Text(l10n.wifiPasswordLabel(params.wifiPassword), style: theme.body(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(l10n.homeOurServices, style: theme.display(fontSize: 18, fontWeight: FontWeight.w600, color: colors.primary)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _BosqueAction(theme: theme, icon: Icons.room_service_outlined, label: l10n.quickTileServices, onTap: params.onNavigateToServices),
            _BosqueAction(theme: theme, icon: Icons.history, label: l10n.quickTileHistory, onTap: () => params.onOpenMyOrders(context)),
            _BosqueAction(theme: theme, icon: Icons.map_outlined, label: l10n.quickTileMap, onTap: () => params.onOpenHotelInfo(context)),
            _BosqueAction(theme: theme, icon: Icons.campaign_outlined, label: l10n.quickTileNotices, onTap: () => params.onOpenNotices(context)),
          ],
        ),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.tertiaryContainer.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(theme.radiusXl * 1.6),
            border: Border.all(color: colors.tertiaryContainer.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(shape: BoxShape.circle, color: colors.tertiaryContainer.withValues(alpha: 0.3)),
                child: Icon(Icons.park_outlined, color: colors.tertiary, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.bosqueQuote,
                textAlign: TextAlign.center,
                style: theme.display(fontSize: 16, fontWeight: FontWeight.w500, color: colors.onTertiaryContainer).copyWith(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              Text('— John Muir', style: theme.labelCaps(color: colors.secondary)),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _RoundBell extends StatelessWidget {
  final GuestTemplateTheme theme;
  final int count;
  final VoidCallback onTap;

  const _RoundBell({required this.theme, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_outlined, color: colors.primary),
          if (count > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(shape: BoxShape.circle, color: colors.error, border: Border.all(color: colors.surface, width: 1.5)),
              ),
            ),
        ],
      ),
    );
  }
}

class _BosqueAction extends StatelessWidget {
  final GuestTemplateTheme theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BosqueAction({required this.theme, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(theme.radiusXl)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: Icon(icon, color: colors.primary, size: 20),
            ),
            const SizedBox(height: 8),
            Text(label, style: theme.body(fontSize: 13, fontWeight: FontWeight.w600, color: colors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
