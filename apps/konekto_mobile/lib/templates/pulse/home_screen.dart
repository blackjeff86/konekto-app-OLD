import 'package:flutter/material.dart';
import 'package:konekto/l10n/app_localizations.dart';
import 'package:konekto/templates/shared/guest_template_content_params.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Pulse: único template escuro por padrão — cartão de vidro com brilho
/// dourado ("glow-gold"), grade 2x2 de ações num cartão translúcido, ícone
/// de casa com contorno dourado no canto do cartão de residência. Adaptado
/// de `pulse_home/code.html`. O card "Cyber-Bar Happy Hour" do mockup foi
/// trocado por um convite genérico pros Serviços (mesmo critério do banner
/// do Casa Marechal antigo: sem evento fixo sem contrapartida real).
class PulseHomeContent extends StatelessWidget {
  final GuestTemplateContentParams params;

  const PulseHomeContent({super.key, required this.params});

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
            CircleAvatar(radius: 18, backgroundColor: colors.primaryContainer, child: Icon(Icons.person, color: colors.onPrimaryContainer, size: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.pulseTag.toUpperCase(),
                style: theme.display(fontSize: 16, fontWeight: FontWeight.w700, color: colors.primary).copyWith(letterSpacing: 3),
              ),
            ),
            _PulseBell(theme: theme, count: params.notificationCount, onTap: () => params.onOpenNotices(context)),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surfaceContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(theme.radiusLg),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.12), blurRadius: 30)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.homeWelcomeName(params.userName),
                style: theme.display(fontSize: 20, fontWeight: FontWeight.w600, color: colors.onSurface).copyWith(letterSpacing: 0.5),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.roomNumberLabel(params.roomNumber), style: theme.body(fontSize: 14, color: colors.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.wifi, color: colors.primary, size: 16),
                            const SizedBox(width: 6),
                            Expanded(child: Text(l10n.wifiPasswordLabel(params.wifiPassword), style: theme.body(color: colors.onSurface))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: colors.primary.withValues(alpha: 0.3)), color: colors.primary.withValues(alpha: 0.05)),
                    child: Icon(Icons.home_filled, color: colors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.homeOurServices.toUpperCase(),
          style: theme.body(fontSize: 12, fontWeight: FontWeight.w600, color: colors.onSurfaceVariant.withValues(alpha: 0.6)).copyWith(letterSpacing: 2),
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _PulseAction(theme: theme, icon: Icons.room_service_outlined, label: l10n.quickTileServices, onTap: params.onNavigateToServices),
            _PulseAction(theme: theme, icon: Icons.history, label: l10n.quickTileHistory, onTap: () => params.onOpenMyOrders(context)),
            _PulseAction(theme: theme, icon: Icons.map_outlined, label: l10n.quickTileMap, onTap: () => params.onOpenHotelInfo(context)),
            _PulseAction(theme: theme, icon: Icons.campaign_outlined, label: l10n.quickTileNotices, onTap: () => params.onOpenNotices(context)),
          ],
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: params.onNavigateToServices,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(theme.radiusXl),
              border: Border.all(color: colors.primary.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.casaConciergeTitle, style: theme.display(fontSize: 16, fontWeight: FontWeight.w600, color: colors.onSurface)),
                      const SizedBox(height: 4),
                      Text(l10n.casaConciergeSubtitle, style: theme.body(fontSize: 12.5, color: colors.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward, color: colors.primary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _PulseBell extends StatelessWidget {
  final GuestTemplateTheme theme;
  final int count;
  final VoidCallback onTap;

  const _PulseBell({required this.theme, required this.count, required this.onTap});

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
              child: Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: colors.error, border: Border.all(color: colors.surface, width: 1.5))),
            ),
        ],
      ),
    );
  }
}

class _PulseAction extends StatelessWidget {
  final GuestTemplateTheme theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PulseAction({required this.theme, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(theme.radiusLg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, color: colors.surfaceContainerHighest),
              child: Icon(icon, color: colors.primary, size: 20),
            ),
            const SizedBox(height: 8),
            Text(label, style: theme.labelCaps(color: colors.onSurface)),
          ],
        ),
      ),
    );
  }
}
