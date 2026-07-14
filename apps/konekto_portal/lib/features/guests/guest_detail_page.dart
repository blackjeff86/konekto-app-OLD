import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/guests_repository.dart';
import 'package:konekto_portal/models/guest.dart';
import 'package:konekto_portal/models/order.dart' show OrderStatus;
import 'package:konekto_portal/models/stay.dart' show GuestOrderSummary;
import 'package:konekto_portal/theme/konekto_brand.dart';
import 'package:konekto_portal/utils/input_formatters.dart';
import 'package:konekto_portal/widgets/copyable_code_box.dart';

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatDateTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '${_formatDate(dateTime)} às $hour:$minute';
}

/// Detalhe de um hóspede — substitui o modal antigo. Mostra o cadastro
/// completo, o quarto/estadia, e todos os pedidos/reservas que esse
/// hóspede já fez (serviço de quarto + agendamentos).
///
/// Renderizado NO LUGAR do conteúdo (não via `Navigator.push`) — mesmo
/// padrão de `ServiceItemsPage`/`onBack` — pra manter o menu lateral do
/// portal sempre visível.
class GuestDetailPage extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;
  final String guestId;
  final VoidCallback onBack;

  const GuestDetailPage({
    super.key,
    required this.session,
    required this.authRepository,
    required this.guestId,
    required this.onBack,
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

  Future<void> _editGuest(Guest guest) async {
    final input = await showDialog<GuestEditInput>(
      context: context,
      builder: (context) => _GuestEditDialog(guest: guest),
    );
    if (input == null) return;

    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(() => _errorMessage = 'Sessão expirada — saia e entre novamente.');
      return;
    }
    try {
      await _repository.updateGuest(hotelId: widget.session.hotelId, guestId: guest.id, token: token, input: input);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cadastro atualizado.')));
      }
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: KonektoBrand.gold));
    }
    if (_errorMessage != null && _guest == null) {
      return Center(child: Text(_errorMessage!, style: KonektoBrand.body(fontSize: 13.5)));
    }
    return _buildBody(_guest!);
  }

  Widget _buildBody(Guest guest) {
    final isActive = guest.status == GuestStatus.active;
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back, size: 18, color: KonektoBrand.slate),
                ),
                Expanded(child: Text(guest.fullName, style: KonektoBrand.display(fontSize: 18))),
              ],
            ),
            const SizedBox(height: 16),
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
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
                  IconButton(
                    tooltip: 'Editar cadastro',
                    icon: const Icon(Icons.edit_outlined, size: 18, color: KonektoBrand.slate),
                    onPressed: () => _editGuest(guest),
                  ),
                ],
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text('Código de acesso', style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate)),
                      ),
                      Expanded(child: CopyableCodeBox(value: guest.accessCode, fontSize: 13)),
                    ],
                  ),
                ),
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

/// Formulário de edição do cadastro — mesmos campos pessoais do formulário
/// de criação, pré-preenchidos com os dados atuais do hóspede. Sem
/// campos de quarto/estadia (aqueles não mudam por aqui).
class _GuestEditDialog extends StatefulWidget {
  final Guest guest;

  const _GuestEditDialog({required this.guest});

  @override
  State<_GuestEditDialog> createState() => _GuestEditDialogState();
}

class _GuestEditDialogState extends State<_GuestEditDialog> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _documentNumberController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _countryController;
  late final TextEditingController _wifiPasswordController;

  late DocumentType _documentType;
  PhoneNumber? _phone;
  PhoneNumber? _whatsapp;
  late bool _whatsappSameAsPhone;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final guest = widget.guest;
    _firstNameController = TextEditingController(text: guest.firstName);
    _lastNameController = TextEditingController(text: guest.lastName);
    _documentNumberController = TextEditingController(text: guest.documentNumber);
    _emailController = TextEditingController(text: guest.email ?? '');
    _addressController = TextEditingController(text: guest.address ?? '');
    _countryController = TextEditingController(text: guest.country);
    _wifiPasswordController = TextEditingController(text: guest.wifiPassword ?? '');
    _documentType = guest.documentType;
    _whatsappSameAsPhone =
        guest.whatsappNumber == null || (guest.whatsappCountryCode == guest.phoneCountryCode && guest.whatsappNumber == guest.phoneNumber);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _documentNumberController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _wifiPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final documentNumber = _documentNumberController.text.trim();
    final country = _countryController.text.trim();
    final phone = _phone;
    final phoneCountryCode = phone?.countryCode ?? widget.guest.phoneCountryCode;
    final phoneNumber = phone != null ? stripNonDigits(phone.number) : widget.guest.phoneNumber;

    if (firstName.isEmpty || lastName.isEmpty || documentNumber.isEmpty || country.isEmpty) {
      setState(() => _errorMessage = 'Preencha nome, sobrenome, documento e país.');
      return;
    }

    final whatsapp = _whatsappSameAsPhone ? null : _whatsapp;
    final whatsappCountryCode = _whatsappSameAsPhone ? phoneCountryCode : (whatsapp?.countryCode ?? widget.guest.whatsappCountryCode);
    final whatsappNumber = _whatsappSameAsPhone
        ? phoneNumber
        : (whatsapp != null ? stripNonDigits(whatsapp.number) : widget.guest.whatsappNumber);
    final email = _emailController.text.trim();
    final address = _addressController.text.trim();
    final wifiPassword = _wifiPasswordController.text.trim();

    Navigator.of(context).pop(
      GuestEditInput(
        firstName: firstName,
        lastName: lastName,
        documentType: _documentType,
        documentNumber: documentNumber,
        phoneCountryCode: phoneCountryCode,
        phoneNumber: phoneNumber,
        whatsappCountryCode: whatsappCountryCode,
        whatsappNumber: whatsappNumber,
        email: email.isEmpty ? null : email,
        address: address.isEmpty ? null : address,
        country: country,
        wifiPassword: wifiPassword.isEmpty ? null : wifiPassword,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KonektoBrand.surface,
      title: Text('Editar cadastro', style: KonektoBrand.display(fontSize: 16)),
      content: SizedBox(
        width: 420,
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
              Row(
                children: [
                  Expanded(child: _EditFormField(label: 'Nome', controller: _firstNameController)),
                  const SizedBox(width: 10),
                  Expanded(child: _EditFormField(label: 'Sobrenome', controller: _lastNameController)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: DropdownButtonFormField<DocumentType>(
                      initialValue: _documentType,
                      dropdownColor: KonektoBrand.surface,
                      style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
                      decoration: InputDecoration(
                        labelText: 'Documento',
                        labelStyle: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate),
                        isDense: true,
                        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.borderStrong)),
                        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.gold)),
                      ),
                      items: [for (final type in DocumentType.values) DropdownMenuItem(value: type, child: Text(type.label))],
                      onChanged: (value) => setState(() => _documentType = value ?? _documentType),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _EditFormField(
                      label: 'Número do documento',
                      controller: _documentNumberController,
                      inputFormatters: _documentType == DocumentType.cpf ? [CpfInputFormatter()] : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              IntlPhoneField(
                initialCountryCode: 'BR',
                initialValue: BrazilPhoneInputFormatter.format(widget.guest.phoneNumber),
                disableLengthCheck: true,
                inputFormatters: [BrazilPhoneInputFormatter()],
                style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
                dropdownTextStyle: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
                decoration: InputDecoration(
                  labelText: 'Telefone',
                  labelStyle: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate),
                  isDense: true,
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.borderStrong)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.gold)),
                ),
                onChanged: (phone) => _phone = phone,
              ),
              const SizedBox(height: 4),
              CheckboxListTile(
                value: _whatsappSameAsPhone,
                onChanged: (value) => setState(() => _whatsappSameAsPhone = value ?? true),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: KonektoBrand.gold,
                dense: true,
                title: Text(
                  'WhatsApp é o mesmo número do telefone',
                  style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.slate),
                ),
              ),
              if (!_whatsappSameAsPhone) ...[
                const SizedBox(height: 4),
                IntlPhoneField(
                  initialCountryCode: 'BR',
                  initialValue: widget.guest.whatsappNumber != null
                      ? BrazilPhoneInputFormatter.format(widget.guest.whatsappNumber!)
                      : null,
                  disableLengthCheck: true,
                  inputFormatters: [BrazilPhoneInputFormatter()],
                  style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
                  dropdownTextStyle: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
                  decoration: InputDecoration(
                    labelText: 'WhatsApp',
                    labelStyle: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate),
                    isDense: true,
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.borderStrong)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.gold)),
                  ),
                  onChanged: (phone) => _whatsapp = phone,
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 6),
              _EditFormField(label: 'E-mail (opcional)', controller: _emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _EditFormField(label: 'Endereço (opcional)', controller: _addressController),
              const SizedBox(height: 10),
              _EditFormField(label: 'País', controller: _countryController),
              const SizedBox(height: 10),
              _EditFormField(
                label: 'Senha de wifi (opcional — vazio usa a padrão do hotel)',
                controller: _wifiPasswordController,
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

class _EditFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _EditFormField({required this.label, required this.controller, this.keyboardType, this.inputFormatters});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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
