import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konekto/app/tenants/booking_sheet.dart';
import 'package:konekto/app/tenants/order_quantity_note_sheet.dart';
import 'package:konekto/app/tenants/services_page.dart' show hexToColor;
import 'package:konekto/data/guest_claim_repository.dart';
import 'package:konekto/data/orders_repository.dart';
import 'package:konekto/models/service.dart';
import 'package:konekto/widgets/tenant_image.dart';

/// Detalhe de um item de serviço — substitui as 5 telas antigas de detalhe
/// (room_service_detail, spa_detail, restaurant_detail, event_detail,
/// passeios_detail) por uma única tela genérica.
///
/// Comportamento escolhido por [serviceType]:
/// - **`roomService`**: [showOrderQuantityNoteSheet] (quantidade +
///   observação) — `item.price != null` mostra "Adicionar ao pedido",
///   `item.price == null` mostra "Solicitar".
/// - **`activity`** (spa, eventos, passeios): [showBookingSheet] (dia +
///   horário) — botão sempre "Reservar".
/// - **`restaurant`**: só informativo, sem botão — o cardápio é pra
///   consulta; a reserva é da MESA como um todo, feita pelo botão no
///   rodapé de `ServiceItemsListPage`, não item a item.
///
/// O seletor de "pessoa alocada no quarto" ainda não existe aqui — depende
/// da entidade Stay (reserva de quarto), planejada pra depois; por
/// enquanto a reserva sempre fica em nome de quem está logado.
///
/// Pedido real: faz um `POST /api/orders` de verdade usando o guest token
/// salvo em `GuestClaimRepository`. Só cai no SnackBar de simulação no modo
/// asset (`USE_API=false`, sem backend real pra vincular o pedido) — no
/// modo API (produção) o hóspede sempre tem token, já que a entrada no app
/// exige um claim bem-sucedido.
class ServiceItemDetailPage extends StatefulWidget {
  final Map<String, dynamic> tenantConfig;
  final String serviceId;
  final String serviceName;
  final ServiceType serviceType;
  final ServiceItem item;
  final String hotelId;

  const ServiceItemDetailPage({
    super.key,
    required this.tenantConfig,
    required this.serviceId,
    required this.serviceName,
    required this.serviceType,
    required this.item,
    required this.hotelId,
  });

  @override
  State<ServiceItemDetailPage> createState() => _ServiceItemDetailPageState();
}

class _ServiceItemDetailPageState extends State<ServiceItemDetailPage> {
  final GuestClaimRepository _guestClaimRepository = GuestClaimRepository();
  final OrdersRepository _ordersRepository = OrdersRepository();
  bool _isSubmitting = false;

  Map<String, dynamic> get tenantConfig => widget.tenantConfig;
  ServiceItem get item => widget.item;

  Future<void> _confirm(BuildContext context) async {
    switch (widget.serviceType) {
      case ServiceType.roomService:
        await _confirmOrder(context);
      case ServiceType.activity:
        await _confirmBooking(context);
      case ServiceType.restaurant:
        break;
    }
  }

  Future<void> _confirmOrder(BuildContext context) async {
    final String fontFamily = tenantConfig['typography']['fontFamily'];
    final Color primaryColor = hexToColor(tenantConfig['colorPalette']['primary']);
    final Color backgroundColor = hexToColor(tenantConfig['colorPalette']['background']);
    final Color bodyTextColor = hexToColor(tenantConfig['typography']['bodyText']['color']);
    final bool isPurchasable = item.price != null;

    final result = await showOrderQuantityNoteSheet(
      context,
      itemName: item.name,
      fontFamily: fontFamily,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      bodyTextColor: bodyTextColor,
      confirmLabel: isPurchasable ? 'Adicionar ao pedido' : 'Solicitar',
    );
    if (result == null) return;
    if (!context.mounted) return;

    await _submitOrder(
      context,
      quantity: result.quantity,
      note: result.note,
      successMessage: isPurchasable ? 'Pedido enviado! A recepção foi notificada.' : 'Solicitação enviada! A recepção entrará em contato.',
    );
  }

  Future<void> _confirmBooking(BuildContext context) async {
    final String fontFamily = tenantConfig['typography']['fontFamily'];
    final Color primaryColor = hexToColor(tenantConfig['colorPalette']['primary']);
    final Color backgroundColor = hexToColor(tenantConfig['colorPalette']['background']);
    final Color bodyTextColor = hexToColor(tenantConfig['typography']['bodyText']['color']);

    final result = await showBookingSheet(
      context,
      itemName: item.name,
      fontFamily: fontFamily,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      bodyTextColor: bodyTextColor,
    );
    if (result == null) return;
    if (!context.mounted) return;

    await _submitOrder(
      context,
      quantity: 1,
      scheduledFor: result.dateTime,
      successMessage: 'Reserva confirmada! A recepção foi notificada.',
    );
  }

  Future<void> _submitOrder(
    BuildContext context, {
    required int quantity,
    String? note,
    DateTime? scheduledFor,
    required String successMessage,
  }) async {
    final String fontFamily = tenantConfig['typography']['fontFamily'];
    final Color primaryColor = hexToColor(tenantConfig['colorPalette']['primary']);

    final guestToken = await _guestClaimRepository.getStoredToken();
    if (guestToken == null) {
      if (!context.mounted) return;
      _showSnackBar(context, message: successMessage, fontFamily: fontFamily, color: primaryColor);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _ordersRepository.createOrder(
        serviceId: widget.serviceId,
        serviceItemId: item.id,
        token: guestToken,
        quantity: quantity,
        note: note,
        scheduledFor: scheduledFor,
      );
      if (!context.mounted) return;
      _showSnackBar(context, message: successMessage, fontFamily: fontFamily, color: primaryColor);
    } on StateError catch (error) {
      if (!context.mounted) return;
      _showSnackBar(context, message: error.message, fontFamily: fontFamily, color: Colors.red.shade700);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
    final String fontFamily = tenantConfig['typography']['fontFamily'];
    final Color primaryColor = hexToColor(tenantConfig['colorPalette']['primary']);
    final Color backgroundColor = hexToColor(tenantConfig['colorPalette']['background']);
    final Color bodyTextColor = hexToColor(tenantConfig['typography']['bodyText']['color']);
    final bool isPurchasable = item.price != null;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 18, offset: Offset(0, 8))],
                  ),
                  child: TenantImage(
                    imageUrl: item.imageUrl,
                    hotelId: widget.hotelId,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: primaryColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.serviceName,
                    style: GoogleFonts.getFont(fontFamily, color: bodyTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    style: GoogleFonts.getFont(fontFamily, color: primaryColor, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPurchasable ? 'R\$ ${item.price!.toStringAsFixed(2)}' : 'Sob consulta',
                    style: GoogleFonts.getFont(fontFamily, color: bodyTextColor, fontSize: 17, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.description,
                    style: GoogleFonts.getFont(fontFamily, color: bodyTextColor, fontSize: 15, height: 1.5),
                  ),
                  if (item.location != null) ...[
                    const SizedBox(height: 16),
                    _DetailRow(icon: Icons.place_outlined, label: item.location!, color: primaryColor, fontFamily: fontFamily),
                  ],
                  if (item.category != null) ...[
                    const SizedBox(height: 8),
                    _DetailRow(icon: Icons.category_outlined, label: item.category!, color: primaryColor, fontFamily: fontFamily),
                  ],
                  if (item.extraInfo != null) ...[
                    const SizedBox(height: 8),
                    _DetailRow(icon: Icons.info_outline, label: item.extraInfo!, color: primaryColor, fontFamily: fontFamily),
                  ],
                  if (widget.serviceType != ServiceType.restaurant) ...[
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : () => _confirm(context),
                        icon: _isSubmitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Icon(
                                widget.serviceType == ServiceType.roomService
                                    ? (isPurchasable ? Icons.shopping_cart : Icons.event_available_outlined)
                                    : Icons.calendar_month_outlined,
                                size: 22,
                              ),
                        label: Text(
                          widget.serviceType == ServiceType.roomService
                              ? (isPurchasable ? 'Adicionar ao pedido' : 'Solicitar')
                              : 'Reservar',
                          style: GoogleFonts.getFont(fontFamily, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String fontFamily;

  const _DetailRow({required this.icon, required this.label, required this.color, required this.fontFamily});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: GoogleFonts.getFont(fontFamily, color: color, fontSize: 13.5, fontWeight: FontWeight.w500))),
      ],
    );
  }
}
