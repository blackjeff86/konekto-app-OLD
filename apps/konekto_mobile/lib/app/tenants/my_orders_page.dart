import 'dart:async';

import 'package:flutter/material.dart';
import 'package:konekto/app/tenants/booking_sheet.dart';
import 'package:konekto/app/tenants/order_card.dart';
import 'package:konekto/app/tenants/order_quantity_note_sheet.dart';
import 'package:konekto/data/guest_claim_repository.dart';
import 'package:konekto/data/orders_repository.dart';
import 'package:konekto/data/tenant_repository.dart';
import 'package:konekto/data/tenant_repository_provider.dart';
import 'package:konekto/l10n/app_localizations.dart';
import 'package:konekto/models/guest_order.dart';
import 'package:konekto/models/service.dart' as models;
import 'package:konekto/theme/guest_app_theme.dart';

/// Tela "Meus Pedidos" — atalho a partir do bloco "Histórico" na tela
/// inicial. Mostra todos os pedidos do hóspede (de qualquer serviço, não
/// só room service) com o status atual, permite editar
/// quantidade/observação ou cancelar enquanto o pedido ainda estiver
/// `pending`, e um botão pra voltar e pedir mais itens.
class MyOrdersPage extends StatefulWidget {
  final Map<String, dynamic> tenantConfig;
  final GuestAppTheme theme;

  const MyOrdersPage({super.key, required this.tenantConfig, required this.theme});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  final GuestClaimRepository _guestClaimRepository = GuestClaimRepository();
  final OrdersRepository _ordersRepository = OrdersRepository();
  final TenantRepository _tenantRepository = createTenantRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<GuestOrder> _orders = const [];

  GuestAppTheme get theme => widget.theme;
  String get _hotelId => widget.tenantConfig['id'] ?? 'hotel_1';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String?> _requireToken() async {
    final token = await _guestClaimRepository.getStoredToken();
    if (token == null && mounted) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.sessionNotFound;
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
      unawaited(_ordersRepository.markStatusSeen(token: token));
    } on StateError catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editOrder(GuestOrder order) async {
    final result = await showOrderQuantityNoteSheet(
      context,
      itemName: order.itemName,
      fontFamily: theme.tokens.bodyFontFamily,
      headlineFontFamily: theme.tokens.headlineFontFamily,
      primaryColor: theme.accent,
      backgroundColor: theme.bg,
      bodyTextColor: theme.mutedColor,
      initialQuantity: order.quantity,
      initialNote: order.note,
      confirmLabel: AppLocalizations.of(context)!.saveChanges,
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

  Future<List<TimeSlot>> _loadAvailability(GuestOrder order, DateTime date) async {
    final json = await _tenantRepository.getItemAvailability(
      hotelId: _hotelId,
      serviceId: order.serviceId,
      itemId: order.serviceItemId,
      date: date,
    );
    final rawSlots = json['slots'] as List<dynamic>? ?? const [];
    return rawSlots
        .map(
          (raw) => TimeSlot(
            time: (raw as Map<String, dynamic>)['time'] as String,
            available: raw['available'] as bool,
          ),
        )
        .toList();
  }

  Future<void> _editBooking(GuestOrder order) async {
    // Precisa saber se o item ainda tem agendamento configurado (pode ter
    // mudado desde que o pedido foi feito) pra decidir entre a grade de
    // horários disponíveis ou o seletor livre de sempre — mesma decisão
    // que `ServiceItemDetailPage` toma na hora de criar o pedido.
    bool schedulingEnabled = false;
    try {
      final serviceJson = await _tenantRepository.getService(_hotelId, order.serviceId);
      final service = models.Service.fromJson(serviceJson);
      final item = service.items.where((item) => item.id == order.serviceItemId).firstOrNull;
      schedulingEnabled = item?.durationMinutes != null;
    } on Exception {
      schedulingEnabled = false;
    }
    if (!mounted) return;

    final result = await showBookingSheet(
      context,
      itemName: order.itemName,
      fontFamily: theme.tokens.bodyFontFamily,
      headlineFontFamily: theme.tokens.headlineFontFamily,
      primaryColor: theme.accent,
      backgroundColor: theme.bg,
      bodyTextColor: theme.mutedColor,
      initialDateTime: order.scheduledFor,
      confirmLabel: AppLocalizations.of(context)!.saveChanges,
      schedulingEnabled: schedulingEnabled,
      loadAvailability: schedulingEnabled ? (date) => _loadAvailability(order, date) : null,
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(order.isBooking ? l10n.cancelBookingTitle : l10n.cancelOrderTitle),
        content: Text(l10n.cancelOrderConfirm(order.itemName)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.dialogBack)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(order.isBooking ? l10n.cancelBookingAction : l10n.cancelOrderAction),
          ),
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
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
                  Expanded(child: Text(l10n.myOrdersTitle, style: theme.headline(fontSize: 22))),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.add, color: theme.accent, size: 18),
                    label: Text(l10n.orderMore, style: theme.body(fontSize: 13, color: theme.accent)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(onRefresh: _load, child: _buildBody(l10n)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null && _orders.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text(_errorMessage!, textAlign: TextAlign.center, style: theme.body(color: theme.mutedColor)),
          ),
        ],
      );
    }
    if (_orders.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(child: Text(l10n.noOrdersYet, style: theme.body(color: theme.mutedColor))),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => OrderCard(
        order: _orders[index],
        theme: theme,
        onEdit: () => _orders[index].isBooking ? _editBooking(_orders[index]) : _editOrder(_orders[index]),
        onCancel: () => _cancelOrder(_orders[index]),
      ),
    );
  }
}
