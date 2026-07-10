import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konekto/app/tenants/services_page.dart' show hexToColor;
import 'package:konekto/data/guest_claim_repository.dart';
import 'package:konekto/data/orders_repository.dart';
import 'package:konekto/models/service.dart';
import 'package:konekto/widgets/tenant_image.dart';

/// Detalhe de um item de serviço — substitui as 5 telas antigas de detalhe
/// (room_service_detail, spa_detail, restaurant_detail, event_detail,
/// passeios_detail) por uma única tela genérica.
///
/// `item.price != null` → mostra preço e um botão "Adicionar ao pedido".
/// `item.price == null` → item não é comprável (evento/passeio/reserva) e
/// mostra "Solicitar" no lugar.
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
  final ServiceItem item;
  final String Function(String) assetPathBuilder;

  const ServiceItemDetailPage({
    super.key,
    required this.tenantConfig,
    required this.serviceId,
    required this.serviceName,
    required this.item,
    required this.assetPathBuilder,
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
    final String fontFamily = tenantConfig['typography']['fontFamily'];
    final Color primaryColor = hexToColor(tenantConfig['colorPalette']['primary']);
    final bool isPurchasable = item.price != null;

    final guestToken = await _guestClaimRepository.getStoredToken();
    if (guestToken == null) {
      if (!context.mounted) return;
      _showSnackBar(
        context,
        message: isPurchasable ? 'Pedido enviado! A recepção foi notificada.' : 'Solicitação enviada! A recepção entrará em contato.',
        fontFamily: fontFamily,
        color: primaryColor,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _ordersRepository.createOrder(serviceId: widget.serviceId, serviceItemId: item.id, token: guestToken);
      if (!context.mounted) return;
      _showSnackBar(
        context,
        message: isPurchasable ? 'Pedido enviado! A recepção foi notificada.' : 'Solicitação enviada! A recepção entrará em contato.',
        fontFamily: fontFamily,
        color: primaryColor,
      );
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
                    assetPathBuilder: widget.assetPathBuilder,
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
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : () => _confirm(context),
                      icon: _isSubmitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(isPurchasable ? Icons.shopping_cart : Icons.event_available_outlined, size: 22),
                      label: Text(
                        isPurchasable ? 'Adicionar ao pedido' : 'Solicitar',
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
