import 'package:flutter/material.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/coupons_repository.dart';
import 'package:konekto_portal/models/coupon.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

/// Cadastro de cupons/promoções do hotel — o hóspede escolhe da lista de
/// cupons elegíveis direto no app ao fazer um pedido (sem digitar código).
class CouponsPage extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const CouponsPage({super.key, required this.session, required this.authRepository});

  @override
  State<CouponsPage> createState() => _CouponsPageState();
}

class _CouponsPageState extends State<CouponsPage> {
  final _repository = CouponsRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<Coupon> _coupons = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String?> _requireToken() async {
    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(() => _errorMessage = 'Sessão expirada — saia e entre novamente.');
    }
    return token;
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final token = await _requireToken();
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final coupons = await _repository.listCoupons(hotelId: widget.session.hotelId, token: token);
      setState(() => _coupons = coupons);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createOrEditCoupon({Coupon? existing}) async {
    final result = await showDialog<CouponInput>(
      context: context,
      builder: (context) => _CouponFormDialog(existing: existing),
    );
    if (result == null) return;

    final token = await _requireToken();
    if (token == null) return;

    try {
      if (existing == null) {
        await _repository.createCoupon(hotelId: widget.session.hotelId, token: token, input: result);
      } else {
        await _repository.updateCoupon(hotelId: widget.session.hotelId, couponId: existing.id, token: token, input: result);
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cupom salvo.')));
      }
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _toggleEnabled(Coupon coupon) async {
    final token = await _requireToken();
    if (token == null) return;
    try {
      await _repository.setEnabled(
        hotelId: widget.session.hotelId,
        couponId: coupon.id,
        token: token,
        enabled: !coupon.enabled,
      );
      await _load();
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _deleteCoupon(Coupon coupon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KonektoBrand.surface,
        title: Text('Remover cupom?', style: KonektoBrand.display(fontSize: 16)),
        content: Text('"${coupon.title}" será removido permanentemente.', style: KonektoBrand.body(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remover')),
        ],
      ),
    );
    if (confirmed != true) return;

    final token = await _requireToken();
    if (token == null) return;
    try {
      await _repository.deleteCoupon(hotelId: widget.session.hotelId, couponId: coupon.id, token: token);
      await _load();
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: KonektoBrand.gold));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Cupons e promoções', style: KonektoBrand.display(fontSize: 18))),
              TextButton.icon(
                onPressed: () => _createOrEditCoupon(),
                icon: const Icon(Icons.add, size: 18, color: KonektoBrand.goldLight),
                label: Text('Criar cupom', style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.goldLight)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'O hóspede escolhe da lista de cupons elegíveis direto ao fazer um pedido no app — não precisa digitar código.',
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
          if (_coupons.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: KonektoBrand.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KonektoBrand.borderStrong),
              ),
              child: Text('Nenhum cupom cadastrado ainda.', style: KonektoBrand.body(fontSize: 13.5)),
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
                  for (final coupon in _coupons) ...[
                    if (coupon != _coupons.first) const Divider(height: 1, color: KonektoBrand.borderStrong),
                    _CouponRow(
                      coupon: coupon,
                      onEdit: () => _createOrEditCoupon(existing: coupon),
                      onToggleEnabled: () => _toggleEnabled(coupon),
                      onDelete: () => _deleteCoupon(coupon),
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

class _CouponRow extends StatelessWidget {
  final Coupon coupon;
  final VoidCallback onEdit;
  final VoidCallback onToggleEnabled;
  final VoidCallback onDelete;

  const _CouponRow({
    required this.coupon,
    required this.onEdit,
    required this.onToggleEnabled,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isLive = coupon.enabled && !coupon.isExpired;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: KonektoBrand.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '-${coupon.discountLabel}',
              style: KonektoBrand.body(fontSize: 13, fontWeight: FontWeight.w700, color: KonektoBrand.goldLight),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon.title,
                  style: KonektoBrand.body(fontSize: 14.5, fontWeight: FontWeight.w700, color: KonektoBrand.cream),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    'código ${coupon.code}',
                    if (coupon.validUntil != null) 'válido até ${_formatDate(coupon.validUntil!)}',
                    if (coupon.minOrderValue != null) 'mín. R\$ ${coupon.minOrderValue!.toStringAsFixed(2)}',
                  ].join('  ·  '),
                  style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isLive ? KonektoBrand.gold.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              coupon.isExpired ? 'Expirado' : (coupon.enabled ? 'Ativo' : 'Desativado'),
              style: KonektoBrand.body(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isLive ? KonektoBrand.goldLight : KonektoBrand.slateSoft,
              ),
            ),
          ),
          Switch(value: coupon.enabled, onChanged: (_) => onToggleEnabled(), activeThumbColor: KonektoBrand.gold),
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined, size: 18, color: KonektoBrand.slate),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'Remover',
            icon: const Icon(Icons.delete_outline, size: 18, color: KonektoBrand.slate),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _CouponFormDialog extends StatefulWidget {
  final Coupon? existing;

  const _CouponFormDialog({this.existing});

  @override
  State<_CouponFormDialog> createState() => _CouponFormDialogState();
}

class _CouponFormDialogState extends State<_CouponFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _codeController;
  late final TextEditingController _discountValueController;
  late final TextEditingController _minOrderValueController;
  late final TextEditingController _usageLimitController;
  late final TextEditingController _perGuestLimitController;

  CouponDiscountType _discountType = CouponDiscountType.percentage;
  DateTime? _validFrom;
  DateTime? _validUntil;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    _codeController = TextEditingController(text: existing?.code ?? '');
    _discountValueController = TextEditingController(text: existing?.discountValue.toStringAsFixed(0) ?? '');
    _minOrderValueController = TextEditingController(text: existing?.minOrderValue?.toStringAsFixed(2) ?? '');
    _usageLimitController = TextEditingController(text: existing?.usageLimit?.toString() ?? '');
    _perGuestLimitController = TextEditingController(text: (existing?.perGuestLimit ?? 1).toString());
    _discountType = existing?.discountType ?? CouponDiscountType.percentage;
    _validFrom = existing?.validFrom;
    _validUntil = existing?.validUntil;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _codeController.dispose();
    _discountValueController.dispose();
    _minOrderValueController.dispose();
    _usageLimitController.dispose();
    _perGuestLimitController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _validFrom : _validUntil) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1095)),
      helpText: isFrom ? 'Válido a partir de' : 'Válido até',
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _validFrom = picked;
      } else {
        _validUntil = picked;
      }
    });
  }

  void _submit() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final code = _codeController.text.trim();
    final discountValue = double.tryParse(_discountValueController.text.replaceAll(',', '.'));

    if (title.isEmpty || description.isEmpty || code.isEmpty || discountValue == null || discountValue <= 0) {
      setState(() => _errorMessage = 'Preencha título, descrição, código e um valor de desconto válido.');
      return;
    }
    if (_discountType == CouponDiscountType.percentage && discountValue > 100) {
      setState(() => _errorMessage = 'Desconto percentual não pode passar de 100%.');
      return;
    }

    final minOrderValue = double.tryParse(_minOrderValueController.text.replaceAll(',', '.'));
    final usageLimit = int.tryParse(_usageLimitController.text);
    final perGuestLimit = int.tryParse(_perGuestLimitController.text) ?? 1;

    Navigator.of(context).pop(
      CouponInput(
        title: title,
        description: description,
        code: code,
        discountType: _discountType,
        discountValue: discountValue,
        minOrderValue: minOrderValue,
        validFrom: _validFrom,
        validUntil: _validUntil,
        usageLimit: usageLimit,
        perGuestLimit: perGuestLimit <= 0 ? 1 : perGuestLimit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KonektoBrand.surface,
      title: Text(widget.existing == null ? 'Criar cupom' : 'Editar cupom', style: KonektoBrand.display(fontSize: 16)),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 14),
              ],
              _Field(label: 'Título', controller: _titleController),
              const SizedBox(height: 10),
              _Field(label: 'Descrição', controller: _descriptionController, maxLines: 2),
              const SizedBox(height: 10),
              _Field(label: 'Código (referência interna, o hóspede não digita)', controller: _codeController),
              const SizedBox(height: 14),
              Text('Tipo de desconto', style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final type in CouponDiscountType.values)
                    ChoiceChip(
                      label: Text(type.label),
                      selected: _discountType == type,
                      onSelected: (_) => setState(() => _discountType = type),
                      selectedColor: KonektoBrand.gold,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      labelStyle: KonektoBrand.body(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _discountType == type ? KonektoBrand.ink : KonektoBrand.slate,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      label: _discountType == CouponDiscountType.percentage ? 'Desconto (%)' : 'Desconto (R\$)',
                      controller: _discountValueController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Field(
                      label: 'Pedido mínimo (opcional)',
                      controller: _minOrderValueController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      label: 'Usos por hóspede',
                      controller: _perGuestLimitController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Field(
                      label: 'Limite total (opcional)',
                      controller: _usageLimitController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _DatePickerField(label: 'Válido a partir de', date: _validFrom, onTap: () => _pickDate(isFrom: true))),
                  const SizedBox(width: 10),
                  Expanded(child: _DatePickerField(label: 'Válido até', date: _validUntil, onTap: () => _pickDate(isFrom: false))),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        TextButton(onPressed: _submit, child: const Text('Salvar')),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;

  const _Field({required this.label, required this.controller, this.maxLines = 1, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate),
        isDense: true,
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.borderStrong)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.gold)),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DatePickerField({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate),
          isDense: true,
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.borderStrong)),
        ),
        child: Text(
          date != null ? _formatDate(date!) : 'Sem limite',
          style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
        ),
      ),
    );
  }
}
