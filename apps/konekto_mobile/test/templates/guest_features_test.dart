import 'package:flutter_test/flutter_test.dart';
import 'package:konekto/templates/shared/guest_features.dart';

void main() {
  group('GuestFeatures.fromTenantConfig', () {
    test('returns has=true for a flag whose resolved module is enabled', () {
      final features = GuestFeatures.fromTenantConfig({
        'enabledModules': [
          {'id': 'digital_checkin', 'enabled': true, 'configuration': <String, dynamic>{}},
          {'id': 'loyalty', 'enabled': true, 'configuration': <String, dynamic>{}},
        ],
      });

      expect(features.has(GuestFeatureFlag.digitalCheckin), isTrue);
      expect(features.has(GuestFeatureFlag.loyalty), isTrue);
    });

    test('returns has=false for a resolved module the hotel disabled (enabled: false)', () {
      final features = GuestFeatures.fromTenantConfig({
        'enabledModules': [
          {'id': 'digital_wallet', 'enabled': false, 'configuration': <String, dynamic>{}},
        ],
      });

      expect(features.has(GuestFeatureFlag.digitalWallet), isFalse);
    });

    test('returns has=false for a known flag absent from enabledModules', () {
      final features = GuestFeatures.fromTenantConfig({
        'enabledModules': [
          {'id': 'digital_checkin', 'enabled': true, 'configuration': <String, dynamic>{}},
        ],
      });

      expect(features.has(GuestFeatureFlag.digitalWallet), isFalse);
    });

    test('falls back to no features when enabledModules is missing', () {
      final features = GuestFeatures.fromTenantConfig({'template': 'aura'});

      for (final flag in GuestFeatureFlag.values) {
        expect(features.has(flag), isFalse);
      }
    });

    test('falls back to no features when enabledModules is not a list', () {
      final features = GuestFeatures.fromTenantConfig({'enabledModules': 'not_a_list'});

      expect(features.has(GuestFeatureFlag.promotions), isFalse);
    });

    test('ignores unknown module ids instead of throwing', () {
      final features = GuestFeatures.fromTenantConfig({
        'enabledModules': [
          {'id': 'digital_checkin', 'enabled': true, 'configuration': <String, dynamic>{}},
          {'id': 'some_future_module_not_in_this_app_version', 'enabled': true, 'configuration': <String, dynamic>{}},
        ],
      });

      expect(features.has(GuestFeatureFlag.digitalCheckin), isTrue);
      expect(
        () => GuestFeatures.fromTenantConfig({
          'enabledModules': [
            {'id': 'some_future_module_not_in_this_app_version', 'enabled': true, 'configuration': <String, dynamic>{}},
          ],
        }),
        returnsNormally,
      );
    });

    test('GuestFeatures.none has every flag off', () {
      for (final flag in GuestFeatureFlag.values) {
        expect(GuestFeatures.none.has(flag), isFalse);
      }
    });
  });
}
