import 'package:flutter/material.dart';
import 'package:konekto/templates/horizon/theme.dart';
import 'package:konekto/templates/shared/guest_features.dart';
import 'package:konekto/templates/shared/widgets/guest_feature_gate.dart';

/// Adaptado de `horizon_wallet_billing/code.html` ("Total Stay Charges") —
/// atrás de [GuestFeatureFlag.digitalWallet]. Lançamentos são dado de
/// demonstração (a Fase 4 troca isso pelo `StayBillPage` real).
class HorizonWalletScreen extends StatelessWidget {
  final GuestFeatures features;

  const HorizonWalletScreen({super.key, required this.features});

  @override
  Widget build(BuildContext context) {
    final theme = horizonTheme;
    return GuestFeatureGate(
      features: features,
      flag: GuestFeatureFlag.digitalWallet,
      theme: theme,
      lockedTitle: 'Carteira digital',
      lockedMessage: 'Disponível para hotéis nos planos Premium e Enterprise.',
      builder: (context) {
        final colors = theme.colors;
        final charges = [
          (icon: Icons.restaurant_outlined, label: 'Sunset Grill Dinner', category: 'Dining', amount: '\$186.00'),
          (icon: Icons.spa_outlined, label: 'Spa Treatment', category: 'Experiences', amount: '\$240.00'),
          (icon: Icons.liquor_outlined, label: 'Villa Mini-Bar', category: 'Incidentals', amount: '\$42.00'),
        ];
        return ColoredBox(
          color: colors.surface,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOTAL STAY CHARGES', style: theme.body(fontSize: 11, fontWeight: FontWeight.w600, color: colors.onSurfaceVariant).copyWith(letterSpacing: 1.5)),
                  const SizedBox(height: 6),
                  Text('\$468.00', style: theme.display(fontSize: 34, fontWeight: FontWeight.w600, color: colors.onSurface)),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [colors.primary, colors.primaryContainer]), borderRadius: BorderRadius.circular(theme.radiusLg)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.contactless, color: Colors.white),
                        const SizedBox(height: 20),
                        Text('ALEX RIVERA', style: theme.body(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white).copyWith(letterSpacing: 1.5)),
                        Text('HORIZON ELITE CARD', style: theme.body(fontSize: 9, color: Colors.white.withValues(alpha: 0.7)).copyWith(letterSpacing: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Stay Summary', style: theme.display(fontSize: 18, fontWeight: FontWeight.w600, color: colors.onSurface)),
                  const SizedBox(height: 12),
                  for (final charge in charges) ...[
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: colors.surfaceContainerHighest),
                          child: Icon(charge.icon, color: colors.primary, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(charge.label, style: theme.body(fontWeight: FontWeight.w600, color: colors.onSurface)),
                              Text(charge.category, style: theme.body(fontSize: 11, color: colors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Text(charge.amount, style: theme.body(fontWeight: FontWeight.w600, color: colors.onSurface)),
                      ],
                    ),
                    Divider(color: colors.outlineVariant.withValues(alpha: 0.4), height: 28),
                  ],
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(side: BorderSide(color: colors.outline), minimumSize: const Size.fromHeight(48)),
                    child: Text('View All Detailed Receipts', style: theme.body(color: colors.primary)),
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
