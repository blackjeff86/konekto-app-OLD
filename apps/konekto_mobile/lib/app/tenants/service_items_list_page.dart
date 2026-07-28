import 'package:flutter/material.dart';
import 'package:konekto/app/tenants/service_item_detail_page.dart';
import 'package:konekto/app/tenants/table_reservation_sheet.dart';
import 'package:konekto/data/guest_claim_repository.dart';
import 'package:konekto/data/orders_repository.dart';
import 'package:konekto/data/tenant_repository.dart';
import 'package:konekto/data/tenant_repository_provider.dart';
import 'package:konekto/l10n/app_localizations.dart';
import 'package:konekto/models/service.dart';
import 'package:konekto/theme/guest_app_theme.dart';
import 'package:konekto/widgets/tenant_image.dart';

/// Lista de itens de um serviço (cardápio de room service, tratamentos de
/// spa, cardápio de um restaurante, eventos, passeios, ou qualquer serviço
/// que o hotel tenha criado) — substitui as 5 telas antigas de lista
/// (room_service_page, spa_services_list, restaurant_list_page,
/// eventos_page, passeios_page) por uma única tela genérica.
class ServiceItemsListPage extends StatefulWidget {
  final String hotelId;
  final Map<String, dynamic> tenantConfig;
  final String serviceId;
  final GuestAppTheme theme;

  const ServiceItemsListPage({
    super.key,
    required this.hotelId,
    required this.tenantConfig,
    required this.serviceId,
    required this.theme,
  });

  @override
  State<ServiceItemsListPage> createState() => _ServiceItemsListPageState();
}

class _ServiceItemsListPageState extends State<ServiceItemsListPage> {
  final TenantRepository _repository = createTenantRepository();
  final GuestClaimRepository _guestClaimRepository = GuestClaimRepository();
  final OrdersRepository _ordersRepository = OrdersRepository();
  late final Future<Service> _serviceFuture;
  bool _isReservingTable = false;

  GuestAppTheme get theme => widget.theme;
  String get _hotelId => widget.hotelId;

  @override
  void initState() {
    super.initState();
    _serviceFuture = _load();
  }

  Future<Service> _load() async {
    final raw = await _repository.getService(_hotelId, widget.serviceId);
    return Service.fromJson(raw);
  }

  Future<void> _reserveTable(BuildContext context, Service service) async {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final result = await showTableReservationSheet(
      context,
      itemName: l10n.tableReservationName(service.localizedName(languageCode)),
      fontFamily: theme.tokens.bodyFontFamily,
      headlineFontFamily: theme.tokens.headlineFontFamily,
      primaryColor: theme.accent,
      backgroundColor: theme.bg,
      bodyTextColor: theme.mutedColor,
      confirmLabel: l10n.reserveButton,
      loadTableAvailability: (scheduledFor) => _repository.getTableAvailability(
        hotelId: _hotelId,
        serviceId: widget.serviceId,
        scheduledFor: scheduledFor,
      ),
    );
    if (result == null) return;
    if (!context.mounted) return;

    final guestToken = await _guestClaimRepository.getStoredToken();
    if (guestToken == null) {
      if (!context.mounted) return;
      _showSnackBar(
        context,
        message: l10n.reservationConfirmed,
        color: theme.accent,
      );
      return;
    }

    setState(() => _isReservingTable = true);
    try {
      await _ordersRepository.createTableReservation(
        serviceId: widget.serviceId,
        token: guestToken,
        scheduledFor: result.dateTime,
        tableTypeId: result.tableTypeId,
      );
      if (!context.mounted) return;
      _showSnackBar(
        context,
        message: l10n.reservationConfirmed,
        color: theme.accent,
      );
    } on StateError catch (error) {
      if (!context.mounted) return;
      _showSnackBar(
        context,
        message: error.message,
        color: Colors.red.shade700,
      );
    } finally {
      if (mounted) setState(() => _isReservingTable = false);
    }
  }

  void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color color,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: theme.body(color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: FutureBuilder<Service>(
          future: _serviceFuture,
          builder: (context, snapshot) {
            final l10n = AppLocalizations.of(context)!;
            final languageCode = Localizations.localeOf(context).languageCode;
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Text(
                  l10n.serviceLoadError,
                  style: theme.body(color: theme.mutedColor),
                ),
              );
            }

            final service = snapshot.data!;
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
                        child: Text(
                          service.localizedName(languageCode),
                          style: theme.headline(fontSize: 22),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: service.items.isEmpty
                      ? Center(
                          child: Text(
                            l10n.serviceItemsEmpty,
                            style: theme.body(color: theme.mutedColor),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: service.items.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = service.items[index];
                            return _ItemCard(
                              item: item,
                              hotelId: _hotelId,
                              theme: theme,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ServiceItemDetailPage(
                                      tenantConfig: widget.tenantConfig,
                                      serviceId: widget.serviceId,
                                      serviceName: service.localizedName(
                                        languageCode,
                                      ),
                                      serviceType: service.type,
                                      service: service,
                                      item: item,
                                      hotelId: _hotelId,
                                      theme: theme,
                                      // Mesmo item pode existir tanto no
                                      // cardápio de Serviço de Quarto quanto
                                      // no Frigobar — aqui é sempre pedido
                                      // normal (vai pro preparo), nunca
                                      // autoinformação de consumo.
                                      isMinibarReportFlow: false,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
                if (service.type == ServiceType.restaurant)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isReservingTable
                            ? null
                            : () => _reserveTable(context, service),
                        icon: _isReservingTable
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.table_bar_outlined, size: 20),
                        label: Text(
                          l10n.reserveTable,
                          style: theme.body(fontSize: 16, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              theme.tokens.cardRadius,
                            ),
                          ),
                        ),
                      ),
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

class _ItemCard extends StatelessWidget {
  final ServiceItem item;
  final String hotelId;
  final GuestAppTheme theme;
  final VoidCallback onTap;

  const _ItemCard({
    required this.item,
    required this.hotelId,
    required this.theme,
    required this.onTap,
  });

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
                    style: theme.headline(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.localizedDescription(languageCode),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.body(
                      fontSize: 12.5,
                      color: theme.mutedColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.price != null
                        ? 'R\$ ${item.price!.toStringAsFixed(2)}'
                        : l10n.priceOnRequest,
                    style: theme.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.accent,
                    ),
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
