import 'package:flutter/material.dart';
import 'package:konekto_admin/auth/auth_repository.dart';
import 'package:konekto_admin/data/clients_repository.dart';
import 'package:konekto_admin/features/clients/client_detail_page.dart';
import 'package:konekto_admin/theme/konekto_brand.dart';

/// Visão financeira cross-hotel — MRR total e status de pagamento por
/// cliente. "Status do pagamento" ainda é um campo manual que o admin edita
/// no detalhamento (sem fatura/boleto automático — fase 2, via Pagar.me).
class FinanceiroPage extends StatefulWidget {
  final AuthRepository authRepository;

  const FinanceiroPage({super.key, required this.authRepository});

  @override
  State<FinanceiroPage> createState() => _FinanceiroPageState();
}

class _FinanceiroPageState extends State<FinanceiroPage> {
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
      hotels.sort((a, b) => _paymentPriority(a).compareTo(_paymentPriority(b)));
      setState(() => _hotels = hotels);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Atrasado primeiro (precisa de ação), depois em dia, depois isento/sem plano.
  int _paymentPriority(HotelOverview hotel) {
    return switch (hotel.subscription?.paymentStatus) {
      'atrasado' => 0,
      'em_dia' => 1,
      'isento' => 2,
      _ => 3,
    };
  }

  String _formatCurrency(double? value) {
    if (value == null) return '—';
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

    final mrr = _hotels.fold<double>(
      0,
      (sum, hotel) => sum + (hotel.subscription?.status == 'active' ? (hotel.subscription?.monthlyAmount ?? 0) : 0),
    );
    final overdue = _hotels.where((hotel) => hotel.subscription?.paymentStatus == 'atrasado');
    final overdueAmount = overdue.fold<double>(0, (sum, hotel) => sum + (hotel.subscription?.monthlyAmount ?? 0));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Financeiro', style: KonektoBrand.display(fontSize: 22)),
          const SizedBox(height: 4),
          Text('Mensalidades e status de pagamento de cada hotel.', style: KonektoBrand.body(fontSize: 13)),
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
              _KpiCard(label: 'MRR (planos ativos)', value: _formatCurrency(mrr), color: KonektoBrand.gold),
              _KpiCard(
                label: 'Em atraso',
                value: '${overdue.length} hotel(is) · ${_formatCurrency(overdueAmount)}',
                color: overdue.isNotEmpty ? const Color(0xFFDC2626) : null,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              color: KonektoBrand.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: KonektoBrand.borderStrong),
            ),
            child: Column(
              children: [
                _TableHeaderRow(),
                for (final hotel in _hotels) _HotelRow(hotel: hotel, formatCurrency: _formatCurrency, onTap: () => setState(() => _openHotelId = hotel.hotelId)),
                if (_hotels.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Nenhum hotel cadastrado ainda.', style: KonektoBrand.body(fontSize: 13.5)),
                  ),
              ],
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
  final Color? color;

  const _KpiCard({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KonektoBrand.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KonektoBrand.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: KonektoBrand.display(fontSize: 20, color: color ?? KonektoBrand.cream)),
          const SizedBox(height: 4),
          Text(label, style: KonektoBrand.body(fontSize: 11.5, color: KonektoBrand.slate)),
        ],
      ),
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = KonektoBrand.body(fontSize: 11, fontWeight: FontWeight.w700, color: KonektoBrand.slate);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: KonektoBrand.borderStrong))),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('HOTEL', style: style)),
          Expanded(flex: 2, child: Text('PLANO', style: style)),
          Expanded(flex: 2, child: Text('MENSALIDADE', style: style)),
          Expanded(flex: 2, child: Text('PAGAMENTO', style: style)),
        ],
      ),
    );
  }
}

class _HotelRow extends StatelessWidget {
  final HotelOverview hotel;
  final String Function(double?) formatCurrency;
  final VoidCallback onTap;

  const _HotelRow({required this.hotel, required this.formatCurrency, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sub = hotel.subscription;
    final (paymentLabel, paymentColor) = switch (sub?.paymentStatus) {
      'em_dia' => ('Em dia', const Color(0xFF5CB85C)),
      'atrasado' => ('Atrasado', const Color(0xFFDC2626)),
      'isento' => ('Isento', KonektoBrand.slate),
      _ => ('—', KonektoBrand.slate),
    };
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: KonektoBrand.border))),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(hotel.name, style: KonektoBrand.body(fontSize: 13.5, fontWeight: FontWeight.w600, color: KonektoBrand.cream))),
            Expanded(flex: 2, child: Text(sub?.planName ?? 'Sem plano', style: KonektoBrand.body(fontSize: 13, color: KonektoBrand.slate))),
            Expanded(flex: 2, child: Text(formatCurrency(sub?.monthlyAmount), style: KonektoBrand.body(fontSize: 13, color: KonektoBrand.cream))),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 7, color: paymentColor),
                  const SizedBox(width: 6),
                  Text(paymentLabel, style: KonektoBrand.body(fontSize: 12.5, fontWeight: FontWeight.w600, color: paymentColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
