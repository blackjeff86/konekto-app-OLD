import 'package:flutter/material.dart';
import 'package:konekto/app/tenants/minibar_page.dart';
import 'package:konekto/app/tenants/service_items_list_page.dart';
import 'package:konekto/data/tenant_repository.dart';
import 'package:konekto/data/tenant_repository_provider.dart';
import 'package:konekto/l10n/app_localizations.dart';
import 'package:konekto/models/service.dart' as models;
import 'package:konekto/modules/module_catalog_repository.dart';
import 'package:konekto/modules/module_definition.dart';
import 'package:konekto/theme/guest_app_theme.dart';
import 'package:konekto/widgets/tenant_image.dart';

/// Ícones conhecidos pro `Service.icon` (string) vindo da API — mesmo
/// conjunto oferecido no portal (`service_icons.dart`), mais alguns legados
/// (map/book_online) que ainda aparecem em dados antigos.
const Map<String, IconData> _iconMapping = {
  'home': Icons.home,
  'history': Icons.history,
  'person': Icons.person,
  'settings': Icons.settings,
  'restaurant': Icons.restaurant,
  'spa': Icons.spa,
  'sports_soccer': Icons.sports_soccer,
  'event': Icons.event,
  'widgets': Icons.widgets,
  'room_service': Icons.room_service,
  'map': Icons.map,
  'book_online': Icons.book_online,
  'pedal_bike': Icons.pedal_bike,
  'local_laundry_service': Icons.local_laundry_service,
  'pool': Icons.pool,
  'fitness_center': Icons.fitness_center,
  'local_bar': Icons.local_bar,
  'directions_car': Icons.directions_car,
  'celebration': Icons.celebration,
  'local_shipping': Icons.local_shipping,
  'pets': Icons.pets,
  'child_care': Icons.child_care,
};

/// Lista de serviços do hotel — busca `GET /services` (dinâmico, definido
/// pelo hotel no portal) em vez de ler um `servicesList` fixo do
/// `tenant_config.json`. Cada card leva pra [ServiceItemsListPage].
typedef _ServicesLoadResult = ({
  String? bannerImageUrl,
  List<models.Service> services,
  Map<String, String?> moduleIdToGroupId,
  List<ServiceGroup> serviceGroups,
});

class ServicesPage extends StatelessWidget {
  final Map<String, dynamic> tenantConfig;
  final GuestAppTheme theme;

  ServicesPage({super.key, required this.tenantConfig, required this.theme});

  final TenantRepository _repository = createTenantRepository();
  final ModuleCatalogRepository _moduleCatalogRepository = ModuleCatalogRepository();

  String get _hotelId => tenantConfig['id'] ?? 'hotel_1';

  Future<_ServicesLoadResult> _load() async {
    final pageConfig = await _repository.getServicesPageConfig(_hotelId);
    final rawServices = await _repository.getServices(_hotelId);
    final serviceStubs = rawServices
        .map((raw) => models.Service.fromJson(raw as Map<String, dynamic>))
        .toList();
    // `getServices` (lista) não traz os itens de cada serviço — só o
    // detalhe por id (`getService`) inclui `items`. Precisamos dos itens
    // aqui pra saber se algum é frigobar (`hasMinibarItems` abaixo), então
    // busca o detalhe completo de cada serviço em paralelo.
    final services = await Future.wait(
      serviceStubs.map(
        (stub) async {
          final raw = await _repository.getService(_hotelId, stub.id);
          return models.Service.fromJson(raw);
        },
      ),
    );
    final banner =
        (pageConfig['pageStyles'] as Map<String, dynamic>?)?['banner']
            as Map<String, dynamic>?;

    // Agrupamento (Fase 12) — catálogo é best-effort: se a busca falhar
    // (sem rede, backend fora do ar), a tela cai pro comportamento de hoje
    // (lista plana, sem grupo nenhum) em vez de quebrar.
    var moduleIdToGroupId = <String, String?>{};
    var serviceGroups = <ServiceGroup>[];
    try {
      final catalog = await _moduleCatalogRepository.getCatalog();
      moduleIdToGroupId = {for (final module in catalog) module.id: module.groupId};
      serviceGroups = await _moduleCatalogRepository.getServiceGroups();
    } on StateError {
      // catálogo indisponível — segue sem agrupar, nunca bloqueia a tela.
    }

    return (
      bannerImageUrl: banner?['imageUrl'] as String?,
      services: services,
      moduleIdToGroupId: moduleIdToGroupId,
      serviceGroups: serviceGroups,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ServicesLoadResult>(
      future: _load(),
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context)!;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: theme.bg,
            body: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: theme.bg,
            body: Center(
              child: Text(
                l10n.servicesLoadError,
                style: theme.body(color: theme.mutedColor),
              ),
            ),
          );
        }

        final bannerImageUrl = snapshot.data!.bannerImageUrl;
        final services = snapshot.data!.services;
        final hasMinibarItems = services.any((service) => service.items.any((item) => item.isMinibarItem));

        return Scaffold(
          backgroundColor: theme.bg,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: theme.tokens.screenPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(l10n.servicesTitle, style: theme.headline()),
                    const SizedBox(height: 16),
                    if (bannerImageUrl != null)
                      TenantImage(
                        imageUrl: bannerImageUrl,
                        hotelId: _hotelId,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(
                          theme.tokens.heroRadius,
                        ),
                      ),
                    if (bannerImageUrl != null) const SizedBox(height: 24),
                    if (hasMinibarItems) ...[
                      _MinibarCard(tenantConfig: tenantConfig, theme: theme),
                      const SizedBox(height: 16),
                    ],
                    if (services.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          l10n.servicesEmpty,
                          style: theme.body(color: theme.mutedColor),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: buildGroupedServiceWidgets(
                          services: services,
                          moduleIdToGroupId: snapshot.data!.moduleIdToGroupId,
                          serviceGroups: snapshot.data!.serviceGroups,
                          tenantConfig: tenantConfig,
                          theme: theme,
                        ),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Monta a lista de widgets da tela de Serviços agrupada por
/// `ServiceGroup` (Fase 12) — serviço sem módulo, ou cujo módulo não tem
/// `groupId` (ex: `room_service`, que aparece solto, não dentro de
/// "Gastronomia"), fica num bloco "sem grupo" no topo, sem cabeçalho —
/// exatamente a lista plana de hoje. Grupos vazios (nenhum serviço
/// pertence a eles) não aparecem. Função pública/top-level de propósito,
/// pra testar a lógica de agrupamento sem montar a árvore de widgets
/// inteira.
List<Widget> buildGroupedServiceWidgets({
  required List<models.Service> services,
  required Map<String, String?> moduleIdToGroupId,
  required List<ServiceGroup> serviceGroups,
  required Map<String, dynamic> tenantConfig,
  required GuestAppTheme theme,
}) {
  String? groupIdFor(models.Service service) {
    final moduleId = service.moduleId;
    if (moduleId == null) return null;
    return moduleIdToGroupId[moduleId];
  }

  final ungrouped = services.where((service) => groupIdFor(service) == null).toList();
  final sortedGroups = [...serviceGroups]..sort((a, b) => a.defaultOrder.compareTo(b.defaultOrder));

  final widgets = <Widget>[];
  void addCards(List<models.Service> group) {
    for (var i = 0; i < group.length; i++) {
      if (i > 0) widgets.add(const SizedBox(height: 12));
      widgets.add(_ServiceCard(service: group[i], tenantConfig: tenantConfig, theme: theme));
    }
  }

  if (ungrouped.isNotEmpty) {
    addCards(ungrouped);
  }
  for (final group in sortedGroups) {
    final groupServices = services.where((service) => groupIdFor(service) == group.id).toList();
    if (groupServices.isEmpty) continue;
    if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 24));
    widgets.add(Text(group.name, style: theme.headline(fontSize: 15, fontWeight: FontWeight.w700)));
    widgets.add(const SizedBox(height: 8));
    addCards(groupServices);
  }
  return widgets;
}

/// Atalho pro frigobar do quarto — deliberadamente separado da lista de
/// serviços do hotel (não é um `Service` que o hóspede navega igual aos
/// outros, é uma ação direta de "informar consumo"), com um tratamento
/// visual levemente diferente (fundo tingido) pra reforçar que é uma coisa
/// diferente de pedir um serviço.
class _MinibarCard extends StatelessWidget {
  final Map<String, dynamic> tenantConfig;
  final GuestAppTheme theme;

  const _MinibarCard({required this.tenantConfig, required this.theme});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MinibarPage(tenantConfig: tenantConfig, theme: theme),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        decoration: BoxDecoration(
          color: theme.accentSoft,
          borderRadius: BorderRadius.circular(theme.tokens.cardRadius),
          border: Border.all(color: theme.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: ShapeDecoration(
                color: theme.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(theme.tokens.iconTileRadius),
                ),
              ),
              child: const Icon(Icons.kitchen_outlined, size: 24.0, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.minibarCardTitle,
                    style: theme.headline(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.minibarCardSubtitle,
                    style: theme.body(fontSize: 14, color: theme.mutedColor, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: theme.mutedColor),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final models.Service service;
  final Map<String, dynamic> tenantConfig;
  final GuestAppTheme theme;

  const _ServiceCard({
    required this.service,
    required this.tenantConfig,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _iconMapping[service.icon] ?? Icons.miscellaneous_services;
    final languageCode = Localizations.localeOf(context).languageCode;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceItemsListPage(
              tenantConfig: tenantConfig,
              serviceId: service.id,
              theme: theme,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(theme.tokens.cardRadius),
          border: Border.all(color: theme.borderColor),
          boxShadow: theme.tokens.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: ShapeDecoration(
                color: theme.accentSoft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    theme.tokens.iconTileRadius,
                  ),
                ),
              ),
              child: Icon(icon, size: 24.0, color: theme.accent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.localizedName(languageCode),
                    style: theme.headline(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.localizedDescription(languageCode),
                    style: theme.body(
                      fontSize: 14,
                      color: theme.mutedColor,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: theme.mutedColor),
          ],
        ),
      ),
    );
  }
}
