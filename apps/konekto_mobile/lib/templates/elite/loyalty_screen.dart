import 'package:flutter/material.dart';
import 'package:konekto/templates/elite/theme.dart';
import 'package:konekto/templates/shared/guest_features.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';
import 'package:konekto/templates/shared/widgets/guest_feature_gate.dart';

/// Adaptado de `lite_loyalty_program/code.html` ("L'Héritage Circle") —
/// atrás de [GuestFeatureFlag.loyalty]. Pontos/status são dado de
/// demonstração.
class EliteLoyaltyScreen extends StatelessWidget {
  final GuestFeatures features;

  const EliteLoyaltyScreen({super.key, required this.features});

  @override
  Widget build(BuildContext context) {
    final theme = eliteTheme;
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
                  Text('EXCLUSIVE MEMBERSHIP', style: theme.body(fontSize: 11, fontWeight: FontWeight.w600, color: colors.secondary).copyWith(letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Text("L'Héritage Circle", style: theme.display(fontSize: 26, fontWeight: FontWeight.w400, color: colors.primary)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: colors.surfaceContainer, borderRadius: BorderRadius.circular(theme.radiusLg)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('AVAILABLE POINTS', style: theme.body(fontSize: 10, color: colors.onSurfaceVariant).copyWith(letterSpacing: 1)),
                              Text('25,000', style: theme.display(fontSize: 22, fontWeight: FontWeight.w600, color: colors.primary)),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: colors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                          child: const Text('Redeem'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [colors.primaryContainer, colors.primary]), borderRadius: BorderRadius.circular(theme.radiusLg)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.workspace_premium, color: colors.secondaryContainer),
                            const SizedBox(width: 10),
                            Text('Platinum Status', style: theme.display(fontSize: 20, fontWeight: FontWeight.w600, color: colors.secondaryContainer)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You are 15,000 points away from reaching Diamond status.',
                          style: theme.body(fontSize: 13, color: colors.onPrimaryContainer),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(value: 0.65, minHeight: 6, backgroundColor: Colors.white.withValues(alpha: 0.2), color: colors.secondaryContainer),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text('65% Completed', style: theme.body(fontSize: 10, color: colors.secondaryContainer)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Exclusive Perks', style: theme.display(fontSize: 18, fontWeight: FontWeight.w600, color: colors.primary)),
                  const SizedBox(height: 14),
                  _PerkTile(theme: theme, icon: Icons.hotel_class_outlined, title: 'Complimentary Suite Upgrade', subtitle: 'Automatic upgrade upon arrival, subject to availability.'),
                  const SizedBox(height: 12),
                  _PerkTile(theme: theme, icon: Icons.event_available_outlined, title: 'Early Access to Events', subtitle: 'First to reserve seats for wine tastings and gallery openings.'),
                  const SizedBox(height: 12),
                  _PerkTile(theme: theme, icon: Icons.support_agent, title: 'Dedicated Concierge', subtitle: '24/7 priority access to our lifestyle management team.'),
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
  final String title;
  final String subtitle;

  const _PerkTile({required this.theme, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.surfaceContainer, borderRadius: BorderRadius.circular(theme.radiusLg)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, color: colors.secondaryContainer.withValues(alpha: 0.3)),
            child: Icon(icon, color: colors.secondary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.display(fontSize: 15, fontWeight: FontWeight.w600, color: colors.primary)),
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
