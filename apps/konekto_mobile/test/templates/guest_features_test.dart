import 'package:flutter_test/flutter_test.dart';
import 'package:konekto/templates/shared/guest_features.dart';

void main() {
  group('GuestFeatures.fromTenantConfig', () {
    test('returns has=true for a flag present in enabledFeatures', () {
      final features = GuestFeatures.fromTenantConfig({
        'enabledFeatures': ['digital_checkin', 'loyalty'],
      });

      expect(features.has(GuestFeatureFlag.digitalCheckin), isTrue);
      expect(features.has(GuestFeatureFlag.loyalty), isTrue);
    });

    test('returns has=false for a known flag absent from enabledFeatures', () {
      final features = GuestFeatures.fromTenantConfig({
        'enabledFeatures': ['digital_checkin'],
      });

      expect(features.has(GuestFeatureFlag.digitalWallet), isFalse);
    });

    test('falls back to no features when enabledFeatures is missing', () {
      final features = GuestFeatures.fromTenantConfig({'infra': 'amara_bay'});

      for (final flag in GuestFeatureFlag.values) {
        expect(features.has(flag), isFalse);
      }
    });

    test('falls back to no features when enabledFeatures is not a list', () {
      final features = GuestFeatures.fromTenantConfig({'enabledFeatures': 'not_a_list'});

      expect(features.has(GuestFeatureFlag.promotions), isFalse);
    });

    test('ignores unknown flag ids instead of throwing', () {
      final features = GuestFeatures.fromTenantConfig({
        'enabledFeatures': ['digital_checkin', 'some_future_flag_not_in_this_app_version'],
      });

      expect(features.has(GuestFeatureFlag.digitalCheckin), isTrue);
      expect(() => GuestFeatures.fromTenantConfig({'enabledFeatures': ['some_future_flag_not_in_this_app_version']}), returnsNormally);
    });

    test('GuestFeatures.none has every flag off', () {
      for (final flag in GuestFeatureFlag.values) {
        expect(GuestFeatures.none.has(flag), isFalse);
      }
    });
  });
}
