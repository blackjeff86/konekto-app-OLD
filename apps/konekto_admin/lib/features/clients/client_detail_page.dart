import 'dart:async';
import 'package:flutter/material.dart';
import 'package:konekto_admin/auth/auth_repository.dart';
import 'package:konekto_admin/data/admin_support_repository.dart' as support;
import 'package:konekto_admin/data/clients_repository.dart';
import 'package:konekto_admin/data/modules_catalog_repository.dart';
import 'package:konekto_admin/theme/konekto_brand.dart';

const List<String> _kStatusOptions = ['trial', 'active', 'suspended', 'cancelled'];
const List<String> _kPaymentStatusOptions = ['em_dia', 'atrasado', 'isento'];
const List<String> _kPlanOptions = ['essential', 'premium', 'enterprise'];

class ClientDetailPage extends StatefulWidget {
  final String hotelId;
  final AuthRepository authRepository;
  final VoidCallback onBack;

  const ClientDetailPage({
    super.key,
    required this.hotelId,
    required this.authRepository,
    required this.onBack,
  });

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  final _repository = ClientsRepository();
  final _supportRepository = support.AdminSupportRepository();
  final _modulesCatalogRepository = ModulesCatalogRepository();
  final _messageController = TextEditingController();
  final _planNameController = TextEditingController();
  final _monthlyAmountController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = true;
  bool _isSavingSubscription = false;
  bool _isSavingModules = false;
  bool _isSendingMessage = false;
  String? _errorMessage;
  HotelOverview? _hotel;
  List<support.SupportMessage> _messages = const [];
  List<ModuleDefinition> _catalogModules = const [];
  List<PlanPreset> _planPresets = const [];
  String _status = 'trial';
  String _paymentStatus = 'em_dia';
  String _plan = 'essential';
  String _presetId = 'essential';
  Set<String> _selectedExtraModules = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _planNameController.dispose();
    _monthlyAmountController.dispose();
    _notesController.dispose();
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
      final results = await Future.wait([
        _repository.getHotel(hotelId: widget.hotelId, token: token),
        _supportRepository.listMessages(hotelId: widget.hotelId, token: token),
        _modulesCatalogRepository.getCatalog(),
      ]);
      final hotel = results[0] as HotelOverview;
      final catalog = results[2] as ModulesCatalog;
      setState(() {
        _hotel = hotel;
        _messages = results[1] as List<support.SupportMessage>;
        _catalogModules = catalog.modules;
        _planPresets = catalog.planPresets;
        _planNameController.text = hotel.subscription?.planName ?? '';
        _monthlyAmountController.text = hotel.subscription?.monthlyAmount?.toStringAsFixed(2) ?? '';
        _status = hotel.subscription?.status ?? 'trial';
        _paymentStatus = hotel.subscription?.paymentStatus ?? 'em_dia';
        _notesController.text = hotel.subscription?.notes ?? '';
        _plan = hotel.subscription?.plan ?? 'essential';
        _presetId = hotel.subscription?.presetId ?? _plan;
        _selectedExtraModules = hotel.extraModules.toSet();
      });
      unawaited(_supportRepository.markThreadRead(hotelId: widget.hotelId, token: token));
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSubscription() async {
    final planName = _planNameController.text.trim();
    if (planName.isEmpty) {
      setState(() => _errorMessage = 'Informe o nome do plano.');
      return;
    }
    final rawAmount = _monthlyAmountController.text.trim().replaceAll(',', '.');
    final monthlyAmount = rawAmount.isEmpty ? null : double.tryParse(rawAmount);
    if (rawAmount.isNotEmpty && monthlyAmount == null) {
      setState(() => _errorMessage = 'Valor mensal inválido — use só números (ex: 499.90).');
      return;
    }
    final token = await widget.authRepository.getStoredToken();
    if (token == null) return;

    setState(() {
      _isSavingSubscription = true;
      _errorMessage = null;
    });
    try {
      await _repository.updateSubscription(
        hotelId: widget.hotelId,
        token: token,
        planName: planName,
        monthlyAmount: monthlyAmount,
        status: _status,
        paymentStatus: _paymentStatus,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        plan: _plan,
        presetId: _presetId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plano atualizado.')));
      }
      await _load();
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSavingSubscription = false);
    }
  }

  Future<void> _saveExtraModules() async {
    final token = await widget.authRepository.getStoredToken();
    if (token == null) return;

    setState(() {
      _isSavingModules = true;
      _errorMessage = null;
    });
    try {
      await _repository.updateExtraModules(
        hotelId: widget.hotelId,
        token: token,
        extraModules: _selectedExtraModules.toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Módulos de cortesia atualizados.')));
      }
      await _load();
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSavingModules = false);
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    final token = await widget.authRepository.getStoredToken();
    if (token == null) return;

    setState(() => _isSendingMessage = true);
    try {
      await _supportRepository.sendMessage(hotelId: widget.hotelId, token: token, message: message);
      _messageController.clear();
      await _load();
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSendingMessage = false);
    }
  }

  String _formatTimestamp(DateTime? date) {
    if (date == null) return 'Nunca';
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: KonektoBrand.gold));
    }

    final hotel = _hotel;
    if (hotel == null) {
      return Center(child: Text(_errorMessage ?? 'Cliente não encontrado.', style: KonektoBrand.body(fontSize: 13.5)));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, color: KonektoBrand.slate, size: 20),
              ),
              const SizedBox(width: 4),
              Text(hotel.name, style: KonektoBrand.display(fontSize: 20)),
            ],
          ),
          if (hotel.address != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Text(hotel.address!, style: KonektoBrand.body(fontSize: 13)),
            ),
          ],
          const SizedBox(height: 24),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildSubscriptionCard()),
              const SizedBox(width: 20),
              Expanded(child: _buildIntegrationCard(hotel)),
            ],
          ),
          const SizedBox(height: 20),
          _buildFeaturesCard(hotel),
          const SizedBox(height: 20),
          _buildStaffCard(hotel),
          const SizedBox(height: 20),
          _buildSupportCard(),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KonektoBrand.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KonektoBrand.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Plano/assinatura', style: KonektoBrand.display(fontSize: 15)),
          const SizedBox(height: 14),
          TextField(
            controller: _planNameController,
            style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
            decoration: _fieldDecoration('Nome do plano'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _monthlyAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
            decoration: _fieldDecoration('Mensalidade (R\$, opcional)'),
          ),
          const SizedBox(height: 12),
          _buildDropdown('Plano (billing/relatório)', _plan, _kPlanOptions, (value) => setState(() => _plan = value)),
          const SizedBox(height: 12),
          _buildDropdown(
            'Plan Preset (módulos/templates)',
            _planPresets.any((preset) => preset.id == _presetId) ? _presetId : _plan,
            _planPresets.map((preset) => preset.id).toList(),
            (value) => setState(() => _presetId = value),
            optionLabel: (id) => _planPresets.firstWhere((preset) => preset.id == id, orElse: () => PlanPreset(id: id, name: id)).name,
          ),
          const SizedBox(height: 12),
          _buildDropdown('Status', _status, _kStatusOptions, (value) => setState(() => _status = value)),
          const SizedBox(height: 12),
          _buildDropdown('Pagamento', _paymentStatus, _kPaymentStatusOptions, (value) => setState(() => _paymentStatus = value)),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            minLines: 2,
            maxLines: 4,
            style: KonektoBrand.body(fontSize: 13, color: KonektoBrand.cream),
            decoration: _fieldDecoration('Notas (opcional)'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 42,
            child: ElevatedButton(
              onPressed: _isSavingSubscription ? null : _saveSubscription,
              style: ElevatedButton.styleFrom(
                backgroundColor: KonektoBrand.gold,
                foregroundColor: KonektoBrand.ink,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              child: _isSavingSubscription
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: KonektoBrand.ink))
                  : Text('Salvar', style: KonektoBrand.body(fontSize: 13.5, fontWeight: FontWeight.w700, color: KonektoBrand.ink)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged, {
    String Function(String id)? optionLabel,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: KonektoBrand.surfaceAlt,
      style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
      decoration: _fieldDecoration(label),
      items: options.map((option) => DropdownMenuItem(value: option, child: Text(optionLabel?.call(option) ?? option))).toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

  InputDecoration _fieldDecoration(String label) {
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

  Widget _buildIntegrationCard(HotelOverview hotel) {
    final integration = hotel.integration;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KonektoBrand.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KonektoBrand.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Integração com o PMS', style: KonektoBrand.display(fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            'Configuração de chave/webhook é feita pelo hotel, no portal deles — aqui só acompanhamos a saúde.',
            style: KonektoBrand.body(fontSize: 11.5),
          ),
          const SizedBox(height: 14),
          _InfoRow(label: 'Configurada', value: integration.configured ? 'Sim' : 'Não'),
          _InfoRow(label: 'Última sincronização recebida', value: _formatTimestamp(integration.lastInboundSyncAt)),
          _InfoRow(label: 'Último envio de pedido', value: _formatTimestamp(integration.lastOutboundAt)),
          _InfoRow(
            label: 'Status do último envio',
            value: integration.lastOutboundOk == null ? '—' : (integration.lastOutboundOk! ? 'Sucesso' : 'Falha'),
          ),
          if (integration.lastOutboundError != null)
            _InfoRow(label: 'Erro', value: integration.lastOutboundError!),
          const SizedBox(height: 8),
          Text('${hotel.activeGuestCount} hóspedes ativos agora', style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.goldLight)),
        ],
      ),
    );
  }

  /// Módulos liberados de cortesia pra este hotel, além do que o Plan
  /// Preset já dá por padrão (`hotel.allowedModules`, sempre marcado e
  /// travado aqui — não dá pra "desligar" o que o preset inclui, isso o
  /// próprio hotel faz no portal dele). Lista vem do catálogo
  /// (`GET /api/modules-catalog`), nunca hardcoded — módulo novo aparece
  /// aqui automaticamente. `implemented: false` fica visível (a equipe
  /// Konekto pode querer conferir o catálogo inteiro) mas sem toggle, pra
  /// não liberar cortesia de algo que ainda não tem tela nenhuma. Só a
  /// equipe Konekto vê essa tela; não existe equivalente no portal do
  /// hotel (ver PATCH /api/platform-admin/hotels/{hotelId}).
  Widget _buildFeaturesCard(HotelOverview hotel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KonektoBrand.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KonektoBrand.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Módulos', style: KonektoBrand.display(fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            'Marcados e travados = incluídos no preset atual. Os demais podem ser liberados como cortesia, sem mudar o plano do hotel. Cinza = ainda sem tela pronta.',
            style: KonektoBrand.body(fontSize: 11.5),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final module in _catalogModules)
                _FeatureFlagChip(
                  label: module.name,
                  includedInPlan: hotel.allowedModules.contains(module.id),
                  implemented: module.implemented,
                  selected: hotel.allowedModules.contains(module.id) || _selectedExtraModules.contains(module.id),
                  onTap: !module.implemented || hotel.allowedModules.contains(module.id)
                      ? null
                      : () => setState(() {
                            if (_selectedExtraModules.contains(module.id)) {
                              _selectedExtraModules.remove(module.id);
                            } else {
                              _selectedExtraModules.add(module.id);
                            }
                          }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 42,
            width: 160,
            child: ElevatedButton(
              onPressed: _isSavingModules ? null : _saveExtraModules,
              style: ElevatedButton.styleFrom(
                backgroundColor: KonektoBrand.gold,
                foregroundColor: KonektoBrand.ink,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              child: _isSavingModules
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: KonektoBrand.ink))
                  : Text('Salvar', style: KonektoBrand.body(fontSize: 13.5, fontWeight: FontWeight.w700, color: KonektoBrand.ink)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(HotelOverview hotel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KonektoBrand.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KonektoBrand.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Usuários com acesso ao portal do hotel', style: KonektoBrand.display(fontSize: 15)),
          const SizedBox(height: 12),
          if (hotel.staff.isEmpty)
            Text('Nenhum staff cadastrado.', style: KonektoBrand.body(fontSize: 13))
          else
            for (final member in hotel.staff)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${member.name} · ${member.email}',
                        style: KonektoBrand.body(fontSize: 13, color: KonektoBrand.cream),
                      ),
                    ),
                    Text(
                      member.role == 'gerente' ? 'Gerente' : 'Recepção',
                      style: KonektoBrand.body(fontSize: 11.5, color: KonektoBrand.goldLight),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KonektoBrand.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KonektoBrand.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Suporte', style: KonektoBrand.display(fontSize: 15)),
          const SizedBox(height: 12),
          if (_messages.isEmpty)
            Text('Nenhuma mensagem ainda.', style: KonektoBrand.body(fontSize: 13))
          else
            for (final message in _messages)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Align(
                  alignment: message.isFromHotel ? Alignment.centerLeft : Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: message.isFromHotel ? Colors.white.withValues(alpha: 0.04) : KonektoBrand.gold.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(message.body, style: KonektoBrand.body(fontSize: 13, color: KonektoBrand.cream)),
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 3,
                  style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
                  decoration: _fieldDecoration('Responder...'),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: _isSendingMessage ? null : _sendMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KonektoBrand.gold,
                    foregroundColor: KonektoBrand.ink,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: _isSendingMessage
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: KonektoBrand.ink))
                      : const Icon(Icons.send, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureFlagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool includedInPlan;
  final bool implemented;
  final VoidCallback? onTap;

  const _FeatureFlagChip({
    required this.label,
    required this.selected,
    required this.includedInPlan,
    this.implemented = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: implemented ? 1 : 0.45,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? KonektoBrand.gold.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? KonektoBrand.gold : KonektoBrand.borderStrong, width: selected ? 1.4 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                !implemented
                    ? Icons.hourglass_empty
                    : (includedInPlan ? Icons.lock_outline : (selected ? Icons.check_circle : Icons.circle_outlined)),
                size: 15,
                color: selected ? KonektoBrand.gold : KonektoBrand.slate,
              ),
              const SizedBox(width: 6),
              Text(label, style: KonektoBrand.body(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? KonektoBrand.cream : KonektoBrand.slate)),
            ],
          ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate))),
          Flexible(
            flex: 2,
            child: Text(value, style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.cream), textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
