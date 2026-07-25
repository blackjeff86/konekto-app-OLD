/// Catálogo de feature flags do app do hóspede — espelha
/// `apps/konekto_api/lib/feature-flags.ts` (`FEATURE_FLAGS`). Cada entrada
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
/// hóspede atual, a partir de `tenantConfig['enabledFeatures']` (lista de
/// strings decidida no backend por `lib/feature-flags.ts`, incluindo
/// eventuais liberações de cortesia feitas pela equipe Konekto — o app não
/// sabe nem precisa saber a diferença entre "veio do plano" e "cortesia").
///
/// Uma flag que não bate com nenhum [GuestFeatureFlag] conhecido (nome
/// removido/ainda não implementado nesta versão do app) é ignorada em vez
/// de quebrar — nunca trata flag desconhecida como ligada.
class GuestFeatures {
  final Set<String> _enabledIds;

  const GuestFeatures._(this._enabledIds);

  static const GuestFeatures none = GuestFeatures._({});

  factory GuestFeatures.fromTenantConfig(Map<String, dynamic> tenantConfig) {
    final raw = tenantConfig['enabledFeatures'];
    if (raw is! List) return GuestFeatures.none;
    return GuestFeatures._(raw.whereType<String>().toSet());
  }

  bool has(GuestFeatureFlag flag) => _enabledIds.contains(flag.id);
}
