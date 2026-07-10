import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konekto/app/tenants/booking_sheet.dart';
import 'package:konekto/app/tenants/service_item_detail_page.dart';
import 'package:konekto/app/tenants/services_page.dart' show hexToColor;
import 'package:konekto/data/guest_claim_repository.dart';
import 'package:konekto/data/orders_repository.dart';
import 'package:konekto/data/tenant_repository.dart';
import 'package:konekto/data/tenant_repository_provider.dart';
import 'package:konekto/models/service.dart';
import 'package:konekto/widgets/tenant_image.dart';

/// Lista de itens de um serviço (cardápio de room service, tratamentos de
/// spa, cardápio de um restaurante, eventos, passeios, ou qualquer serviço
/// que o hotel tenha criado) — substitui as 5 telas antigas de lista
/// (room_service_page, spa_services_list, restaurant_list_page,
/// eventos_page, passeios_page) por uma única tela genérica.
class ServiceItemsListPage extends StatefulWidget {
  final Map<String, dynamic> tenantConfig;
  final String serviceId;

  const ServiceItemsListPage({super.key, required this.tenantConfig, required this.serviceId});

  @override
  State<ServiceItemsListPage> createState() => _ServiceItemsListPageState();
}

class _ServiceItemsListPageState extends State<ServiceItemsListPage> {
  final TenantRepository _repository = createTenantRepository();
  final GuestClaimRepository _guestClaimRepository = GuestClaimRepository();
  final OrdersRepository _ordersRepository = OrdersRepository();
  late final Future<Service> _serviceFuture;
  bool _isReservingTable = false;

  String get _hotelId => widget.tenantConfig['id'] ?? 'hotel_1';

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
    final String fontFamily = widget.tenantConfig['typography']['fontFamily'];
    final Color primaryColor = hexToColor(widget.tenantConfig['colorPalette']['primary']);
    final Color backgroundColor = hexToColor(widget.tenantConfig['colorPalette']['background']);
    final Color bodyTextColor = hexToColor(widget.tenantConfig['typography']['bodyText']['color']);

    final result = await showBookingSheet(
      context,
      itemName: 'Mesa em ${service.name}',
      fontFamily: fontFamily,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      bodyTextColor: bodyTextColor,
      confirmLabel: 'Reservar mesa',
    );
    if (result == null) return;
    if (!context.mounted) return;

    final guestToken = await _guestClaimRepository.getStoredToken();
    if (guestToken == null) {
      if (!context.mounted) return;
      _showSnackBar(context, message: 'Reserva confirmada! A recepção foi notificada.', fontFamily: fontFamily, color: primaryColor);
      return;
    }

    setState(() => _isReservingTable = true);
    try {
      await _ordersRepository.createTableReservation(serviceId: widget.serviceId, token: guestToken, scheduledFor: result.dateTime);
      if (!context.mounted) return;
      _showSnackBar(context, message: 'Reserva confirmada! A recepção foi notificada.', fontFamily: fontFamily, color: primaryColor);
    } on StateError catch (error) {
      if (!context.mounted) return;
      _showSnackBar(context, message: error.message, fontFamily: fontFamily, color: Colors.red.shade700);
    } finally {
      if (mounted) setState(() => _isReservingTable = false);
    }
  }

  void _showSnackBar(BuildContext context, {required String message, required String fontFamily, required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.getFont(fontFamily, color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String fontFamily = widget.tenantConfig['typography']['fontFamily'];
    final Color primaryColor = hexToColor(widget.tenantConfig['colorPalette']['primary']);
    final Color backgroundColor = hexToColor(widget.tenantConfig['colorPalette']['background']);
    final Color bodyTextColor = hexToColor(widget.tenantConfig['typography']['bodyText']['color']);
    final Color cardBackgroundColor = hexToColor(widget.tenantConfig['colorPalette']['cardBackground']);
    final Color cardBorderColor = hexToColor(widget.tenantConfig['colorPalette']['dividerColor']);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: FutureBuilder<Service>(
          future: _serviceFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text('Erro ao carregar o serviço.'));
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
                        icon: Icon(Icons.arrow_back, color: primaryColor),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          service.name,
                          style: GoogleFonts.getFont(fontFamily, color: primaryColor, fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: service.items.isEmpty
                      ? Center(
                          child: Text(
                            'Nenhum item disponível ainda.',
                            style: GoogleFonts.getFont(fontFamily, color: bodyTextColor, fontSize: 14),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: service.items.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = service.items[index];
                            return _ItemCard(
                              item: item,
                              hotelId: _hotelId,
                              fontFamily: fontFamily,
                              primaryColor: primaryColor,
                              bodyTextColor: bodyTextColor,
                              cardBackgroundColor: cardBackgroundColor,
                              cardBorderColor: cardBorderColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ServiceItemDetailPage(
                                      tenantConfig: widget.tenantConfig,
                                      serviceId: widget.serviceId,
                                      serviceName: service.name,
                                      serviceType: service.type,
                                      item: item,
                                      hotelId: _hotelId,
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
                        onPressed: _isReservingTable ? null : () => _reserveTable(context, service),
                        icon: _isReservingTable
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.table_bar_outlined, size: 20),
                        label: Text('Reservar mesa', style: GoogleFonts.getFont(fontFamily, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
  final String fontFamily;
  final Color primaryColor;
  final Color bodyTextColor;
  final Color cardBackgroundColor;
  final Color cardBorderColor;
  final VoidCallback onTap;

  const _ItemCard({
    required this.item,
    required this.hotelId,
    required this.fontFamily,
    required this.primaryColor,
    required this.bodyTextColor,
    required this.cardBackgroundColor,
    required this.cardBorderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorderColor.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(color: primaryColor.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            TenantImage(
              imageUrl: item.imageUrl,
              hotelId: hotelId,
              height: 68,
              width: 68,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.getFont(fontFamily, color: primaryColor, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.getFont(fontFamily, color: bodyTextColor, fontSize: 12.5, height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.price != null ? 'R\$ ${item.price!.toStringAsFixed(2)}' : 'Sob consulta',
                    style: GoogleFonts.getFont(fontFamily, color: primaryColor, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: primaryColor.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}
