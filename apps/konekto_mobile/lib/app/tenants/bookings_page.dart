import 'package:flutter/material.dart';
import 'package:konekto/app/tenants/booking_sheet.dart';
import 'package:konekto/app/tenants/order_card.dart';
import 'package:konekto/data/guest_claim_repository.dart';
import 'package:konekto/data/orders_repository.dart';
import 'package:konekto/l10n/app_localizations.dart';
import 'package:konekto/models/guest_order.dart';
import 'package:konekto/theme/guest_app_theme.dart';

/// Aba "Reservas" — mesmos pedidos de `MyOrdersPage`, mas só os que têm
/// `scheduledFor` (spa, eventos, passeios, reserva de mesa em restaurante).
/// Pedidos simples de Serviço de Quarto (sem agendamento) não aparecem
/// aqui — esses ficam em "Meus Pedidos"/Histórico.
class BookingsPage extends StatefulWidget {
  final Map<String, dynamic> tenantConfig;
  final GuestAppTheme theme;
  final VoidCallback? onExploreServices;

  const BookingsPage({super.key, required this.tenantConfig, required this.theme, this.onExploreServices});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  final GuestClaimRepository _guestClaimRepository = GuestClaimRepository();
  final OrdersRepository _ordersRepository = OrdersRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<GuestOrder> _bookings = const [];

  GuestAppTheme get theme => widget.theme;

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
        _bookings = orders.where((order) => order.isBooking).toList();
        _errorMessage = null;
      });
    } on StateError catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editBooking(GuestOrder order) async {
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

  Future<void> _cancelBooking(GuestOrder order) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelBookingTitle),
        content: Text(l10n.cancelOrderConfirm(order.itemName)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.dialogBack)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.cancelBookingAction)),
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
    return RefreshIndicator(onRefresh: _load, child: _buildBody(l10n));
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null && _bookings.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(child: Text(_errorMessage!, textAlign: TextAlign.center, style: theme.body(color: theme.mutedColor))),
        ],
      );
    }
    if (_bookings.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(shape: BoxShape.circle, color: theme.accentSoft),
              child: Icon(Icons.event_note_rounded, size: 44, color: theme.accent),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.noBookingsYet, textAlign: TextAlign.center, style: theme.headline(fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            l10n.noBookingsDescription,
            textAlign: TextAlign.center,
            style: theme.body(fontSize: 14, color: theme.mutedColor, height: 1.4),
          ),
          if (widget.onExploreServices != null) ...[
            const SizedBox(height: 28),
            Center(
              child: ElevatedButton.icon(
                onPressed: widget.onExploreServices,
                icon: const Icon(Icons.explore_outlined),
                label: Text(l10n.exploreServices, style: theme.body(fontWeight: FontWeight.w600, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.tokens.cardRadius)),
                ),
              ),
            ),
          ],
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _bookings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => OrderCard(
        order: _bookings[index],
        theme: theme,
        onEdit: () => _editBooking(_bookings[index]),
        onCancel: () => _cancelBooking(_bookings[index]),
      ),
    );
  }
}
