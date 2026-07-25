import 'package:konekto/modules/module_definition.dart';
import 'package:konekto/modules/module_icons.dart';
import 'package:konekto/theme/guest_app_theme.dart';

/// Module Engine — função pura, só decide QUAIS módulos estão ativos e em
/// que ordem, pra cada superfície (nav, Home, menu de Serviços). Nada de
/// layout, navegação ou tema aqui — isso é Home Layout Engine/Navigation
/// Engine/Theme Engine (fases seguintes).
class ModuleEngine {
  const ModuleEngine._();

  /// Bottom nav — módulos com `placement: bottomNav`, habilitados,
  /// implementados, ordenados por `defaultOrder`. Fallback pros 4 itens
  /// fixos de hoje ([kGuestNavItems]) se `enabledModules` vier vazio
  /// (hotel ainda não tocado pela migração de módulos no backend) ou se a
  /// resolução não encontrar nenhum módulo de nav — nunca deixa a nav
  /// vazia.
  static List<GuestNavItem> resolveNavItems({
    required List<ResolvedModule> enabledModules,
    required List<ModuleDefinition> catalog,
  }) {
    final navModules = _resolveByPlacement(
      enabledModules: enabledModules,
      catalog: catalog,
      placement: ModulePlacement.bottomNav,
    );
    if (navModules.isEmpty) return kGuestNavItems;
    return navModules.map((module) => GuestNavItem(resolveModuleIcon(module.icon), module.screenId ?? module.id)).toList();
  }

  /// Módulos que aparecem na tela "Serviços" — hoje a tela já busca o
  /// catálogo de `Service`/`ServiceItem` dinâmico da API própria (não este
  /// Module Engine); isso passa a valer de fato na Fase 12, quando o
  /// catálogo de Serviços for gateado por módulo. Por enquanto devolve os
  /// módulos de categoria Hospitalidade habilitados, pra telas futuras
  /// (ex: agrupamento) já terem de onde ler.
  static List<ModuleDefinition> resolveServicesMenuModules({
    required List<ResolvedModule> enabledModules,
    required List<ModuleDefinition> catalog,
  }) {
    return _resolveByPlacement(enabledModules: enabledModules, catalog: catalog, placement: ModulePlacement.servicesMenu);
  }

  /// Módulos que aparecem como seção/card na Home — consumido pelo Home
  /// Layout Engine (fase seguinte) pra montar a Home de cada template.
  static List<ModuleDefinition> resolveHomeModules({
    required List<ResolvedModule> enabledModules,
    required List<ModuleDefinition> catalog,
  }) {
    return _resolveByPlacement(enabledModules: enabledModules, catalog: catalog, placement: ModulePlacement.home);
  }

  static List<ModuleDefinition> _resolveByPlacement({
    required List<ResolvedModule> enabledModules,
    required List<ModuleDefinition> catalog,
    required ModulePlacement placement,
  }) {
    final catalogById = {for (final module in catalog) module.id: module};
    final resolved = enabledModules
        .where((resolvedModule) => resolvedModule.enabled)
        .map((resolvedModule) => catalogById[resolvedModule.id])
        .whereType<ModuleDefinition>()
        .where((module) => module.implemented && module.placement.contains(placement))
        .toList();
    resolved.sort((a, b) => a.defaultOrder.compareTo(b.defaultOrder));
    return resolved;
  }
}
