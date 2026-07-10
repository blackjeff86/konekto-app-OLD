import 'dart:async';
import 'package:flutter/material.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/orders_repository.dart';
import 'package:konekto_portal/models/order.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

const Duration _kPollInterval = Duration(seconds: 5);

/// Tela "Pedidos" — lista os pedidos dos hóspedes (qualquer item de
/// qualquer serviço, sem distinção por tipo) com polling a cada 5s
/// enquanto a aba está aberta, e permite avançar o status.
class OrdersPage extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const OrdersPage({super.key, required this.session, required this.authRepository});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final _repository = OrdersRepository();
  Timer? _pollTimer;

  bool _isLoading = true;
  String? _errorMessage;
  List<Order> _orders = const [];

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(_kPollInterval, (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<String?> _requireToken() async {
    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(() => _errorMessage = 'Sessão expirada — saia e entre novamente.');
    }
    return token;
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    final token = await _requireToken();
    if (token == null) {
      if (!silent) setState(() => _isLoading = false);
      return;
    }
    try {
      final orders = await _repository.listOrders(hotelId: widget.session.hotelId, token: token);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _errorMessage = null;
      });
    } on StateError catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(Order order, OrderStatus status) async {
    final token = await _requireToken();
    if (token == null) return;
    try {
      await _repository.updateStatus(hotelId: widget.session.hotelId, orderId: order.id, token: token, status: status);
      await _load(silent: true);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: KonektoBrand.gold));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pedidos', style: KonektoBrand.display(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            'Atualiza automaticamente a cada 5 segundos.',
            style: KonektoBrand.body(fontSize: 12.5),
          ),
          const SizedBox(height: 20),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x1ADC2626),
                border: Border.all(color: const Color(0x4DDC2626)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_errorMessage!, style: KonektoBrand.body(fontSize: 12.5, color: const Color(0xFFF1A6A0))),
            ),
            const SizedBox(height: 16),
          ],
          if (_orders.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: KonektoBrand.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KonektoBrand.borderStrong),
              ),
              child: Text('Nenhum pedido ainda.', style: KonektoBrand.body(fontSize: 13.5)),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: KonektoBrand.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KonektoBrand.borderStrong),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final order in _orders) ...[
                    if (order != _orders.first) const Divider(height: 1, color: KonektoBrand.borderStrong),
                    _OrderRow(order: order, onStatusChange: (status) => _updateStatus(order, status)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final Order order;
  final ValueChanged<OrderStatus> onStatusChange;

  const _OrderRow({required this.order, required this.onStatusChange});

  String _formatScheduledFor(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month às $hour:$minute';
  }

  Color _statusColor() {
    return switch (order.status) {
      OrderStatus.pending => KonektoBrand.gold,
      OrderStatus.inProgress => const Color(0xFF5B9BD5),
      OrderStatus.completed => const Color(0xFF5CB85C),
      OrderStatus.cancelled => KonektoBrand.slateSoft,
    };
  }

  List<OrderStatus> _nextStatusOptions() {
    return switch (order.status) {
      OrderStatus.pending => [OrderStatus.inProgress, OrderStatus.cancelled],
      OrderStatus.inProgress => [OrderStatus.completed, OrderStatus.cancelled],
      OrderStatus.completed => [],
      OrderStatus.cancelled => [],
    };
  }

  @override
  Widget build(BuildContext context) {
    final options = _nextStatusOptions();
    final color = _statusColor();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order.itemName}${order.quantity > 1 ? ' ×${order.quantity}' : ''}',
                  style: KonektoBrand.body(fontSize: 14, fontWeight: FontWeight.w700, color: KonektoBrand.cream),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.guestName} · Quarto ${order.guestRoomNumber}'
                  '${order.price != null ? ' · R\$ ${(order.price! * order.quantity).toStringAsFixed(2)}' : ' · Sob consulta'}',
                  style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate),
                ),
                if (order.scheduledFor != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Agendado: ${_formatScheduledFor(order.scheduledFor!)}',
                    style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.gold, fontWeight: FontWeight.w600),
                  ),
                ],
                if (order.note != null && order.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Obs: ${order.note}',
                    style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.gold).copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
            child: Text(
              order.status.label,
              style: KonektoBrand.body(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
          ),
          if (options.isNotEmpty) ...[
            const SizedBox(width: 8),
            PopupMenuButton<OrderStatus>(
              color: KonektoBrand.surface,
              icon: const Icon(Icons.more_vert, size: 18, color: KonektoBrand.slate),
              onSelected: onStatusChange,
              itemBuilder: (context) => [
                for (final option in options)
                  PopupMenuItem(value: option, child: Text(option.label, style: KonektoBrand.body(fontSize: 13, color: KonektoBrand.cream))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
