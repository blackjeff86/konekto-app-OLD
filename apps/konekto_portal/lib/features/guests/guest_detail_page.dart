import 'package:flutter/material.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/guests_repository.dart';
import 'package:konekto_portal/models/guest.dart';
import 'package:konekto_portal/models/order.dart' show OrderStatus;
import 'package:konekto_portal/models/stay.dart' show GuestOrderSummary;
import 'package:konekto_portal/theme/konekto_brand.dart';

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatDateTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '${_formatDate(dateTime)} às $hour:$minute';
}

/// Página de detalhe de um hóspede — substitui o modal antigo. Mostra o
/// cadastro completo, o quarto/estadia, e todos os pedidos/reservas que
/// esse hóspede já fez (serviço de quarto + agendamentos).
class GuestDetailPage extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;
  final String guestId;

  const GuestDetailPage({
    super.key,
    required this.session,
    required this.authRepository,
    required this.guestId,
  });

  @override
  State<GuestDetailPage> createState() => _GuestDetailPageState();
}

class _GuestDetailPageState extends State<GuestDetailPage> {
  final _repository = GuestsRepository();

  bool _isLoading = true;
  String? _errorMessage;
  Guest? _guest;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(() {
        _errorMessage = 'Sessão expirada — saia e entre novamente.';
        _isLoading = false;
      });
      return;
    }
    try {
      final guest = await _repository.getGuest(
        hotelId: widget.session.hotelId,
        guestId: widget.guestId,
        token: token,
      );
      setState(() => _guest = guest);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _revokeGuest(Guest guest) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KonektoBrand.surface,
        title: Text('Revogar acesso?', style: KonektoBrand.display(fontSize: 16)),
        content: Text(
          '"${guest.fullName}" não vai mais conseguir entrar no app com esse código.',
          style: KonektoBrand.body(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Revogar')),
        ],
      ),
    );
    if (confirmed != true) return;

    final token = await widget.authRepository.getStoredToken();
    if (token == null) return;
    try {
      await _repository.revokeGuest(hotelId: widget.session.hotelId, guestId: guest.id, token: token);
      await _load();
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KonektoBrand.ink,
      appBar: AppBar(
        backgroundColor: KonektoBrand.ink,
        elevation: 0,
        title: Text(_guest?.fullName ?? 'Hóspede', style: KonektoBrand.display(fontSize: 17)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: KonektoBrand.gold))
          : _errorMessage != null && _guest == null
              ? Center(
                  child: Text(_errorMessage!, style: KonektoBrand.body(fontSize: 13.5)),
                )
              : _buildBody(_guest!),
    );
  }

  Widget _buildBody(Guest guest) {
    final isActive = guest.status == GuestStatus.active;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            _SectionCard(
              title: 'Cadastro',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? KonektoBrand.gold.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isActive ? 'Ativo' : 'Revogado',
                  style: KonektoBrand.body(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? KonektoBrand.goldLight : KonektoBrand.slateSoft,
                  ),
                ),
              ),
              children: [
                _DetailLine(label: 'Documento', value: '${guest.documentType.label} · ${guest.documentNumber}'),
                _DetailLine(label: 'Telefone', value: '${guest.phoneCountryCode} ${guest.phoneNumber}'),
                if (guest.whatsappNumber != null)
                  _DetailLine(label: 'WhatsApp', value: '${guest.whatsappCountryCode} ${guest.whatsappNumber}'),
                if (guest.email != null) _DetailLine(label: 'E-mail', value: guest.email!),
                if (guest.address != null) _DetailLine(label: 'Endereço', value: guest.address!),
                _DetailLine(label: 'País', value: guest.country),
                _DetailLine(label: 'Senha de wifi', value: guest.wifiPassword ?? 'Padrão do hotel'),
                _DetailLine(label: 'Código de acesso', value: guest.accessCode),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Quarto',
              children: [
                _DetailLine(label: 'Número', value: guest.roomNumber),
                _DetailLine(label: 'Estadia', value: '${_formatDate(guest.checkInDate)} até ${_formatDate(guest.checkOutDate)}'),
                _DetailLine(label: 'Status da estadia', value: guest.stay.status.label),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Pedidos e reservas',
              children: guest.orders.isEmpty
                  ? [Text('Nenhum pedido ainda.', style: KonektoBrand.body(fontSize: 13))]
                  : [for (final order in guest.orders) _OrderLine(order: order)],
            ),
            const SizedBox(height: 24),
            if (isActive)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _revokeGuest(guest),
                  icon: const Icon(Icons.block, size: 16, color: Color(0xFFF1A6A0)),
                  label: Text('Revogar acesso', style: KonektoBrand.body(fontSize: 13, color: const Color(0xFFF1A6A0))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0x4DDC2626)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  const _SectionCard({required this.title, this.trailing, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KonektoBrand.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KonektoBrand.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: KonektoBrand.display(fontSize: 15))),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate))),
          Expanded(child: Text(value, style: KonektoBrand.body(fontSize: 13, color: KonektoBrand.cream))),
        ],
      ),
    );
  }
}

class _OrderLine extends StatelessWidget {
  final GuestOrderSummary order;

  const _OrderLine({required this.order});

  Color get _statusColor => switch (order.status) {
        OrderStatus.pending => KonektoBrand.gold,
        OrderStatus.inProgress => const Color(0xFF5B9BD5),
        OrderStatus.completed => const Color(0xFF5CB85C),
        OrderStatus.cancelled => KonektoBrand.slateSoft,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order.itemName}${order.quantity > 1 ? ' ×${order.quantity}' : ''}',
                  style: KonektoBrand.body(fontSize: 13.5, fontWeight: FontWeight.w700, color: KonektoBrand.cream),
                ),
                const SizedBox(height: 2),
                Text(
                  order.price != null ? 'R\$ ${(order.price! * order.quantity).toStringAsFixed(2)}' : 'Sob consulta',
                  style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate),
                ),
                if (order.scheduledFor != null)
                  Text(
                    'Agendado: ${_formatDateTime(order.scheduledFor!)}',
                    style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.gold, fontWeight: FontWeight.w600),
                  ),
                if (order.note != null && order.note!.isNotEmpty)
                  Text(
                    'Obs: ${order.note}',
                    style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate).copyWith(fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
            child: Text(
              order.status.label,
              style: KonektoBrand.body(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor),
            ),
          ),
        ],
      ),
    );
  }
}
