import 'package:flutter/material.dart';
import 'package:konekto/templates/horizon/theme.dart';
import 'package:konekto/templates/shared/guest_features.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';
import 'package:konekto/templates/shared/widgets/guest_feature_gate.dart';

/// Adaptado de `horizon_loyalty_rewards/code.html` ("Horizon Rewards") —
/// atrás de [GuestFeatureFlag.loyalty]. Pontos/perks são dado de
/// demonstração.
class HorizonLoyaltyScreen extends StatelessWidget {
  final GuestFeatures features;

  const HorizonLoyaltyScreen({super.key, required this.features});

  @override
  Widget build(BuildContext context) {
    final theme = horizonTheme;
    return GuestFeatureGate(
      features: features,
      flag: GuestFeatureFlag.loyalty,
      theme: theme,
      lockedTitle: 'Programa de fidelidade',
      lockedMessage: 'Disponível para hotéis nos planos Premium e Enterprise.',
      builder: (context) {
        final colors = theme.colors;
        return ColoredBox(
          color: colors.surface,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Horizon Rewards', style: theme.display(fontSize: 24, fontWeight: FontWeight.w600, color: colors.onSurface)),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [colors.primary, colors.primaryContainer]),
                      borderRadius: BorderRadius.circular(theme.radiusLg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.workspace_premium, color: Colors.white),
                            const SizedBox(width: 10),
                            Text('Elite Member', style: theme.display(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('You are currently enjoying our most exclusive coastal privileges.', style: theme.body(fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('NEXT TIER: LEGENDARY STATUS', style: theme.body(fontSize: 10, color: Colors.white.withValues(alpha: 0.8)).copyWith(letterSpacing: 1)),
                            Text('2,450 pts', style: theme.body(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Unlocked Experiences', style: theme.display(fontSize: 18, fontWeight: FontWeight.w600, color: colors.onSurface)),
                  const SizedBox(height: 14),
                  _PerkTile(theme: theme, icon: Icons.spa_outlined, badge: 'MEMBER EXCLUSIVE', title: 'Complimentary Spa Upgrade', subtitle: 'Elevate your next massage to a full body ritual.'),
                  const SizedBox(height: 12),
                  _PerkTile(theme: theme, icon: Icons.schedule, badge: 'TIER BENEFIT', title: 'Early Check-in', subtitle: 'Settle into your villa the moment you arrive.'),
                  const SizedBox(height: 12),
                  _PerkTile(theme: theme, icon: Icons.beach_access_outlined, badge: 'ELITE ONLY', title: 'Private Beach Access', subtitle: 'Reserved cabana at the Horizon Cove.'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PerkTile extends StatelessWidget {
  final GuestTemplateTheme theme;
  final IconData icon;
  final String badge;
  final String title;
  final String subtitle;

  const _PerkTile({required this.theme, required this.icon, required this.badge, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(theme.radiusLg)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, color: colors.primaryContainer.withValues(alpha: 0.3)),
            child: Icon(icon, color: colors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(badge, style: theme.body(fontSize: 9, fontWeight: FontWeight.w700, color: colors.secondary).copyWith(letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(title, style: theme.display(fontSize: 15, fontWeight: FontWeight.w600, color: colors.onSurface)),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.body(fontSize: 12.5, color: colors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
