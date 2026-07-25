import 'package:flutter/material.dart';
import 'package:konekto_admin/auth/auth_repository.dart';
import 'package:konekto_admin/data/clients_repository.dart';
import 'package:konekto_admin/features/clients/client_detail_page.dart';
import 'package:konekto_admin/theme/konekto_brand.dart';

/// Visão geral cross-hotel — KPIs principais e a lista de clientes que
/// precisam de atenção (falha de integração, suporte não lido, pagamento
/// atrasado), pra não precisar abrir Clientes/Suporte/Financeiro só pra
/// saber se está tudo bem.
class DashboardPage extends StatefulWidget {
  final AuthRepository authRepository;

  const DashboardPage({super.key, required this.authRepository});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _repository = ClientsRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<HotelOverview> _hotels = const [];
  String? _openHotelId;

  @override
  void initState() {
    super.initState();
    _load();
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
      final hotels = await _repository.listHotels(token: token);
      setState(() => _hotels = hotels);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _needsAttention(HotelOverview hotel) {
    return hotel.unreadSupportMessages > 0 ||
        hotel.integration.lastOutboundOk == false ||
        hotel.subscription?.paymentStatus == 'atrasado';
  }

  String _formatCurrency(double value) {
    final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
    final parts = fixed.split(',');
    final intPart = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
    return 'R\$ $intPart,${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    if (_openHotelId != null) {
      return ClientDetailPage(
        hotelId: _openHotelId!,
        authRepository: widget.authRepository,
        onBack: () {
          setState(() => _openHotelId = null);
          _load();
        },
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: KonektoBrand.gold));
    }

    final totalGuests = _hotels.fold<int>(0, (sum, hotel) => sum + hotel.activeGuestCount);
    final totalUnreadSupport = _hotels.fold<int>(0, (sum, hotel) => sum + hotel.unreadSupportMessages);
    final integrationFailing = _hotels.where((hotel) => hotel.integration.lastOutboundOk == false).length;
    final mrr = _hotels.fold<double>(
      0,
      (sum, hotel) => sum + (hotel.subscription?.status == 'active' ? (hotel.subscription?.monthlyAmount ?? 0) : 0),
    );
    final attentionList = _hotels.where(_needsAttention).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Dashboard', style: KonektoBrand.display(fontSize: 22)),
          const SizedBox(height: 4),
          Text('Visão geral de todos os hotéis clientes.', style: KonektoBrand.body(fontSize: 13)),
          const SizedBox(height: 24),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0x1ADC2626),
                  border: Border.all(color: const Color(0x4DDC2626)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_errorMessage!, style: KonektoBrand.body(fontSize: 12.5, color: const Color(0xFFF1A6A0))),
              ),
            ),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _KpiCard(label: 'Hotéis clientes', value: '${_hotels.length}', icon: Icons.apartment_outlined),
              _KpiCard(label: 'Hóspedes ativos agora', value: '$totalGuests', icon: Icons.people_outline),
              _KpiCard(
                label: 'MRR (planos ativos)',
                value: _formatCurrency(mrr),
                icon: Icons.payments_outlined,
                color: KonektoBrand.gold,
              ),
              _KpiCard(
                label: 'Integrações com falha',
                value: '$integrationFailing',
                icon: Icons.sync_problem_outlined,
                color: integrationFailing > 0 ? const Color(0xFFDC2626) : null,
              ),
              _KpiCard(
                label: 'Mensagens de suporte não lidas',
                value: '$totalUnreadSupport',
                icon: Icons.mark_email_unread_outlined,
                color: totalUnreadSupport > 0 ? KonektoBrand.gold : null,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text('Precisa de atenção', style: KonektoBrand.display(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            'Hotéis com falha de integração, suporte não respondido ou pagamento atrasado.',
            style: KonektoBrand.body(fontSize: 12.5),
          ),
          const SizedBox(height: 16),
          if (attentionList.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: KonektoBrand.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: KonektoBrand.borderStrong),
              ),
              child: Text('Tudo em dia — nenhum hotel precisa de atenção agora.', style: KonektoBrand.body(fontSize: 13)),
            )
          else
            for (final hotel in attentionList)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => setState(() => _openHotelId = hotel.hotelId),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: KonektoBrand.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x4DDC2626)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(hotel.name, style: KonektoBrand.body(fontSize: 14, fontWeight: FontWeight.w700, color: KonektoBrand.cream)),
                        ),
                        if (hotel.integration.lastOutboundOk == false)
                          const _ReasonChip(label: 'integração falhando'),
                        if (hotel.unreadSupportMessages > 0) ...[
                          const SizedBox(width: 8),
                          _ReasonChip(label: '${hotel.unreadSupportMessages} suporte'),
                        ],
                        if (hotel.subscription?.paymentStatus == 'atrasado') ...[
                          const SizedBox(width: 8),
                          const _ReasonChip(label: 'pagamento atrasado'),
                        ],
                        const SizedBox(width: 12),
                        const Icon(Icons.chevron_right, color: KonektoBrand.slate, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _KpiCard({required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final accent = color ?? KonektoBrand.cream;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KonektoBrand.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KonektoBrand.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: KonektoBrand.slate),
          const SizedBox(height: 12),
          Text(value, style: KonektoBrand.display(fontSize: 22, color: accent)),
          const SizedBox(height: 4),
          Text(label, style: KonektoBrand.body(fontSize: 11.5, color: KonektoBrand.slate)),
        ],
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  final String label;

  const _ReasonChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0x33DC2626), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: KonektoBrand.body(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFFF1A6A0))),
    );
  }
}
