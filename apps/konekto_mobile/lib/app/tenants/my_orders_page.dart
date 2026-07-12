import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konekto/app/tenants/booking_sheet.dart';
import 'package:konekto/app/tenants/order_quantity_note_sheet.dart';
import 'package:konekto/app/tenants/services_page.dart' show hexToColor;
import 'package:konekto/data/guest_claim_repository.dart';
import 'package:konekto/data/orders_repository.dart';
import 'package:konekto/models/guest_order.dart';

/// Tela "Meus Pedidos" — atalho a partir do card de Serviço de Quarto na
/// tela inicial. Mostra todos os pedidos do hóspede (de qualquer serviço,
/// não só room service) com o status atual, permite editar
/// quantidade/observação ou cancelar enquanto o pedido ainda estiver
/// `pending`, e um botão pra voltar e pedir mais itens.
class MyOrdersPage extends StatefulWidget {
  final Map<String, dynamic> tenantConfig;

  const MyOrdersPage({super.key, required this.tenantConfig});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  final GuestClaimRepository _guestClaimRepository = GuestClaimRepository();
  final OrdersRepository _ordersRepository = OrdersRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<GuestOrder> _orders = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String?> _requireToken() async {
    final token = await _guestClaimRepository.getStoredToken();
    if (token == null && mounted) {
      setState(() {
        _errorMessage = 'Não foi possível identificar sua sessão.';
        _isLoading = false;
      });
    }
    return token;
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final token = await _requireToken();
    if (token == null) return;
    try {
      final orders = await _ordersRepository.getMyOrders(token: token);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _errorMessage = null;
      });
    } on StateError catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editOrder(GuestOrder order) async {
    final String fontFamily = widget.tenantConfig['typography']['fontFamily'];
    final Color primaryColor = hexToColor(widget.tenantConfig['colorPalette']['primary']);
    final Color backgroundColor = hexToColor(widget.tenantConfig['colorPalette']['background']);
    final Color bodyTextColor = hexToColor(widget.tenantConfig['typography']['bodyText']['color']);

    final result = await showOrderQuantityNoteSheet(
      context,
      itemName: order.itemName,
      fontFamily: fontFamily,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      bodyTextColor: bodyTextColor,
      initialQuantity: order.quantity,
      initialNote: order.note,
      confirmLabel: 'Salvar alterações',
    );
    if (result == null) return;

    final token = await _requireToken();
    if (token == null) return;
    try {
      await _ordersRepository.updateOrder(
        orderId: order.id,
        token: token,
        quantity: result.quantity,
        note: result.note ?? '',
      );
      await _load();
    } on StateError catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _editBooking(GuestOrder order) async {
    final String fontFamily = widget.tenantConfig['typography']['fontFamily'];
    final Color primaryColor = hexToColor(widget.tenantConfig['colorPalette']['primary']);
    final Color backgroundColor = hexToColor(widget.tenantConfig['colorPalette']['background']);
    final Color bodyTextColor = hexToColor(widget.tenantConfig['typography']['bodyText']['color']);

    final result = await showBookingSheet(
      context,
      itemName: order.itemName,
      fontFamily: fontFamily,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      bodyTextColor: bodyTextColor,
      initialDateTime: order.scheduledFor,
      confirmLabel: 'Salvar alterações',
    );
    if (result == null) return;

    final token = await _requireToken();
    if (token == null) return;
    try {
      await _ordersRepository.updateOrder(orderId: order.id, token: token, scheduledFor: result.dateTime);
      await _load();
    } on StateError catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _cancelOrder(GuestOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar pedido?'),
        content: Text('Tem certeza que deseja cancelar "${order.itemName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Voltar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Cancelar pedido')),
        ],
      ),
    );
    if (confirmed != true) return;

    final token = await _requireToken();
    if (token == null) return;
    try {
      await _ordersRepository.cancelOrder(orderId: order.id, token: token);
      await _load();
    } on StateError catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    }
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
        child: Column(
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
                      'Meus Pedidos',
                      style: GoogleFonts.getFont(fontFamily, color: primaryColor, fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.add, color: primaryColor, size: 18),
                    label: Text('Pedir mais', style: GoogleFonts.getFont(fontFamily, color: primaryColor, fontSize: 13)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _buildBody(fontFamily, primaryColor, bodyTextColor, cardBackgroundColor, cardBorderColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    String fontFamily,
    Color primaryColor,
    Color bodyTextColor,
    Color cardBackgroundColor,
    Color cardBorderColor,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null && _orders.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.getFont(fontFamily, color: bodyTextColor, fontSize: 14),
            ),
          ),
        ],
      );
    }
    if (_orders.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text(
              'Você ainda não fez nenhum pedido.',
              style: GoogleFonts.getFont(fontFamily, color: bodyTextColor, fontSize: 14),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _OrderCard(
        order: _orders[index],
        fontFamily: fontFamily,
        primaryColor: primaryColor,
        bodyTextColor: bodyTextColor,
        cardBackgroundColor: cardBackgroundColor,
        cardBorderColor: cardBorderColor,
        onEdit: () => _orders[index].isBooking ? _editBooking(_orders[index]) : _editOrder(_orders[index]),
        onCancel: () => _cancelOrder(_orders[index]),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final GuestOrder order;
  final String fontFamily;
  final Color primaryColor;
  final Color bodyTextColor;
  final Color cardBackgroundColor;
  final Color cardBorderColor;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  const _OrderCard({
    required this.order,
    required this.fontFamily,
    required this.primaryColor,
    required this.bodyTextColor,
    required this.cardBackgroundColor,
    required this.cardBorderColor,
    required this.onEdit,
    required this.onCancel,
  });

  String _formatScheduledFor(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month às $hour:$minute';
  }

  Color get _statusColor => switch (order.status) {
        GuestOrderStatus.pending => const Color(0xFFCB9A3E),
        GuestOrderStatus.inProgress => const Color(0xFF5B9BD5),
        GuestOrderStatus.completed => const Color(0xFF5CB85C),
        GuestOrderStatus.cancelled => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorderColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: primaryColor.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${order.itemName}${order.quantity > 1 ? ' ×${order.quantity}' : ''}',
                  style: GoogleFonts.getFont(fontFamily, color: primaryColor, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
                child: Text(
                  order.status.label,
                  style: GoogleFonts.getFont(fontFamily, color: _statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            order.price != null ? 'R\$ ${(order.price! * order.quantity).toStringAsFixed(2)}' : 'Sob consulta',
            style: GoogleFonts.getFont(fontFamily, color: bodyTextColor, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          if (order.scheduledFor != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.event_outlined, size: 14, color: primaryColor),
                const SizedBox(width: 6),
                Text(
                  _formatScheduledFor(order.scheduledFor!),
                  style: GoogleFonts.getFont(fontFamily, color: primaryColor, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
          if (order.note != null && order.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Obs: ${order.note}',
              style: GoogleFonts.getFont(fontFamily, color: bodyTextColor, fontSize: 12.5, fontStyle: FontStyle.italic),
            ),
          ],
          if (order.couponTitle != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.local_offer_outlined, size: 14, color: primaryColor),
                const SizedBox(width: 6),
                Text(
                  '${order.couponTitle} aplicado (-R\$ ${order.discountAmount?.toStringAsFixed(2) ?? '0.00'})',
                  style: GoogleFonts.getFont(fontFamily, color: primaryColor, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
          if (order.status.isEditableByGuest) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined, size: 16, color: primaryColor),
                  label: Text('Editar', style: GoogleFonts.getFont(fontFamily, color: primaryColor, fontSize: 12.5)),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: onCancel,
                  icon: Icon(Icons.close, size: 16, color: Colors.red.shade400),
                  label: Text('Cancelar', style: GoogleFonts.getFont(fontFamily, color: Colors.red.shade400, fontSize: 12.5)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
