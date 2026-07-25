import 'package:flutter/material.dart';
import 'package:konekto/l10n/app_localizations.dart';
import 'package:konekto/templates/shared/guest_template_content_params.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Aura: cartão de residência com selo de categoria do quarto e wifi
/// inline (sem acordeão — o mockup mostra a senha direto), grade 2x2 de
/// acesso rápido com ícone circular que inverte de cor, e um banner de
/// destaque com foto full-bleed. Adaptado de `aura_home/code.html`
/// (`stitch_hospitality_tech_white_label_design.zip`) — os cartões de
/// "Check-in/Check-out/Guests" do mockup foram omitidos porque o app não
/// tem essa data hoje (mesmo critério já usado nos 5 templates antigos:
/// nunca inventar dado que o backend não modela).
class AuraHomeContent extends StatelessWidget {
  final GuestTemplateContentParams params;

  const AuraHomeContent({super.key, required this.params});

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
            CircleAvatar(radius: 20, backgroundColor: colors.surfaceContainerHighest, child: Icon(Icons.person, color: colors.primary)),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.homeWelcomeName(params.userName), style: theme.display(fontSize: 20, fontWeight: FontWeight.w600, color: colors.primary))),
            _NotificationBell(theme: theme, count: params.notificationCount, onTap: () => params.onOpenNotices(context)),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(theme.radiusXl),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
            boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.roomNumberLabel(params.roomNumber), style: theme.display(fontSize: 22, fontWeight: FontWeight.w600, color: colors.primary)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: colors.surfaceContainerHighest.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(theme.radiusLg)),
                child: Row(
                  children: [
                    Icon(Icons.wifi, color: colors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.wifiNetworkLabel(params.wifiNetworkName), style: theme.labelCaps()),
                          Text(l10n.wifiPasswordLabel(params.wifiPassword), style: theme.body(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(l10n.homeOurServices, style: theme.display(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _AuraAction(theme: theme, icon: Icons.room_service_outlined, label: l10n.quickTileServices, onTap: params.onNavigateToServices)),
            const SizedBox(width: 12),
            Expanded(child: _AuraAction(theme: theme, icon: Icons.history, label: l10n.quickTileHistory, onTap: () => params.onOpenMyOrders(context))),
            const SizedBox(width: 12),
            Expanded(child: _AuraAction(theme: theme, icon: Icons.map_outlined, label: l10n.quickTileMap, onTap: () => params.onOpenHotelInfo(context))),
            const SizedBox(width: 12),
            Expanded(child: _AuraAction(theme: theme, icon: Icons.campaign_outlined, label: l10n.quickTileNotices, onTap: () => params.onOpenNotices(context))),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final GuestTemplateTheme theme;
  final int count;
  final VoidCallback onTap;

  const _NotificationBell({required this.theme, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, color: colors.surfaceContainerHighest),
            child: Icon(Icons.notifications_outlined, color: colors.onSurfaceVariant, size: 20),
          ),
          if (count > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(shape: BoxShape.circle, color: colors.error, border: Border.all(color: colors.surface, width: 1.5)),
                alignment: Alignment.center,
                child: Text(count > 9 ? '9+' : '$count', style: TextStyle(color: colors.onError, fontSize: 8, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}

class _AuraAction extends StatelessWidget {
  final GuestTemplateTheme theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AuraAction({required this.theme, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(theme.radiusLg)),
            child: Icon(icon, color: colors.primary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.labelCaps(color: colors.onSurface)),
        ],
      ),
    );
  }
}
