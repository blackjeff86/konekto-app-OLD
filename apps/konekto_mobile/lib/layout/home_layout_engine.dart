import 'package:konekto/layout/home_layout_strategy.dart';
import 'package:konekto/templates/guest_template_registry.dart';

/// Qual estratégia de arranjo cada template usa — 1 linha de config, não
/// lógica. Trocar o arranjo de um template é mudar esta linha, nunca
/// reescrever o template.
const Map<GuestTemplateId, HomeLayoutStrategy> _homeLayoutStrategyByTemplate = {
  GuestTemplateId.aura: VerticalListLayoutStrategy(),
  GuestTemplateId.bosque: VerticalListLayoutStrategy(),
  GuestTemplateId.elite: MinimalDashboardLayoutStrategy(),
  GuestTemplateId.pulse: MinimalDashboardLayoutStrategy(),
  GuestTemplateId.horizon: HeroCarouselLayoutStrategy(),
};

HomeLayoutStrategy homeLayoutStrategyFor(GuestTemplateId templateId) =>
    _homeLayoutStrategyByTemplate[templateId] ?? const VerticalListLayoutStrategy();
