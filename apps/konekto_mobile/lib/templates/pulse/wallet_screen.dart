import 'package:flutter/material.dart';
import 'package:konekto/templates/pulse/theme.dart';
import 'package:konekto/templates/shared/guest_features.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';
import 'package:konekto/templates/shared/widgets/guest_feature_gate.dart';

/// Adaptado de `pulse_wallet_charges/code.html` — atrás de
/// [GuestFeatureFlag.digitalWallet]. Saldo/lançamentos são dado de
/// demonstração (a Fase 4 troca isso pelo `StayBillPage` real).
class PulseWalletScreen extends StatelessWidget {
  final GuestFeatures features;

  const PulseWalletScreen({super.key, required this.features});

  @override
  Widget build(BuildContext context) {
    final theme = pulseTheme;
    return GuestFeatureGate(
      features: features,
      flag: GuestFeatureFlag.digitalWallet,
      theme: theme,
      lockedTitle: 'Carteira digital',
      lockedMessage: 'Disponível para hotéis nos planos Premium e Enterprise.',
      builder: (context) {
        final colors = theme.colors;
        final charges = [
          (label: 'Room Service', amount: '\$142.00', status: 'PENDING'),
          (label: 'Cyber Spa', amount: '\$350.00', status: 'AUTHORIZED'),
          (label: 'Observation Bar', amount: '\$85.00', status: 'AUTHORIZED'),
          (label: 'Private Transfer', amount: '\$120.00', status: 'SETTLED'),
        ];
        return ColoredBox(
          color: colors.surface,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOTAL BALANCE', style: theme.labelCaps(color: colors.onSurfaceVariant.withValues(alpha: 0.7)).copyWith(letterSpacing: 2)),
                  const SizedBox(height: 6),
                  Text('\$2,450.00', style: theme.display(fontSize: 34, fontWeight: FontWeight.w700, color: colors.primary)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _StatCard(theme: theme, label: 'Daily Limit', value: '\$5,000')),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(theme: theme, label: 'Pulse Points', value: '12.4K')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Recent Charges', style: theme.display(fontSize: 18, fontWeight: FontWeight.w600, color: colors.onSurface)),
                  const SizedBox(height: 12),
                  for (final charge in charges) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainer.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(theme.radiusLg),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(charge.label, style: theme.body(fontWeight: FontWeight.w600, color: colors.onSurface)),
                                const SizedBox(height: 2),
                                Text(charge.status, style: theme.body(fontSize: 10, color: colors.onSurfaceVariant).copyWith(letterSpacing: 1)),
                              ],
                            ),
                          ),
                          Text(charge.amount, style: theme.body(fontWeight: FontWeight.w600, color: colors.primary)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final GuestTemplateTheme theme;
  final String label;
  final String value;

  const _StatCard({required this.theme, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(theme.radiusLg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.body(fontSize: 11, color: colors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value, style: theme.display(fontSize: 18, fontWeight: FontWeight.w600, color: colors.onSurface)),
        ],
      ),
    );
  }
}
