import 'package:flutter/material.dart';
import 'package:konekto/l10n/app_localizations.dart';
import 'package:konekto/templates/shared/guest_template_content_params.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Adaptado de `horizon_home/code.html`: cartão de vidro flutuante com
/// quarto + wifi, grade 2x2 de acesso rápido, banner de destaque. Foto de
/// fundo full-bleed do mockup (vista aérea de resort costeiro) virou um
/// degradê da própria paleta — sem foto de estoque genérica, mesmo
/// critério dos outros 4 templates.
class HorizonHomeContent extends StatelessWidget {
  final GuestTemplateContentParams params;

  const HorizonHomeContent({super.key, required this.params});

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
            CircleAvatar(radius: 20, backgroundColor: colors.primaryContainer.withValues(alpha: 0.3), child: Icon(Icons.person, color: colors.primary)),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.homeWelcomeName(params.userName), style: theme.display(fontSize: 20, fontWeight: FontWeight.w600, color: colors.onSurface))),
            _HorizonBell(theme: theme, count: params.notificationCount, onTap: () => params.onOpenNotices(context)),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [colors.primary, colors.primaryContainer]),
            borderRadius: BorderRadius.circular(theme.radiusXl),
          ),
          padding: const EdgeInsets.all(20),
          alignment: Alignment.bottomLeft,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(theme.radiusLg)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.roomNumberLabel(params.roomNumber), style: theme.body(fontSize: 11, color: colors.onSurfaceVariant)),
                    Text(l10n.wifiPasswordLabel(params.wifiPassword), style: theme.display(fontSize: 15, fontWeight: FontWeight.w600, color: colors.primary)),
                  ],
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 28, color: colors.outlineVariant),
                const SizedBox(width: 16),
                Icon(Icons.wb_sunny_outlined, color: colors.secondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(l10n.homeOurServices, style: theme.display(fontSize: 18, fontWeight: FontWeight.w600, color: colors.onSurface)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _HorizonAction(theme: theme, icon: Icons.room_service_outlined, label: l10n.quickTileServices, onTap: params.onNavigateToServices),
            _HorizonAction(theme: theme, icon: Icons.history, label: l10n.quickTileHistory, onTap: () => params.onOpenMyOrders(context)),
            _HorizonAction(theme: theme, icon: Icons.map_outlined, label: l10n.quickTileMap, onTap: () => params.onOpenHotelInfo(context)),
            _HorizonAction(theme: theme, icon: Icons.campaign_outlined, label: l10n.quickTileNotices, onTap: () => params.onOpenNotices(context)),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _HorizonBell extends StatelessWidget {
  final GuestTemplateTheme theme;
  final int count;
  final VoidCallback onTap;

  const _HorizonBell({required this.theme, required this.count, required this.onTap});

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
              child: Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: colors.secondary, border: Border.all(color: colors.surface, width: 1.5))),
            ),
        ],
      ),
    );
  }
}

class _HorizonAction extends StatelessWidget {
  final GuestTemplateTheme theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HorizonAction({required this.theme, required this.icon, required this.label, required this.onTap});

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
              width: 44,
              height: 44,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: Icon(icon, color: colors.primary, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, style: theme.body(fontSize: 13, fontWeight: FontWeight.w600, color: colors.onSurface)),
          ],
        ),
      ),
    );
  }
}
