import 'package:flutter_test/flutter_test.dart';
import 'package:konekto/modules/module_definition.dart';
import 'package:konekto/modules/module_engine.dart';
import 'package:konekto/theme/guest_app_theme.dart';

ModuleDefinition _module(
  String id, {
  List<ModulePlacement> placement = const [],
  bool implemented = true,
  int defaultOrder = 0,
  String icon = 'home',
}) {
  return ModuleDefinition(
    id: id,
    name: id,
    description: '',
    category: ModuleCategory.core,
    icon: icon,
    placement: placement,
    screenId: id,
    defaultOrder: defaultOrder,
    implemented: implemented,
  );
}

void main() {
  group('ModuleEngine.resolveNavItems', () {
    test('falls back to kGuestNavItems when enabledModules is empty', () {
      final result = ModuleEngine.resolveNavItems(enabledModules: const [], catalog: const []);
      expect(result, kGuestNavItems);
    });

    test('resolves nav items from enabled, implemented, bottomNav-placement modules, ordered by defaultOrder', () {
      final catalog = [
        _module('profile', placement: const [ModulePlacement.bottomNav], defaultOrder: 3),
        _module('home', placement: const [ModulePlacement.bottomNav], defaultOrder: 0),
        _module('services', placement: const [ModulePlacement.bottomNav], defaultOrder: 1),
      ];
      final resolved = [
        const ResolvedModule(id: 'home', enabled: true),
        const ResolvedModule(id: 'services', enabled: true),
        const ResolvedModule(id: 'profile', enabled: true),
      ];

      final result = ModuleEngine.resolveNavItems(enabledModules: resolved, catalog: catalog);

      expect(result.map((item) => item.route).toList(), ['home', 'services', 'profile']);
    });

    test('excludes a disabled module even if it is in the catalog with bottomNav placement', () {
      final catalog = [
        _module('home', placement: const [ModulePlacement.bottomNav], defaultOrder: 0),
        _module('services', placement: const [ModulePlacement.bottomNav], defaultOrder: 1),
      ];
      final resolved = [
        const ResolvedModule(id: 'home', enabled: true),
        const ResolvedModule(id: 'services', enabled: false),
      ];

      final result = ModuleEngine.resolveNavItems(enabledModules: resolved, catalog: catalog);

      expect(result.map((item) => item.route).toList(), ['home']);
    });

    test('excludes a not-yet-implemented module even if enabled and bottomNav-placement', () {
      final catalog = [
        _module('home', placement: const [ModulePlacement.bottomNav], defaultOrder: 0),
        _module('interactive_map', placement: const [ModulePlacement.bottomNav], implemented: false, defaultOrder: 1),
      ];
      final resolved = [
        const ResolvedModule(id: 'home', enabled: true),
        const ResolvedModule(id: 'interactive_map', enabled: true),
      ];

      final result = ModuleEngine.resolveNavItems(enabledModules: resolved, catalog: catalog);

      expect(result.map((item) => item.route).toList(), ['home']);
    });

    test('excludes a module with home placement (not bottomNav) from the nav', () {
      final catalog = [
        _module('home', placement: const [ModulePlacement.bottomNav], defaultOrder: 0),
        _module('messages', placement: const [ModulePlacement.home], defaultOrder: 1),
      ];
      final resolved = [
        const ResolvedModule(id: 'home', enabled: true),
        const ResolvedModule(id: 'messages', enabled: true),
      ];

      final result = ModuleEngine.resolveNavItems(enabledModules: resolved, catalog: catalog);

      expect(result.map((item) => item.route).toList(), ['home']);
    });

    test('falls back to kGuestNavItems when no resolved module has bottomNav placement', () {
      final catalog = [_module('messages', placement: const [ModulePlacement.home])];
      final resolved = [const ResolvedModule(id: 'messages', enabled: true)];

      final result = ModuleEngine.resolveNavItems(enabledModules: resolved, catalog: catalog);

      expect(result, kGuestNavItems);
    });
  });

  group('ModuleEngine.resolveHomeModules / resolveServicesMenuModules', () {
    test('separates modules by placement independently', () {
      final catalog = [
        _module('hotel_info', placement: const [ModulePlacement.home], defaultOrder: 0),
        _module('room_service', placement: const [ModulePlacement.servicesMenu], defaultOrder: 0),
      ];
      final resolved = [
        const ResolvedModule(id: 'hotel_info', enabled: true),
        const ResolvedModule(id: 'room_service', enabled: true),
      ];

      final homeModules = ModuleEngine.resolveHomeModules(enabledModules: resolved, catalog: catalog);
      final servicesModules = ModuleEngine.resolveServicesMenuModules(enabledModules: resolved, catalog: catalog);

      expect(homeModules.map((m) => m.id), ['hotel_info']);
      expect(servicesModules.map((m) => m.id), ['room_service']);
    });
  });

  group('resolvedModulesFromTenantConfig', () {
    test('parses the enabledModules list from a raw tenantConfig map', () {
      final tenantConfig = {
        'enabledModules': [
          {'id': 'home', 'enabled': true, 'configuration': <String, dynamic>{}},
          {'id': 'restaurant', 'enabled': false, 'configuration': {'order': 2}},
        ],
      };

      final result = resolvedModulesFromTenantConfig(tenantConfig);

      expect(result, hasLength(2));
      expect(result[0].id, 'home');
      expect(result[0].enabled, isTrue);
      expect(result[1].configuration, {'order': 2});
    });

    test('returns an empty list when enabledModules is absent (hotel not yet touched by the backend migration)', () {
      expect(resolvedModulesFromTenantConfig({'template': 'aura'}), isEmpty);
    });

    test('returns an empty list when enabledModules is not a list', () {
      expect(resolvedModulesFromTenantConfig({'enabledModules': 'not_a_list'}), isEmpty);
    });
  });
}
