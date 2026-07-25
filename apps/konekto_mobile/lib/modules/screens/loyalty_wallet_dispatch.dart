import 'package:flutter/material.dart';
import 'package:konekto/modules/screens/loyalty/elite_loyalty_screen.dart';
import 'package:konekto/modules/screens/loyalty/horizon_loyalty_screen.dart';
import 'package:konekto/modules/screens/loyalty/pulse_loyalty_screen.dart';
import 'package:konekto/modules/screens/wallet/elite_wallet_screen.dart';
import 'package:konekto/modules/screens/wallet/horizon_wallet_screen.dart';
import 'package:konekto/modules/screens/wallet/pulse_wallet_screen.dart';
import 'package:konekto/templates/guest_template_registry.dart';
import 'package:konekto/templates/shared/guest_features.dart';

/// Loyalty/Wallet saíram de dentro de `templates/{elite,pulse,horizon}/`
/// (onde ficavam presos sem rota nenhuma) — mas cada tela ainda é desenhada
/// pra combinar com UM template específico (`eliteTheme`/`pulseTheme`/
/// `horizonTheme` embutidos em cada arquivo), não um Module Renderer
/// genérico ainda (isso exige desenho de verdade por módulo — fora de
/// escopo desta fase, ver tasks/plan.md). Por isso o dispatch é por
/// template: só Elite/Pulse/Horizon têm tela própria hoje; Aura/Bosque
/// devolvem `null` (chamador esconde a entrada em vez de abrir algo sem
/// tema correspondente).
Widget? resolveLoyaltyScreen(GuestTemplateId templateId, GuestFeatures features) {
  return switch (templateId) {
    GuestTemplateId.elite => EliteLoyaltyScreen(features: features),
    GuestTemplateId.pulse => PulseLoyaltyScreen(features: features),
    GuestTemplateId.horizon => HorizonLoyaltyScreen(features: features),
    GuestTemplateId.aura || GuestTemplateId.bosque => null,
  };
}

Widget? resolveWalletScreen(GuestTemplateId templateId, GuestFeatures features) {
  return switch (templateId) {
    GuestTemplateId.elite => EliteWalletScreen(features: features),
    GuestTemplateId.pulse => PulseWalletScreen(features: features),
    GuestTemplateId.horizon => HorizonWalletScreen(features: features),
    GuestTemplateId.aura || GuestTemplateId.bosque => null,
  };
}
