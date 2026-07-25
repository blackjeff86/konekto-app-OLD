import 'package:flutter/material.dart';
import 'package:konekto/data/stay_bill_repository.dart';
import 'package:konekto/l10n/app_localizations.dart';
import 'package:konekto/payments/pagarme_card_form_view.dart';
import 'package:konekto/payments/pagarme_script_loader.dart';
import 'package:konekto/payments/pagarme_tokenizer.dart';
import 'package:konekto/theme/guest_app_theme.dart';

/// Modal de pagamento com cartão — tokeniza via `tokenizecard.js` do
/// Pagar.me (nunca manda dado de cartão bruto pro nosso backend) e paga o
/// saldo em aberto da conta da estadia. Devolve `true` se o pagamento foi
/// concluído com sucesso.
Future<bool?> showCardPaymentSheet(
  BuildContext context, {
  required GuestAppTheme theme,
  required double amount,
  required String guestToken,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _CardPaymentSheet(theme: theme, amount: amount, guestToken: guestToken),
  );
}

class _CardPaymentSheet extends StatefulWidget {
  final GuestAppTheme theme;
  final double amount;
  final String guestToken;

  const _CardPaymentSheet({required this.theme, required this.amount, required this.guestToken});

  @override
  State<_CardPaymentSheet> createState() => _CardPaymentSheetState();
}

class _CardPaymentSheetState extends State<_CardPaymentSheet> {
  static const _formElementId = 'pagarme-stay-bill-card-form';

  final _repository = StayBillRepository();
  bool _isScriptReady = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadScript();
  }

  Future<void> _loadScript() async {
    try {
      await loadPagarmeScript();
      if (mounted) setState(() => _isScriptReady = true);
    } on StateError catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _confirm() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final cardToken = await PagarmeTokenizer.instance.tokenize(_formElementId);
      await _repository.payBill(token: widget.guestToken, cardToken: cardToken);
      if (mounted) Navigator.of(context).pop(true);
    } on StateError catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = widget.theme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(color: theme.bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(color: theme.mutedColor.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(l10n.payStayBillTitle, style: theme.headline(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                l10n.payStayBillAmount('R\$ ${widget.amount.toStringAsFixed(2)}'),
                style: theme.body(fontSize: 15, fontWeight: FontWeight.w600, color: theme.accent),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_errorMessage!, style: theme.body(fontSize: 13, color: Colors.red.shade700)),
                ),
                const SizedBox(height: 16),
              ],
              if (!_isScriptReady && _errorMessage == null)
                const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24), child: CircularProgressIndicator()))
              else if (_isScriptReady)
                PagarmeCardFormView(
                  formElementId: _formElementId,
                  accentColor: theme.accent,
                  textColor: theme.textColor,
                  mutedColor: theme.mutedColor,
                  fontFamily: theme.tokens.bodyFontFamily,
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isScriptReady && !_isSubmitting) ? _confirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.tokens.cardRadius)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n.confirmPayment, style: theme.body(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
