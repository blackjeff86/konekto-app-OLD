import 'package:flutter/material.dart';
import 'package:konekto/layout/layout_registry.dart';
import 'package:konekto/modules/module_definition.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Home Layout Engine — decide COMO os módulos resolvidos (Module Engine)
/// se organizam visualmente na Home de um template. Módulos são sempre os
/// mesmos entre templates; só a estratégia de arranjo muda — nenhuma
/// lógica de negócio aqui, só composição visual.
abstract class HomeLayoutStrategy {
  Widget build(BuildContext context, List<ModuleDefinition> modules, GuestTemplateTheme theme);
}

/// Aura, Bosque — lista vertical, um card compacto por módulo.
class VerticalListLayoutStrategy implements HomeLayoutStrategy {
  const VerticalListLayoutStrategy();

  @override
  Widget build(BuildContext context, List<ModuleDefinition> modules, GuestTemplateTheme theme) {
    if (modules.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < modules.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          LayoutRegistry.resolve(modules[i].id, 'compact_card').builder(context, modules[i]),
        ],
      ],
    );
  }
}

/// Horizon — hero em destaque pro primeiro módulo, carrossel horizontal
/// pros demais.
class HeroCarouselLayoutStrategy implements HomeLayoutStrategy {
  const HeroCarouselLayoutStrategy();

  @override
  Widget build(BuildContext context, List<ModuleDefinition> modules, GuestTemplateTheme theme) {
    if (modules.isEmpty) return const SizedBox.shrink();
    final hero = modules.first;
    final rest = modules.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutRegistry.resolve(hero.id, 'hero_card').builder(context, hero),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: rest.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final module = rest[index];
                return SizedBox(
                  width: 220,
                  child: LayoutRegistry.resolve(module.id, 'carousel_card').builder(context, module),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// Elite, Pulse — grade tipo dashboard, 2 colunas.
class MinimalDashboardLayoutStrategy implements HomeLayoutStrategy {
  const MinimalDashboardLayoutStrategy();

  @override
  Widget build(BuildContext context, List<ModuleDefinition> modules, GuestTemplateTheme theme) {
    if (modules.isEmpty) return const SizedBox.shrink();
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [for (final module in modules) LayoutRegistry.resolve(module.id, 'dashboard_card').builder(context, module)],
    );
  }
}
