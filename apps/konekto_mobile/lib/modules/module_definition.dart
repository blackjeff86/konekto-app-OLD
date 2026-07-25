/// Espelha `ModuleDefinition` em apps/konekto_api/lib/module-catalog.ts —
/// buscado via `GET /api/modules-catalog` (ModuleCatalogRepository), nunca
/// hardcoded aqui.
enum ModuleCategory { core, hospitalidade, financeiro, experiencia, comunicacao }

enum ModulePlacement { home, bottomNav, servicesMenu, settings }

ModuleCategory _categoryFromString(String raw) => switch (raw) {
      'core' => ModuleCategory.core,
      'hospitalidade' => ModuleCategory.hospitalidade,
      'financeiro' => ModuleCategory.financeiro,
      'experiencia' => ModuleCategory.experiencia,
      'comunicacao' => ModuleCategory.comunicacao,
      _ => ModuleCategory.core,
    };

ModulePlacement? _placementFromString(String raw) => switch (raw) {
      'home' => ModulePlacement.home,
      'bottomNav' => ModulePlacement.bottomNav,
      'servicesMenu' => ModulePlacement.servicesMenu,
      'settings' => ModulePlacement.settings,
      _ => null,
    };

class ModuleDefinition {
  final String id;
  final String name;
  final String description;
  final ModuleCategory category;
  final String? groupId;
  final String icon;
  final List<ModulePlacement> placement;
  final String? screenId;
  final int defaultOrder;
  final List<String> dependencies;
  final bool implemented;
  final String? configSchemaId;

  const ModuleDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.groupId,
    required this.icon,
    this.placement = const [],
    this.screenId,
    this.defaultOrder = 0,
    this.dependencies = const [],
    required this.implemented,
    this.configSchemaId,
  });

  factory ModuleDefinition.fromJson(Map<String, dynamic> json) {
    return ModuleDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      category: _categoryFromString(json['category'] as String? ?? 'core'),
      groupId: json['groupId'] as String?,
      icon: json['icon'] as String? ?? '',
      placement: ((json['placement'] as List<dynamic>?) ?? const [])
          .map((raw) => _placementFromString(raw as String))
          .whereType<ModulePlacement>()
          .toList(),
      screenId: json['screenId'] as String?,
      defaultOrder: json['defaultOrder'] as int? ?? 0,
      dependencies: ((json['dependencies'] as List<dynamic>?) ?? const []).map((item) => item as String).toList(),
      implemented: json['implemented'] as bool? ?? false,
      configSchemaId: json['configSchemaId'] as String?,
    );
  }
}

/// Espelha `ResolvedModule` em apps/konekto_api/lib/module-engine.ts —
/// já vem calculado dentro de `tenantConfig['enabledModules']` (o backend
/// resolve preset + extras + desligados, o Flutter nunca refaz essa conta).
class ResolvedModule {
  final String id;
  final bool enabled;
  final Map<String, dynamic> configuration;

  const ResolvedModule({required this.id, required this.enabled, this.configuration = const {}});

  factory ResolvedModule.fromJson(Map<String, dynamic> json) {
    return ResolvedModule(
      id: json['id'] as String,
      enabled: json['enabled'] as bool? ?? false,
      configuration: (json['configuration'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

/// Lê `tenantConfig['enabledModules']` (lista já resolvida vinda do GET
/// /api/hotels/:hotelId) — lista vazia/ausente é um caso válido (hotel
/// ainda não tocado pela Fase 3), não um erro.
List<ResolvedModule> resolvedModulesFromTenantConfig(Map<String, dynamic> tenantConfig) {
  final raw = tenantConfig['enabledModules'];
  if (raw is! List) return const [];
  return raw.whereType<Map<String, dynamic>>().map(ResolvedModule.fromJson).toList();
}

/// Espelha `ServiceGroup` em apps/konekto_api/lib/module-catalog.ts —
/// agrupamento da tela de Serviços (Fase 12).
class ServiceGroup {
  final String id;
  final String name;
  final int defaultOrder;

  const ServiceGroup({required this.id, required this.name, required this.defaultOrder});

  factory ServiceGroup.fromJson(Map<String, dynamic> json) {
    return ServiceGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      defaultOrder: json['defaultOrder'] as int? ?? 0,
    );
  }
}
