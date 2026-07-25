import 'package:flutter/material.dart';
import 'package:konekto/app/tenants/service_item_detail_page.dart';
import 'package:konekto/data/tenant_repository.dart';
import 'package:konekto/data/tenant_repository_provider.dart';
import 'package:konekto/l10n/app_localizations.dart';
import 'package:konekto/models/service.dart';
import 'package:konekto/theme/guest_app_theme.dart';
import 'package:konekto/widgets/tenant_image.dart';

class _MinibarEntry {
  final Service service;
  final ServiceItem item;

  const _MinibarEntry({required this.service, required this.item});
}

/// Lista só os itens de frigobar do hotel, juntando todos os serviços em
/// que estejam cadastrados — separada da lista normal de Serviço de Quarto
/// de propósito (informar consumo é uma ação bem diferente de pedir algo
/// pra preparar, misturar as duas confunde o hóspede).
class MinibarPage extends StatefulWidget {
  final Map<String, dynamic> tenantConfig;
  final GuestAppTheme theme;

  const MinibarPage({super.key, required this.tenantConfig, required this.theme});

  @override
  State<MinibarPage> createState() => _MinibarPageState();
}

class _MinibarPageState extends State<MinibarPage> {
  final TenantRepository _repository = createTenantRepository();
  late final Future<List<_MinibarEntry>> _entriesFuture;

  GuestAppTheme get theme => widget.theme;
  String get _hotelId => widget.tenantConfig['id'] ?? 'hotel_1';

  @override
  void initState() {
    super.initState();
    _entriesFuture = _load();
  }

  Future<List<_MinibarEntry>> _load() async {
    final raw = await _repository.getServices(_hotelId);
    final serviceStubs = raw.map((json) => Service.fromJson(json as Map<String, dynamic>)).toList();
    // `getServices` (lista) não traz os itens de cada serviço — só o
    // detalhe por id (`getService`) inclui `items`, então busca cada um em
    // paralelo pra poder juntar os itens de frigobar de todos os serviços.
    final services = await Future.wait(
      serviceStubs.map((stub) async {
        final json = await _repository.getService(_hotelId, stub.id);
        return Service.fromJson(json);
      }),
    );
    return [
      for (final service in services)
        for (final item in service.items)
          if (item.isMinibarItem) _MinibarEntry(service: service, item: item),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: FutureBuilder<List<_MinibarEntry>>(
          future: _entriesFuture,
          builder: (context, snapshot) {
            final l10n = AppLocalizations.of(context)!;
            final languageCode = Localizations.localeOf(context).languageCode;
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Text(l10n.servicesLoadError, style: theme.body(color: theme.mutedColor)),
              );
            }

            final entries = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: theme.textColor),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(l10n.minibarTitle, style: theme.headline(fontSize: 22)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
                  child: Text(
                    l10n.minibarPageSubtitle,
                    style: theme.body(fontSize: 13, color: theme.mutedColor, height: 1.4),
                  ),
                ),
                Expanded(
                  child: entries.isEmpty
                      ? Center(
                          child: Text(l10n.minibarEmpty, style: theme.body(color: theme.mutedColor)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: entries.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return _MinibarItemCard(
                              item: entry.item,
                              hotelId: _hotelId,
                              theme: theme,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ServiceItemDetailPage(
                                      tenantConfig: widget.tenantConfig,
                                      serviceId: entry.service.id,
                                      serviceName: entry.service.localizedName(languageCode),
                                      serviceType: entry.service.type,
                                      service: entry.service,
                                      item: entry.item,
                                      hotelId: _hotelId,
                                      theme: theme,
                                      isMinibarReportFlow: true,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MinibarItemCard extends StatelessWidget {
  final ServiceItem item;
  final String hotelId;
  final GuestAppTheme theme;
  final VoidCallback onTap;

  const _MinibarItemCard({required this.item, required this.hotelId, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(theme.tokens.cardRadius),
          border: Border.all(color: theme.borderColor),
          boxShadow: theme.tokens.cardShadow,
        ),
        child: Row(
          children: [
            TenantImage(
              imageUrl: item.imageUrl,
              hotelId: hotelId,
              height: 68,
              width: 68,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(theme.tokens.iconTileRadius),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.localizedName(languageCode),
                    style: theme.headline(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.price != null ? 'R\$ ${item.price!.toStringAsFixed(2)}' : l10n.priceOnRequest,
                    style: theme.body(fontSize: 13, fontWeight: FontWeight.w600, color: theme.accent),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.mutedColor),
          ],
        ),
      ),
    );
  }
}
