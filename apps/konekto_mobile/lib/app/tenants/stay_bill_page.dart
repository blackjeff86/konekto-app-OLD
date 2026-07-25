import 'package:flutter/material.dart';
import 'package:konekto/app/tenants/card_payment_sheet.dart';
import 'package:konekto/data/guest_claim_repository.dart';
import 'package:konekto/data/stay_bill_repository.dart';
import 'package:konekto/l10n/app_localizations.dart';
import 'package:konekto/models/stay_bill.dart';
import 'package:konekto/theme/guest_app_theme.dart';

/// "Minha conta" — conta consolidada da estadia (todos os pedidos não
/// cancelados do quarto, menos o que já foi pago) com opção de pagar tudo
/// de uma vez com cartão de crédito.
class StayBillPage extends StatefulWidget {
  final GuestAppTheme theme;

  const StayBillPage({super.key, required this.theme});

  @override
  State<StayBillPage> createState() => _StayBillPageState();
}

class _StayBillPageState extends State<StayBillPage> {
  final _guestClaimRepository = GuestClaimRepository();
  final _repository = StayBillRepository();

  bool _isLoading = true;
  String? _errorMessage;
  StayBill? _bill;

  GuestAppTheme get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String?> _requireToken() async {
    final l10n = AppLocalizations.of(context)!;
    final token = await _guestClaimRepository.getStoredToken();
    if (token == null && mounted) {
      setState(() {
        _errorMessage = l10n.sessionNotFound;
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
      final bill = await _repository.getBill(token);
      if (!mounted) return;
      setState(() {
        _bill = bill;
        _errorMessage = null;
      });
    } on StateError catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pay() async {
    final bill = _bill;
    if (bill == null || bill.balanceDue <= 0) return;

    final token = await _requireToken();
    if (token == null) return;
    if (!mounted) return;

    final paid = await showCardPaymentSheet(context, theme: theme, amount: bill.balanceDue, guestToken: token);
    if (paid == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.paymentSuccess)));
      }
      await _load();
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
                  Expanded(child: Text(l10n.stayBillTitle, style: theme.headline(fontSize: 22))),
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
    if (_errorMessage != null && _bill == null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(child: Text(_errorMessage!, textAlign: TextAlign.center, style: theme.body(color: theme.mutedColor))),
        ],
      );
    }

    final bill = _bill!;
    if (!bill.onlinePaymentAvailable) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(shape: BoxShape.circle, color: theme.accentSoft),
              child: Icon(Icons.credit_card_off_outlined, size: 40, color: theme.accent),
            ),
          ),
          const SizedBox(height: 20),
          Text(l10n.stayBillPaymentUnavailable, textAlign: TextAlign.center, style: theme.headline(fontSize: 18)),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(theme.tokens.cardRadius),
            boxShadow: theme.tokens.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.stayBillBalanceDue, style: theme.body(color: theme.mutedColor, fontSize: 13)),
              const SizedBox(height: 6),
              Text('R\$ ${bill.balanceDue.toStringAsFixed(2)}', style: theme.headline(fontSize: 32, fontWeight: FontWeight.bold)),
              if (bill.balanceDue > 0) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _pay,
                    icon: const Icon(Icons.credit_card_outlined, size: 20),
                    label: Text(l10n.payNow, style: theme.body(fontSize: 16, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.tokens.cardRadius)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(l10n.stayBillOrders, style: theme.headline(fontSize: 16)),
        const SizedBox(height: 12),
        if (bill.orders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(l10n.noOrdersYet, style: theme.body(color: theme.mutedColor)),
          )
        else
          for (final order in bill.orders) ...[
            _StayBillOrderRow(order: order, theme: theme),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _StayBillOrderRow extends StatelessWidget {
  final StayBillOrder order;
  final GuestAppTheme theme;

  const _StayBillOrderRow({required this.order, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(theme.tokens.cardRadius),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${order.itemName}${order.quantity > 1 ? ' ×${order.quantity}' : ''}',
              style: theme.body(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            'R\$ ${(order.price * order.quantity).toStringAsFixed(2)}',
            style: theme.body(fontSize: 14, fontWeight: FontWeight.w600, color: theme.accent),
          ),
        ],
      ),
    );
  }
}
