import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konekto/app/tenants/services_page.dart';
import 'package:konekto/models/service.dart';
import 'package:konekto/modules/module_definition.dart';
import 'package:konekto/theme/guest_app_theme.dart';

Service _service(String id, {String? moduleId}) => Service(
      id: id,
      name: id,
      slug: id,
      icon: 'restaurant',
      description: 'desc',
      type: ServiceType.activity,
      moduleId: moduleId,
    );

final _theme = GuestAppTheme.fromTenantConfig(const {});

void main() {
  group('buildGroupedServiceWidgets', () {
    test('services without a matching group render first, ungrouped, with no header', () {
      final widgets = buildGroupedServiceWidgets(
        services: [_service('room-service', moduleId: 'room_service')],
        moduleIdToGroupId: {'room_service': null},
        serviceGroups: const [],
        tenantConfig: const {},
        theme: _theme,
      );

      // Só o card, nenhum Text de cabeçalho de grupo antes dele.
      expect(widgets.whereType<Text>(), isEmpty);
    });

    test('groups services under their module\'s groupId, in group defaultOrder', () {
      final widgets = buildGroupedServiceWidgets(
        services: [_service('passeios', moduleId: 'tours'), _service('spa', moduleId: 'spa')],
        moduleIdToGroupId: {'tours': 'experiencias', 'spa': 'bem_estar'},
        serviceGroups: const [
          ServiceGroup(id: 'bem_estar', name: 'Bem-estar', defaultOrder: 1),
          ServiceGroup(id: 'experiencias', name: 'Experiências', defaultOrder: 3),
        ],
        tenantConfig: const {},
        theme: _theme,
      );

      final headers = widgets.whereType<Text>().map((t) => (t.data)).toList();
      expect(headers, ['Bem-estar', 'Experiências']);
    });

    test('a group with no matching service does not render a header', () {
      final widgets = buildGroupedServiceWidgets(
        services: [_service('spa', moduleId: 'spa')],
        moduleIdToGroupId: {'spa': 'bem_estar'},
        serviceGroups: const [
          ServiceGroup(id: 'bem_estar', name: 'Bem-estar', defaultOrder: 0),
          ServiceGroup(id: 'gastronomia', name: 'Gastronomia', defaultOrder: 1),
        ],
        tenantConfig: const {},
        theme: _theme,
      );

      final headers = widgets.whereType<Text>().map((t) => t.data).toList();
      expect(headers, ['Bem-estar']);
    });

    test('a service whose module has no groupId falls into the ungrouped bucket', () {
      final widgets = buildGroupedServiceWidgets(
        services: [_service('room-service', moduleId: 'room_service'), _service('spa', moduleId: 'spa')],
        moduleIdToGroupId: {'room_service': null, 'spa': 'bem_estar'},
        serviceGroups: const [ServiceGroup(id: 'bem_estar', name: 'Bem-estar', defaultOrder: 0)],
        tenantConfig: const {},
        theme: _theme,
      );

      final headers = widgets.whereType<Text>().map((t) => t.data).toList();
      expect(headers, ['Bem-estar']);
    });

    test('a service with no moduleId at all is ungrouped (legacy data before Fase 12)', () {
      final widgets = buildGroupedServiceWidgets(
        services: [_service('legacy-service')],
        moduleIdToGroupId: const {},
        serviceGroups: const [],
        tenantConfig: const {},
        theme: _theme,
      );

      expect(widgets.whereType<Text>(), isEmpty);
    });
  });
}
