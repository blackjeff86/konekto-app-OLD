import 'package:flutter/material.dart';
import 'package:sevvn_admin/auth/auth_repository.dart';
import 'package:sevvn_admin/data/clients_repository.dart';
import 'package:sevvn_admin/features/clients/client_detail_page.dart';
import 'package:sevvn_admin/theme/konekto_brand.dart';
import 'package:sevvn_admin/widgets/copyable_code_box.dart';

/// Lista de todos os hotéis clientes — renderiza o detalhamento NO LUGAR
/// (não via `Navigator.push`), mesmo padrão do konekto_portal
/// (stay_detail_page.dart/guest_detail_page.dart).
class ClientsListPage extends StatefulWidget {
  final AuthRepository authRepository;

  const ClientsListPage({super.key, required this.authRepository});

  @override
  State<ClientsListPage> createState() => _ClientsListPageState();
}

class _ClientsListPageState extends State<ClientsListPage> {
  final _repository = ClientsRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<HotelOverview> _hotels = const [];
  String? _selectedHotelId;

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

  Future<void> _openCreateHotelDialog() async {
    final result = await showDialog<CreateHotelResult>(
      context: context,
      builder: (_) => _CreateHotelDialog(repository: _repository, authRepository: widget.authRepository),
    );
    if (result == null || !mounted) return;
    await showDialog<void>(context: context, builder: (_) => _HotelCreatedDialog(result: result));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedHotelId != null) {
      return ClientDetailPage(
        hotelId: _selectedHotelId!,
        authRepository: widget.authRepository,
        onBack: () {
          setState(() => _selectedHotelId = null);
          _load();
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Clientes', style: KonektoBrand.display(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text('Todos os hotéis usando a Sevvn.', style: KonektoBrand.body(fontSize: 13)),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _openCreateHotelDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: KonektoBrand.gold,
                foregroundColor: KonektoBrand.ink,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text('Novo cliente', style: KonektoBrand.body(fontSize: 13.5, fontWeight: FontWeight.w700, color: KonektoBrand.ink)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0x1ADC2626),
              border: Border.all(color: const Color(0x4DDC2626)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_errorMessage!, style: KonektoBrand.body(fontSize: 12.5, color: const Color(0xFFF1A6A0))),
          ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: KonektoBrand.gold))
              : _hotels.isEmpty
                  ? Center(child: Text('Nenhum hotel cadastrado ainda.', style: KonektoBrand.body(fontSize: 13.5)))
                  : ListView.separated(
                      itemCount: _hotels.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _ClientCard(
                        hotel: _hotels[index],
                        onTap: () => setState(() => _selectedHotelId = _hotels[index].hotelId),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _ClientCard extends StatelessWidget {
  final HotelOverview hotel;
  final VoidCallback onTap;

  const _ClientCard({required this.hotel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: KonektoBrand.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: KonektoBrand.borderStrong),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(hotel.name, style: KonektoBrand.body(fontSize: 15, fontWeight: FontWeight.w700, color: KonektoBrand.cream)),
                  if (hotel.address != null) ...[
                    const SizedBox(height: 2),
                    Text(hotel.address!, style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate)),
                  ],
                ],
              ),
            ),
            _PlanBadge(subscription: hotel.subscription),
            const SizedBox(width: 10),
            _IntegrationBadge(integration: hotel.integration),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${hotel.activeGuestCount}', style: KonektoBrand.body(fontSize: 15, fontWeight: FontWeight.w700, color: KonektoBrand.cream)),
                Text('hóspedes ativos', style: KonektoBrand.body(fontSize: 10.5, color: KonektoBrand.slate)),
              ],
            ),
            if (hotel.unreadSupportMessages > 0) ...[
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: KonektoBrand.gold, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  '${hotel.unreadSupportMessages} suporte',
                  style: KonektoBrand.body(fontSize: 10.5, fontWeight: FontWeight.w700, color: KonektoBrand.ink),
                ),
              ),
            ],
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, color: KonektoBrand.slate, size: 20),
          ],
        ),
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final Subscription? subscription;

  const _PlanBadge({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final sub = subscription;
    final (label, color) = sub == null
        ? ('sem plano', KonektoBrand.slate)
        : switch (sub.status) {
            'active' => (sub.planName, const Color(0xFF5CB85C)),
            'trial' => ('${sub.planName} · trial', KonektoBrand.gold),
            'suspended' => ('${sub.planName} · suspenso', const Color(0xFFDC2626)),
            _ => ('${sub.planName} · cancelado', KonektoBrand.slate),
          };
    return _Pill(label: label, color: color);
  }
}

class _IntegrationBadge extends StatelessWidget {
  final IntegrationHealth integration;

  const _IntegrationBadge({required this.integration});

  @override
  Widget build(BuildContext context) {
    final (label, color) = !integration.configured
        ? ('integração: não configurada', KonektoBrand.slate)
        : integration.lastOutboundOk == false
            ? ('integração: falha', const Color(0xFFDC2626))
            : ('integração: ok', const Color(0xFF5CB85C));
    return _Pill(label: label, color: color);
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: color),
          const SizedBox(width: 6),
          Text(label, style: KonektoBrand.body(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

InputDecoration _createHotelFieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.03),
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: KonektoBrand.borderStrong, width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: KonektoBrand.gold, width: 1.6),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  );
}

/// Diálogo de onboarding de um cliente real — cria o Hotel e já o primeiro
/// Staff (gerente) junto, atomicamente, no backend. Sem isso o hotel nasceria
/// sem ninguém com acesso ao portal.
class _CreateHotelDialog extends StatefulWidget {
  final ClientsRepository repository;
  final AuthRepository authRepository;

  const _CreateHotelDialog({required this.repository, required this.authRepository});

  @override
  State<_CreateHotelDialog> createState() => _CreateHotelDialogState();
}

const _kPlanOptions = [
  ('essential', 'Essential'),
  ('premium', 'Premium'),
  ('enterprise', 'Enterprise'),
];

class _CreateHotelDialogState extends State<_CreateHotelDialog> {
  final _nameController = TextEditingController();
  final _gerenteNameController = TextEditingController();
  final _gerenteEmailController = TextEditingController();
  String _selectedPlan = 'essential';

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _gerenteNameController.dispose();
    _gerenteEmailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final gerenteName = _gerenteNameController.text.trim();
    final gerenteEmail = _gerenteEmailController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Informe o nome do hotel.');
      return;
    }
    if (gerenteName.isEmpty) {
      setState(() => _errorMessage = 'Informe o nome do gerente.');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(gerenteEmail)) {
      setState(() => _errorMessage = 'Informe um e-mail válido para o gerente.');
      return;
    }

    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(() => _errorMessage = 'Sessão expirada — saia e entre novamente.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final result = await widget.repository.createHotel(
        token: token,
        name: name,
        plan: _selectedPlan,
        gerenteName: gerenteName,
        gerenteEmail: gerenteEmail,
      );
      if (mounted) Navigator.of(context).pop(result);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KonektoBrand.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Novo cliente', style: KonektoBrand.display(fontSize: 18)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
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
              TextField(
                controller: _nameController,
                style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
                decoration: _createHotelFieldDecoration('Nome do hotel'),
              ),
              const SizedBox(height: 16),
              Text('Plano comercial', style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate)),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final (id, label) in _kPlanOptions) ...[
                    Expanded(
                      child: _PlanChoiceChip(
                        label: label,
                        selected: _selectedPlan == id,
                        onTap: () => setState(() => _selectedPlan = id),
                      ),
                    ),
                    if (id != _kPlanOptions.last.$1) const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _gerenteNameController,
                style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
                decoration: _createHotelFieldDecoration('Nome do gerente'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _gerenteEmailController,
                keyboardType: TextInputType.emailAddress,
                style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
                decoration: _createHotelFieldDecoration('E-mail do gerente'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.slate)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: KonektoBrand.gold,
            foregroundColor: KonektoBrand.ink,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: KonektoBrand.ink))
              : Text('Criar hotel', style: KonektoBrand.body(fontSize: 13.5, fontWeight: FontWeight.w700, color: KonektoBrand.ink)),
        ),
      ],
    );
  }
}

class _PlanChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PlanChoiceChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? KonektoBrand.gold.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? KonektoBrand.gold : KonektoBrand.borderStrong, width: selected ? 1.6 : 1),
        ),
        child: Text(
          label,
          style: KonektoBrand.body(fontSize: 12.5, fontWeight: FontWeight.w700, color: selected ? KonektoBrand.gold : KonektoBrand.slate),
        ),
      ),
    );
  }
}

/// Mostra a senha temporária do gerente UMA ÚNICA VEZ — depois disso só o
/// hash fica salvo, não tem como recuperar.
class _HotelCreatedDialog extends StatelessWidget {
  final CreateHotelResult result;

  const _HotelCreatedDialog({required this.result});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KonektoBrand.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Hotel criado', style: KonektoBrand.display(fontSize: 18)),
      content: SizedBox(
        width: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Repasse estas credenciais pro gerente ${result.gerenteName}. A senha só aparece aqui — não fica salva em nenhum outro lugar.',
              style: KonektoBrand.body(fontSize: 13),
            ),
            const SizedBox(height: 20),
            Text('E-mail de acesso', style: KonektoBrand.body(fontSize: 11.5, color: KonektoBrand.slate)),
            const SizedBox(height: 6),
            CopyableCodeBox(value: result.gerenteEmail, fontSize: 15),
            const SizedBox(height: 16),
            Text('Senha temporária', style: KonektoBrand.body(fontSize: 11.5, color: KonektoBrand.slate)),
            const SizedBox(height: 6),
            CopyableCodeBox(value: result.temporaryPassword, fontSize: 18),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: KonektoBrand.gold,
            foregroundColor: KonektoBrand.ink,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          child: Text('Fechar', style: KonektoBrand.body(fontSize: 13.5, fontWeight: FontWeight.w700, color: KonektoBrand.ink)),
        ),
      ],
    );
  }
}

