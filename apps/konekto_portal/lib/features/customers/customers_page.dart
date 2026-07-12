import 'package:flutter/material.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/customers_repository.dart';
import 'package:konekto_portal/models/customer.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

String _currency(double value) => 'R\$ ${value.toStringAsFixed(2)}';

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

enum _SortMode { lastVisit, totalSpent, visitsCount, name }

extension on _SortMode {
  String get label => switch (this) {
        _SortMode.lastVisit => 'Última visita',
        _SortMode.totalSpent => 'Total gasto',
        _SortMode.visitsCount => 'Visitas',
        _SortMode.name => 'Nome',
      };
}

/// Tela "Clientes" — histórico consolidado de todo mundo que já se
/// hospedou (não só os hóspedes ativos agora, ver `GuestsPage` pra isso),
/// cruzando as várias vezes que a mesma pessoa apareceu pelo documento.
/// Pensada como base pra campanhas de e-mail/promoção mais pra frente —
/// por enquanto é só consulta.
class CustomersPage extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const CustomersPage({super.key, required this.session, required this.authRepository});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final _repository = CustomersRepository();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<Customer> _customers = const [];
  _SortMode _sortMode = _SortMode.lastVisit;
  String _viewingDocumentNumber = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      final customers = await _repository.listCustomers(hotelId: widget.session.hotelId, token: token);
      if (!mounted) return;
      setState(() => _customers = customers);
    } on StateError catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Customer> get _visibleCustomers {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _customers
        : _customers
            .where(
              (customer) =>
                  customer.fullName.toLowerCase().contains(query) ||
                  customer.documentNumber.toLowerCase().contains(query),
            )
            .toList();
    final sorted = [...filtered];
    switch (_sortMode) {
      case _SortMode.lastVisit:
        sorted.sort((a, b) => b.lastVisit.compareTo(a.lastVisit));
      case _SortMode.totalSpent:
        sorted.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
      case _SortMode.visitsCount:
        sorted.sort((a, b) => b.visitsCount.compareTo(a.visitsCount));
      case _SortMode.name:
        sorted.sort((a, b) => a.fullName.compareTo(b.fullName));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    if (_viewingDocumentNumber.isNotEmpty) {
      final customer = _customers.firstWhere(
        (c) => c.documentNumber == _viewingDocumentNumber,
        orElse: () => _customers.first,
      );
      return _CustomerDetail(customer: customer, onBack: () => setState(() => _viewingDocumentNumber = ''));
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: KonektoBrand.gold));
    }

    final visible = _visibleCustomers;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Clientes', style: KonektoBrand.display(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            'Todo mundo que já se hospedou, com o histórico completo de estadias e o total gasto — base pra futuras campanhas de e-mail e cupons.',
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou documento...',
                    hintStyle: KonektoBrand.body(fontSize: 13, color: KonektoBrand.slateSoft),
                    prefixIcon: const Icon(Icons.search, size: 18, color: KonektoBrand.slate),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.borderStrong)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.gold)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<_SortMode>(
                value: _sortMode,
                dropdownColor: KonektoBrand.surface,
                underline: const SizedBox.shrink(),
                style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.cream),
                icon: const Icon(Icons.sort, size: 16, color: KonektoBrand.slate),
                items: [
                  for (final mode in _SortMode.values)
                    DropdownMenuItem(value: mode, child: Text('Ordenar: ${mode.label}')),
                ],
                onChanged: (mode) => setState(() => _sortMode = mode ?? _sortMode),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (visible.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: KonektoBrand.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KonektoBrand.borderStrong),
              ),
              child: Text(
                _customers.isEmpty ? 'Nenhum cliente no histórico ainda.' : 'Nenhum resultado pra essa busca.',
                style: KonektoBrand.body(fontSize: 13.5),
              ),
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
                  for (final customer in visible) ...[
                    if (customer != visible.first) const Divider(height: 1, color: KonektoBrand.borderStrong),
                    _CustomerRow(
                      customer: customer,
                      onTap: () => setState(() => _viewingDocumentNumber = customer.documentNumber),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const _CustomerRow({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final contact = customer.email ?? '${customer.phoneCountryCode} ${customer.phoneNumber}';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.fullName,
                    style: KonektoBrand.body(fontSize: 14, fontWeight: FontWeight.w700, color: KonektoBrand.cream),
                  ),
                  const SizedBox(height: 2),
                  Text(contact, style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: KonektoBrand.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${customer.visitsCount} visita${customer.visitsCount == 1 ? '' : 's'}',
                style: KonektoBrand.body(fontSize: 11, fontWeight: FontWeight.w600, color: KonektoBrand.goldLight),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 90,
              child: Text(
                _currency(customer.totalSpent),
                textAlign: TextAlign.right,
                style: KonektoBrand.body(fontSize: 13, fontWeight: FontWeight.w600, color: KonektoBrand.cream),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 80,
              child: Text(
                _formatDate(customer.lastVisit),
                textAlign: TextAlign.right,
                style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: KonektoBrand.slate),
          ],
        ),
      ),
    );
  }
}

class _CustomerDetail extends StatelessWidget {
  final Customer customer;
  final VoidCallback onBack;

  const _CustomerDetail({required this.customer, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back, size: 18, color: KonektoBrand.slate)),
                Expanded(child: Text(customer.fullName, style: KonektoBrand.display(fontSize: 18))),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: KonektoBrand.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KonektoBrand.borderStrong),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Contato', style: KonektoBrand.display(fontSize: 15)),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Documento', value: '${customer.documentType.label} · ${customer.documentNumber}'),
                  _InfoRow(label: 'Telefone', value: '${customer.phoneCountryCode} ${customer.phoneNumber}'),
                  if (customer.whatsappNumber != null)
                    _InfoRow(label: 'WhatsApp', value: '${customer.whatsappCountryCode} ${customer.whatsappNumber}'),
                  if (customer.email != null) _InfoRow(label: 'E-mail', value: customer.email!),
                  _InfoRow(label: 'País', value: customer.country),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _StatCard(label: 'Visitas', value: '${customer.visitsCount}')),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(label: 'Total gasto', value: _currency(customer.totalSpent))),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(label: 'Primeira visita', value: _formatDate(customer.firstVisit))),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(label: 'Última visita', value: _formatDate(customer.lastVisit))),
              ],
            ),
            const SizedBox(height: 16),
            Text('Histórico de estadias', style: KonektoBrand.display(fontSize: 15)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: KonektoBrand.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KonektoBrand.borderStrong),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final stay in customer.stays) ...[
                    if (stay != customer.stays.first) const Divider(height: 1, color: KonektoBrand.borderStrong),
                    _StayHistoryRow(stay: stay),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: KonektoBrand.borderStrong),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mail_outline, size: 18, color: KonektoBrand.slate),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Em breve: enviar e-mails com promoções e cupons direto pra esse cliente.',
                      style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.slate),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.slate))),
          Expanded(child: Text(value, style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream))),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KonektoBrand.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KonektoBrand.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: KonektoBrand.body(fontSize: 11, color: KonektoBrand.slate)),
          const SizedBox(height: 4),
          Text(value, style: KonektoBrand.display(fontSize: 15)),
        ],
      ),
    );
  }
}

class _StayHistoryRow extends StatelessWidget {
  final CustomerStayEntry stay;

  const _StayHistoryRow({required this.stay});

  @override
  Widget build(BuildContext context) {
    final isActive = stay.status == 'active';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quarto ${stay.roomNumber}',
                  style: KonektoBrand.body(fontSize: 14, fontWeight: FontWeight.w700, color: KonektoBrand.cream),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDate(stay.checkInDate)} – ${_formatDate(stay.checkOutDate)}  ·  ${stay.nights} noite${stay.nights == 1 ? '' : 's'}',
                  style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? KonektoBrand.gold.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isActive ? 'Ativa' : 'Fechada',
              style: KonektoBrand.body(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? KonektoBrand.goldLight : KonektoBrand.slateSoft,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _currency(stay.spent),
            style: KonektoBrand.body(fontSize: 13, fontWeight: FontWeight.w600, color: KonektoBrand.goldLight),
          ),
        ],
      ),
    );
  }
}
