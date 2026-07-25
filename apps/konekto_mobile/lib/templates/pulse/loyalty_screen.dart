import 'package:flutter/material.dart';
import 'package:konekto/templates/pulse/theme.dart';
import 'package:konekto/templates/shared/guest_features.dart';
import 'package:konekto/templates/shared/widgets/guest_feature_gate.dart';

/// Adaptado de `pulse_loyalty_program/code.html` ("Pulse Core Membership")
/// — atrás de [GuestFeatureFlag.loyalty].
class PulseLoyaltyScreen extends StatelessWidget {
  final GuestFeatures features;

  const PulseLoyaltyScreen({super.key, required this.features});

  @override
  Widget build(BuildContext context) {
    final theme = pulseTheme;
    return GuestFeatureGate(
      features: features,
      flag: GuestFeatureFlag.loyalty,
      theme: theme,
      lockedTitle: 'Programa de fidelidade',
      lockedMessage: 'Disponível para hotéis nos planos Premium e Enterprise.',
      builder: (context) {
        final colors = theme.colors;
        final modules = [
          (icon: Icons.bolt, status: 'ACTIVE', title: 'Early Access'),
          (icon: Icons.upgrade, status: 'UPGRADED', title: 'Complimentary Upgrade'),
          (icon: Icons.support_agent, status: 'PRIORITY', title: 'Digital Concierge'),
          (icon: Icons.science_outlined, status: 'IN PROGRESS', title: 'Beta Test Participation'),
        ];
        return ColoredBox(
          color: colors.surface,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PULSE CORE MEMBERSHIP', style: theme.labelCaps(color: colors.primary).copyWith(letterSpacing: 2)),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(theme.radiusLg),
                      border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
                      boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.15), blurRadius: 24)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.diamond_outlined, color: colors.primary),
                            const SizedBox(width: 10),
                            Text('Platinum', style: theme.display(fontSize: 22, fontWeight: FontWeight.w700, color: colors.onSurface)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Progressing to Diamond Status', style: theme.body(fontSize: 13, color: colors.onSurfaceVariant)),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(value: 0.65, minHeight: 6, backgroundColor: colors.outlineVariant.withValues(alpha: 0.4), color: colors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Unlocked Modules', style: theme.display(fontSize: 18, fontWeight: FontWeight.w600, color: colors.onSurface)),
                  const SizedBox(height: 4),
                  Text('Your current active ecosystem perks.', style: theme.body(fontSize: 12.5, color: colors.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: [
                      for (final module in modules)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainer.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(theme.radiusLg),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(module.icon, color: colors.primary, size: 22),
                              const Spacer(),
                              Text(module.status, style: theme.body(fontSize: 9, fontWeight: FontWeight.w700, color: colors.primary).copyWith(letterSpacing: 1)),
                              const SizedBox(height: 4),
                              Text(module.title, style: theme.body(fontSize: 13, fontWeight: FontWeight.w600, color: colors.onSurface)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
