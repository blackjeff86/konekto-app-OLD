import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konekto/app/tenants/services_page.dart' show hexToColor;
import 'package:konekto/models/service.dart';
import 'package:konekto/widgets/tenant_image.dart';

/// Detalhe de um item de serviço — substitui as 5 telas antigas de detalhe
/// (room_service_detail, spa_detail, restaurant_detail, event_detail,
/// passeios_detail) por uma única tela genérica.
///
/// `item.price != null` → mostra preço e um botão "Adicionar ao pedido".
/// `item.price == null` → item não é comprável (evento/passeio/reserva) e
/// mostra "Solicitar" no lugar. Pedidos reais (gravados no backend) ainda
/// não existem — ver `specs/portal-fase5-hospedes-pedidos-config.md`, fase
/// "Pedidos" — por enquanto ambos os botões só confirmam com um SnackBar,
/// preservando o comportamento de simulação que as telas antigas já tinham.
class ServiceItemDetailPage extends StatelessWidget {
  final Map<String, dynamic> tenantConfig;
  final String serviceName;
  final ServiceItem item;
  final String Function(String) assetPathBuilder;

  const ServiceItemDetailPage({
    super.key,
    required this.tenantConfig,
    required this.serviceName,
    required this.item,
    required this.assetPathBuilder,
  });

  void _confirm(BuildContext context) {
    final String fontFamily = tenantConfig['typography']['fontFamily'];
    final Color primaryColor = hexToColor(tenantConfig['colorPalette']['primary']);
    final bool isPurchasable = item.price != null;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPurchasable ? 'Pedido enviado! A recepção foi notificada.' : 'Solicitação enviada! A recepção entrará em contato.',
          style: GoogleFonts.getFont(fontFamily, color: Colors.white),
        ),
        backgroundColor: primaryColor,
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
                    assetPathBuilder: assetPathBuilder,
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
                    serviceName,
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
                      onPressed: () => _confirm(context),
                      icon: Icon(isPurchasable ? Icons.shopping_cart : Icons.event_available_outlined, size: 22),
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
