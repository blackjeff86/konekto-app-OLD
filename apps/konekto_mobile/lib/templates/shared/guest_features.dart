/// Catálogo de feature flags do app do hóspede — espelha
/// `apps/sevvn_api/lib/feature-flags.ts` (`FEATURE_FLAGS`). Cada entrada
/// aqui precisa ter uma correspondente lá, e vice-versa.
enum GuestFeatureFlag {
  digitalCheckin('digital_checkin'),
  digitalCheckout('digital_checkout'),
  interactiveMap('interactive_map'),
  promotions('promotions'),
  loyalty('loyalty'),
  digitalWallet('digital_wallet'),
  multilingualChat('multilingual_chat'),
  serviceReviews('service_reviews'),
  smartNotifications('smart_notifications');

  final String id;
  const GuestFeatureFlag(this.id);
}

/// Resolve quais features Premium/Enterprise estão liberadas pro hotel do
/// hóspede atual, a partir de `tenantConfig['enabledModules']` — a lista já
/// resolvida pelo Module Engine (backend), que soma preset do plano +
/// cortesia da equipe Konekto − o que o hotel desligou (ver
/// `apps/sevvn_api/lib/module-engine.ts`). Antes da arquitetura de
/// módulos isso lia `tenantConfig['enabledFeatures']` (campo renomeado pra
/// `extraModules` — só os extras de cortesia, não o resolvido) — atualizado
/// aqui pra não ficar lendo um campo morto e sempre resolver pra
/// [GuestFeatures.none].
///
/// Uma flag que não bate com nenhum [GuestFeatureFlag] conhecido (nome
/// removido/ainda não implementado nesta versão do app) é ignorada em vez
/// de quebrar — nunca trata flag desconhecida como ligada.
class GuestFeatures {
  final Set<String> _enabledIds;

  const GuestFeatures._(this._enabledIds);

  static const GuestFeatures none = GuestFeatures._({});

  factory GuestFeatures.fromTenantConfig(Map<String, dynamic> tenantConfig) {
    final raw = tenantConfig['enabledModules'];
    if (raw is! List) return GuestFeatures.none;
    final enabledIds = raw
        .whereType<Map<String, dynamic>>()
        .where((module) => module['enabled'] == true)
        .map((module) => module['id'])
        .whereType<String>()
        .toSet();
    return GuestFeatures._(enabledIds);
  }

  bool has(GuestFeatureFlag flag) => _enabledIds.contains(flag.id);
}

