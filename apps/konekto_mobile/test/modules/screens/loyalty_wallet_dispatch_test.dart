import 'package:flutter_test/flutter_test.dart';
import 'package:konekto/modules/screens/loyalty/elite_loyalty_screen.dart';
import 'package:konekto/modules/screens/loyalty/horizon_loyalty_screen.dart';
import 'package:konekto/modules/screens/loyalty/pulse_loyalty_screen.dart';
import 'package:konekto/modules/screens/loyalty_wallet_dispatch.dart';
import 'package:konekto/modules/screens/wallet/elite_wallet_screen.dart';
import 'package:konekto/modules/screens/wallet/horizon_wallet_screen.dart';
import 'package:konekto/modules/screens/wallet/pulse_wallet_screen.dart';
import 'package:konekto/templates/guest_template_registry.dart';
import 'package:konekto/templates/shared/guest_features.dart';

void main() {
  group('resolveLoyaltyScreen', () {
    test('returns the matching themed screen for elite/pulse/horizon', () {
      expect(resolveLoyaltyScreen(GuestTemplateId.elite, GuestFeatures.none), isA<EliteLoyaltyScreen>());
      expect(resolveLoyaltyScreen(GuestTemplateId.pulse, GuestFeatures.none), isA<PulseLoyaltyScreen>());
      expect(resolveLoyaltyScreen(GuestTemplateId.horizon, GuestFeatures.none), isA<HorizonLoyaltyScreen>());
    });

    test('returns null for aura/bosque — no themed screen exists for them yet', () {
      expect(resolveLoyaltyScreen(GuestTemplateId.aura, GuestFeatures.none), isNull);
      expect(resolveLoyaltyScreen(GuestTemplateId.bosque, GuestFeatures.none), isNull);
    });
  });

  group('resolveWalletScreen', () {
    test('returns the matching themed screen for elite/pulse/horizon', () {
      expect(resolveWalletScreen(GuestTemplateId.elite, GuestFeatures.none), isA<EliteWalletScreen>());
      expect(resolveWalletScreen(GuestTemplateId.pulse, GuestFeatures.none), isA<PulseWalletScreen>());
      expect(resolveWalletScreen(GuestTemplateId.horizon, GuestFeatures.none), isA<HorizonWalletScreen>());
    });

    test('returns null for aura/bosque — no themed screen exists for them yet', () {
      expect(resolveWalletScreen(GuestTemplateId.aura, GuestFeatures.none), isNull);
      expect(resolveWalletScreen(GuestTemplateId.bosque, GuestFeatures.none), isNull);
    });
  });
}
