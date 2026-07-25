import 'package:flutter/material.dart';
import 'package:konekto/templates/elite/theme.dart';
import 'package:konekto/templates/shared/guest_features.dart';
import 'package:konekto/templates/shared/widgets/guest_feature_gate.dart';

/// Adaptado de `lite_wallet_charges/code.html` — atrás de
/// [GuestFeatureFlag.digitalWallet]. Saldo/lançamentos são dado de
/// demonstração (a Fase 4 troca isso pelo `StayBillPage` real, que já
/// existe e calcula o saldo de verdade a partir dos pedidos).
class EliteWalletScreen extends StatelessWidget {
  final GuestFeatures features;

  const EliteWalletScreen({super.key, required this.features});

  @override
  Widget build(BuildContext context) {
    final theme = eliteTheme;
    return GuestFeatureGate(
      features: features,
      flag: GuestFeatureFlag.digitalWallet,
      theme: theme,
      lockedTitle: 'Carteira digital',
      lockedMessage: 'Disponível para hotéis nos planos Premium e Enterprise.',
      builder: (context) {
        final colors = theme.colors;
        final charges = [
          (icon: Icons.restaurant_outlined, label: 'Room Service', amount: '\$945.50'),
          (icon: Icons.spa_outlined, label: 'Serenity Spa Services', amount: '\$675.00'),
        ];
        return ColoredBox(
          color: colors.surface,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOTAL BALANCE', style: theme.body(fontSize: 11, fontWeight: FontWeight.w600, color: colors.onSurfaceVariant).copyWith(letterSpacing: 1.5)),
                  const SizedBox(height: 6),
                  Text('\$4,820.50', style: theme.display(fontSize: 36, fontWeight: FontWeight.w400, color: colors.primary)),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(theme.radiusLg)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.contactless, color: colors.onPrimary),
                        const SizedBox(height: 24),
                        Text('JULIAN VANCE', style: theme.body(fontSize: 13, fontWeight: FontWeight.w600, color: colors.onPrimary).copyWith(letterSpacing: 1.5)),
                        Text('CARDHOLDER', style: theme.body(fontSize: 9, color: colors.onPrimary.withValues(alpha: 0.7)).copyWith(letterSpacing: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Recent Charges', style: theme.display(fontSize: 18, fontWeight: FontWeight.w600, color: colors.primary)),
                  const SizedBox(height: 12),
                  for (final charge in charges) ...[
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: colors.surfaceContainer),
                          child: Icon(charge.icon, color: colors.secondary, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Text(charge.label, style: theme.body(fontWeight: FontWeight.w600, color: colors.onSurface))),
                        Text(charge.amount, style: theme.body(fontWeight: FontWeight.w600, color: colors.primary)),
                      ],
                    ),
                    Divider(color: colors.outlineVariant.withValues(alpha: 0.4), height: 28),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(side: BorderSide(color: colors.outline), minimumSize: const Size.fromHeight(48)),
                    child: Text('Bespoke Support — Contact Front Desk', style: theme.body(color: colors.primary)),
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
