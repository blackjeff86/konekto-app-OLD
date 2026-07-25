import 'package:flutter/material.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/payment_repository.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

/// Pagamento online da conta da estadia (marketplace/split via Pagar.me).
/// O KYC completo (pessoa física/jurídica, conta bancária) é feito pelo
/// hotel direto no onboarding do próprio Pagar.me — aqui só colamos e
/// validamos o Recipient ID resultante, sem reconstruir o formulário de
/// compliance deles.
class PaymentsSection extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const PaymentsSection({
    super.key,
    required this.session,
    required this.authRepository,
  });

  @override
  State<PaymentsSection> createState() => _PaymentsSectionState();
}

class _PaymentsSectionState extends State<PaymentsSection> {
  final _repository = PaymentRepository();
  final _recipientIdController = TextEditingController();

  PaymentAccountStatus _status = PaymentAccountStatus.notConfigured;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _recipientIdController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(() {
        _errorMessage = 'Sessão expirada — saia e entre novamente.';
        _isLoading = false;
      });
      return;
    }
    try {
      final account = await _repository.getAccount(
        hotelId: widget.session.hotelId,
        token: token,
      );
      _status = account.status;
      _recipientIdController.text = account.recipientId ?? '';
    } on StateError catch (error) {
      _errorMessage = error.message;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final recipientId = _recipientIdController.text.trim();
    if (recipientId.isEmpty) {
      setState(() => _errorMessage = 'Cole o Recipient ID do Pagar.me.');
      return;
    }
    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(
        () => _errorMessage = 'Sessão expirada — saia e entre novamente.',
      );
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final account = await _repository.setRecipientId(
        hotelId: widget.session.hotelId,
        token: token,
        recipientId: recipientId,
      );
      setState(() => _status = account.status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados de pagamento salvos.')),
        );
      }
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: KonektoBrand.gold),
      );
    }

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: KonektoBrand.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: KonektoBrand.borderStrong),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pagamento online',
                style: KonektoBrand.display(fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                'Permite o hóspede pagar a conta da estadia com cartão de crédito de dentro do app. '
                'Crie a conta de recebedor no onboarding do Pagar.me (dashboard.pagar.me) e cole aqui o Recipient ID.',
                style: KonektoBrand.body(fontSize: 12.5),
              ),
              const SizedBox(height: 20),
              _StatusBadge(status: _status),
              const SizedBox(height: 20),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x1ADC2626),
                    border: Border.all(color: const Color(0x4DDC2626)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: KonektoBrand.body(
                      fontSize: 12.5,
                      color: const Color(0xFFF1A6A0),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _recipientIdController,
                style: KonektoBrand.body(
                  fontSize: 14,
                  color: KonektoBrand.cream,
                ),
                decoration: InputDecoration(
                  labelText: 'Recipient ID do Pagar.me',
                  labelStyle: KonektoBrand.body(
                    fontSize: 12.5,
                    color: KonektoBrand.slate,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.03),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: KonektoBrand.borderStrong,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: KonektoBrand.gold,
                      width: 1.6,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KonektoBrand.gold,
                    foregroundColor: KonektoBrand.ink,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: KonektoBrand.ink,
                          ),
                        )
                      : Text(
                          'Salvar',
                          style: KonektoBrand.body(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: KonektoBrand.ink,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final PaymentAccountStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      PaymentAccountStatus.notConfigured => (
        'Não configurado',
        KonektoBrand.slate,
      ),
      PaymentAccountStatus.pending => (
        'Pendente de verificação',
        KonektoBrand.gold,
      ),
      PaymentAccountStatus.verified => ('Ativo', const Color(0xFF5CB85C)),
      PaymentAccountStatus.rejected => (
        'Recusado pelo Pagar.me',
        const Color(0xFFDC2626),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: KonektoBrand.body(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
