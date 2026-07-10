import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/guests_repository.dart';
import 'package:konekto_portal/guest_app_config.dart';
import 'package:konekto_portal/models/guest.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

void _copyToClipboard(BuildContext context, String value) {
  Clipboard.setData(ClipboardData(text: value));
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Copiado.')));
}

String _inviteMessage(Guest guest) {
  return 'Olá, ${guest.fullName}! Seu check-in foi confirmado (quarto ${guest.roomNumber}).\n'
      'Acesse $guestAppUrl e digite o código ${guest.accessCode} para começar.';
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

/// Tela "Hóspedes" — cadastro completo (documento, contato, estadia),
/// gera um código individual e permite revogar acesso. Disponível pra
/// `gerente` e `recepcao` (diferente de Configurações).
class GuestsPage extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const GuestsPage({
    super.key,
    required this.session,
    required this.authRepository,
  });

  @override
  State<GuestsPage> createState() => _GuestsPageState();
}

class _GuestsPageState extends State<GuestsPage> {
  final _repository = GuestsRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<Guest> _guests = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String?> _requireToken() async {
    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(
        () => _errorMessage = 'Sessão expirada — saia e entre novamente.',
      );
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
      final guests = await _repository.listGuests(
        hotelId: widget.session.hotelId,
        token: token,
      );
      setState(() => _guests = guests);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createGuest() async {
    final input = await showDialog<NewGuestInput>(
      context: context,
      builder: (context) => const _GuestFormDialog(),
    );
    if (input == null) return;

    final token = await _requireToken();
    if (token == null) return;

    try {
      final guest = await _repository.createGuest(
        hotelId: widget.session.hotelId,
        token: token,
        input: input,
      );
      await _load();
      if (mounted) await _showAccessCodeDialog(guest);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _showAccessCodeDialog(Guest guest) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KonektoBrand.surface,
        title: Text(
          'Hóspede criado',
          style: KonektoBrand.display(fontSize: 16),
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Código de acesso:', style: KonektoBrand.body(fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: KonektoBrand.borderStrong),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        guest.accessCode,
                        style: KonektoBrand.display(
                          fontSize: 18,
                          color: KonektoBrand.goldLight,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copiar código',
                      icon: const Icon(
                        Icons.copy_outlined,
                        size: 18,
                        color: KonektoBrand.slate,
                      ),
                      onPressed: () =>
                          _copyToClipboard(context, guest.accessCode),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ou copie a mensagem pronta pra mandar por WhatsApp/e-mail:',
                style: KonektoBrand.body(fontSize: 13),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _copyToClipboard(context, _inviteMessage(guest)),
                  icon: const Icon(
                    Icons.content_copy,
                    size: 16,
                    color: KonektoBrand.goldLight,
                  ),
                  label: Text(
                    'Copiar mensagem',
                    style: KonektoBrand.body(
                      fontSize: 13,
                      color: KonektoBrand.goldLight,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: KonektoBrand.borderStrong),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showGuestDetails(Guest guest) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KonektoBrand.surface,
        title: Text(guest.fullName, style: KonektoBrand.display(fontSize: 16)),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailLine(
                  label: 'Documento',
                  value:
                      '${guest.documentType.label} · ${guest.documentNumber}',
                ),
                _DetailLine(
                  label: 'Telefone',
                  value: '${guest.phoneCountryCode} ${guest.phoneNumber}',
                ),
                if (guest.whatsappNumber != null)
                  _DetailLine(
                    label: 'WhatsApp',
                    value:
                        '${guest.whatsappCountryCode} ${guest.whatsappNumber}',
                  ),
                if (guest.email != null)
                  _DetailLine(label: 'E-mail', value: guest.email!),
                if (guest.address != null)
                  _DetailLine(label: 'Endereço', value: guest.address!),
                _DetailLine(label: 'País', value: guest.country),
                _DetailLine(label: 'Quarto', value: guest.roomNumber),
                _DetailLine(
                  label: 'Estadia',
                  value:
                      '${_formatDate(guest.checkInDate)} até ${_formatDate(guest.checkOutDate)}',
                ),
                _DetailLine(
                  label: 'Senha de wifi',
                  value: guest.wifiPassword ?? 'Padrão do hotel',
                ),
                _DetailLine(label: 'Código de acesso', value: guest.accessCode),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _revokeGuest(Guest guest) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KonektoBrand.surface,
        title: Text(
          'Revogar acesso?',
          style: KonektoBrand.display(fontSize: 16),
        ),
        content: Text(
          '"${guest.fullName}" (quarto ${guest.roomNumber}) não vai mais conseguir entrar no app com esse código.',
          style: KonektoBrand.body(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revogar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final token = await _requireToken();
    if (token == null) return;

    try {
      await _repository.revokeGuest(
        hotelId: widget.session.hotelId,
        guestId: guest.id,
        token: token,
      );
      await _load();
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hóspedes',
                  style: KonektoBrand.display(fontSize: 18),
                ),
              ),
              TextButton.icon(
                onPressed: _createGuest,
                icon: const Icon(
                  Icons.person_add_alt_1,
                  size: 18,
                  color: KonektoBrand.goldLight,
                ),
                label: Text(
                  'Criar hóspede',
                  style: KonektoBrand.body(
                    fontSize: 12.5,
                    color: KonektoBrand.goldLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Cada hóspede recebe um código individual pra entrar no app — sem senha, sem cadastro.',
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
          if (_guests.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: KonektoBrand.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KonektoBrand.borderStrong),
              ),
              child: Text(
                'Nenhum hóspede cadastrado ainda.',
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
                  for (final guest in _guests) ...[
                    if (guest != _guests.first)
                      const Divider(
                        height: 1,
                        color: KonektoBrand.borderStrong,
                      ),
                    _GuestRow(
                      guest: guest,
                      onRevoke: () => _revokeGuest(guest),
                      onTap: () => _showGuestDetails(guest),
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
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: KonektoBrand.body(fontSize: 13, color: KonektoBrand.cream),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestRow extends StatelessWidget {
  final Guest guest;
  final VoidCallback onRevoke;
  final VoidCallback onTap;

  const _GuestRow({
    required this.guest,
    required this.onRevoke,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = guest.status == GuestStatus.active;
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
                    guest.fullName,
                    style: KonektoBrand.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: KonektoBrand.cream,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Quarto ${guest.roomNumber}  ·  ${guest.accessCode}  ·  ${_formatDate(guest.checkInDate)}–${_formatDate(guest.checkOutDate)}',
                    style: KonektoBrand.body(
                      fontSize: 12,
                      color: KonektoBrand.slate,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? KonektoBrand.gold.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isActive ? 'Ativo' : 'Revogado',
                style: KonektoBrand.body(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? KonektoBrand.goldLight
                      : KonektoBrand.slateSoft,
                ),
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Revogar acesso',
                icon: const Icon(
                  Icons.block,
                  size: 18,
                  color: KonektoBrand.slate,
                ),
                onPressed: onRevoke,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuestFormDialog extends StatefulWidget {
  const _GuestFormDialog();

  @override
  State<_GuestFormDialog> createState() => _GuestFormDialogState();
}

class _GuestFormDialogState extends State<_GuestFormDialog> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _countryController = TextEditingController();
  final _roomController = TextEditingController();
  final _wifiPasswordController = TextEditingController();

  DocumentType _documentType = DocumentType.cpf;
  PhoneNumber? _phone;
  PhoneNumber? _whatsapp;
  bool _whatsappSameAsPhone = true;
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _documentNumberController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _roomController.dispose();
    _wifiPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isCheckIn}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn
          ? (_checkInDate ?? now)
          : (_checkOutDate ?? _checkInDate ?? now),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() {
      if (isCheckIn) {
        _checkInDate = picked;
      } else {
        _checkOutDate = picked;
      }
    });
  }

  void _submit() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final documentNumber = _documentNumberController.text.trim();
    final country = _countryController.text.trim();
    final roomNumber = _roomController.text.trim();
    final phone = _phone;
    final checkInDate = _checkInDate;
    final checkOutDate = _checkOutDate;

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        documentNumber.isEmpty ||
        country.isEmpty ||
        roomNumber.isEmpty ||
        phone == null ||
        checkInDate == null ||
        checkOutDate == null) {
      setState(
        () => _errorMessage =
            'Preencha nome, sobrenome, documento, telefone, país, quarto e as datas de estadia.',
      );
      return;
    }
    if (checkOutDate.isBefore(checkInDate)) {
      setState(
        () => _errorMessage =
            'A data de saída não pode ser antes da data de entrada.',
      );
      return;
    }

    final whatsapp = _whatsappSameAsPhone ? phone : _whatsapp;
    final email = _emailController.text.trim();
    final address = _addressController.text.trim();
    final wifiPassword = _wifiPasswordController.text.trim();

    Navigator.of(context).pop(
      NewGuestInput(
        firstName: firstName,
        lastName: lastName,
        documentType: _documentType,
        documentNumber: documentNumber,
        phoneCountryCode: phone.countryCode,
        phoneNumber: phone.number,
        whatsappCountryCode: whatsapp?.countryCode,
        whatsappNumber: whatsapp?.number,
        email: email.isEmpty ? null : email,
        address: address.isEmpty ? null : address,
        country: country,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        roomNumber: roomNumber,
        wifiPassword: wifiPassword.isEmpty ? null : wifiPassword,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KonektoBrand.surface,
      title: Text('Criar hóspede', style: KonektoBrand.display(fontSize: 16)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                const SizedBox(height: 14),
              ],
              Row(
                children: [
                  Expanded(
                    child: _FormField(
                      label: 'Nome',
                      controller: _firstNameController,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FormField(
                      label: 'Sobrenome',
                      controller: _lastNameController,
                    ),
                  ),
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
                      style: KonektoBrand.body(
                        fontSize: 13.5,
                        color: KonektoBrand.cream,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Documento',
                        labelStyle: KonektoBrand.body(
                          fontSize: 12,
                          color: KonektoBrand.slate,
                        ),
                        isDense: true,
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: KonektoBrand.borderStrong,
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: KonektoBrand.gold),
                        ),
                      ),
                      items: [
                        for (final type in DocumentType.values)
                          DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          ),
                      ],
                      onChanged: (value) => setState(
                        () => _documentType = value ?? _documentType,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FormField(
                      label: 'Número do documento',
                      controller: _documentNumberController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              IntlPhoneField(
                initialCountryCode: 'BR',
                style: KonektoBrand.body(
                  fontSize: 13.5,
                  color: KonektoBrand.cream,
                ),
                dropdownTextStyle: KonektoBrand.body(
                  fontSize: 13.5,
                  color: KonektoBrand.cream,
                ),
                decoration: InputDecoration(
                  labelText: 'Telefone',
                  labelStyle: KonektoBrand.body(
                    fontSize: 12,
                    color: KonektoBrand.slate,
                  ),
                  isDense: true,
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: KonektoBrand.borderStrong),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: KonektoBrand.gold),
                  ),
                ),
                onChanged: (phone) => _phone = phone,
              ),
              const SizedBox(height: 4),
              CheckboxListTile(
                value: _whatsappSameAsPhone,
                onChanged: (value) =>
                    setState(() => _whatsappSameAsPhone = value ?? true),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: KonektoBrand.gold,
                dense: true,
                title: Text(
                  'WhatsApp é o mesmo número do telefone',
                  style: KonektoBrand.body(
                    fontSize: 12.5,
                    color: KonektoBrand.slate,
                  ),
                ),
              ),
              if (!_whatsappSameAsPhone) ...[
                const SizedBox(height: 4),
                IntlPhoneField(
                  initialCountryCode: 'BR',
                  style: KonektoBrand.body(
                    fontSize: 13.5,
                    color: KonektoBrand.cream,
                  ),
                  dropdownTextStyle: KonektoBrand.body(
                    fontSize: 13.5,
                    color: KonektoBrand.cream,
                  ),
                  decoration: InputDecoration(
                    labelText: 'WhatsApp',
                    labelStyle: KonektoBrand.body(
                      fontSize: 12,
                      color: KonektoBrand.slate,
                    ),
                    isDense: true,
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: KonektoBrand.borderStrong),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: KonektoBrand.gold),
                    ),
                  ),
                  onChanged: (phone) => _whatsapp = phone,
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 6),
              _FormField(
                label: 'E-mail (opcional)',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              _FormField(
                label: 'Endereço (opcional)',
                controller: _addressController,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _FormField(
                      label: 'País',
                      controller: _countryController,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FormField(
                      label: 'Número do quarto',
                      controller: _roomController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _DatePickerField(
                      label: 'Check-in',
                      date: _checkInDate,
                      onTap: () => _pickDate(isCheckIn: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DatePickerField(
                      label: 'Check-out',
                      date: _checkOutDate,
                      onTap: () => _pickDate(isCheckIn: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _FormField(
                label: 'Senha de wifi (opcional — vazio usa a padrão do hotel)',
                controller: _wifiPasswordController,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: _submit, child: const Text('Criar')),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _FormField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate),
        isDense: true,
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: KonektoBrand.borderStrong),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: KonektoBrand.gold),
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: KonektoBrand.body(
            fontSize: 12,
            color: KonektoBrand.slate,
          ),
          isDense: true,
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: KonektoBrand.borderStrong),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: KonektoBrand.gold),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date != null ? _formatDate(date!) : 'Selecionar',
              style: KonektoBrand.body(
                fontSize: 13.5,
                color: date != null
                    ? KonektoBrand.cream
                    : KonektoBrand.slateSoft,
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: KonektoBrand.slate,
            ),
          ],
        ),
      ),
    );
  }
}
