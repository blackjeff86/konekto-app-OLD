import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/guests_repository.dart';
import 'package:konekto_portal/data/stays_repository.dart';
import 'package:konekto_portal/features/guests/guest_detail_page.dart';
import 'package:konekto_portal/guest_app_config.dart';
import 'package:konekto_portal/models/guest.dart';
import 'package:konekto_portal/models/stay.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';
import 'package:konekto_portal/widgets/copyable_code_box.dart';

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

/// Dados pessoais coletados pelo formulário — sem `stayId`, resolvido
/// separadamente (quarto novo ou existente) antes de criar o hóspede.
class _GuestPersonalInput {
  final String firstName;
  final String lastName;
  final DocumentType documentType;
  final String documentNumber;
  final String phoneCountryCode;
  final String phoneNumber;
  final String? whatsappCountryCode;
  final String? whatsappNumber;
  final String? email;
  final String? address;
  final String country;
  final String? wifiPassword;

  const _GuestPersonalInput({
    required this.firstName,
    required this.lastName,
    required this.documentType,
    required this.documentNumber,
    required this.phoneCountryCode,
    required this.phoneNumber,
    this.whatsappCountryCode,
    this.whatsappNumber,
    this.email,
    this.address,
    required this.country,
    this.wifiPassword,
  });
}

class _GuestFormResult {
  final _GuestPersonalInput personal;
  final String stayId;

  const _GuestFormResult({required this.personal, required this.stayId});
}

/// Tela "Hóspedes" — lista plana de todas as pessoas cadastradas (de
/// qualquer quarto), cada uma com seu código individual. Criar um hóspede
/// vincula (ou cria na hora) o quarto/estadia dele — ver `_GuestFormDialog`.
/// Tocar numa linha abre a página de detalhe completa (substitui o modal
/// antigo). Gestão por quarto (vários hóspedes, avisos, fechar conta) fica
/// na tela "Quartos".
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
  final _staysRepository = StaysRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<Guest> _guests = const [];
  String? _viewingGuestId;

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
    final token = await _requireToken();
    if (token == null) return;

    List<Stay> activeStays;
    try {
      final stays = await _staysRepository.listStays(hotelId: widget.session.hotelId, token: token);
      activeStays = stays.where((stay) => stay.status == StayStatus.active).toList();
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
      return;
    }

    if (activeStays.isEmpty) {
      setState(
        () => _errorMessage = 'Nenhum quarto ocupado ainda — abra um quarto na aba Quartos antes de cadastrar um hóspede.',
      );
      return;
    }

    if (!mounted) return;
    final result = await showDialog<_GuestFormResult>(
      context: context,
      builder: (context) => _GuestFormDialog(activeStays: activeStays),
    );
    if (result == null) return;

    try {
      final guest = await _repository.createGuest(
        hotelId: widget.session.hotelId,
        token: token,
        input: NewGuestInput(
          stayId: result.stayId,
          firstName: result.personal.firstName,
          lastName: result.personal.lastName,
          documentType: result.personal.documentType,
          documentNumber: result.personal.documentNumber,
          phoneCountryCode: result.personal.phoneCountryCode,
          phoneNumber: result.personal.phoneNumber,
          whatsappCountryCode: result.personal.whatsappCountryCode,
          whatsappNumber: result.personal.whatsappNumber,
          email: result.personal.email,
          address: result.personal.address,
          country: result.personal.country,
          wifiPassword: result.personal.wifiPassword,
        ),
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
              CopyableCodeBox(value: guest.accessCode),
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

  void _openGuestDetail(Guest guest) {
    setState(() => _viewingGuestId = guest.id);
  }

  @override
  Widget build(BuildContext context) {
    final viewingGuestId = _viewingGuestId;
    if (viewingGuestId != null) {
      return GuestDetailPage(
        session: widget.session,
        authRepository: widget.authRepository,
        guestId: viewingGuestId,
        onBack: () {
          setState(() => _viewingGuestId = null);
          _load();
        },
      );
    }

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
            'Cada hóspede recebe um código individual pra entrar no app — sem senha, sem cadastro. Vários hóspedes do mesmo quarto ficam agrupados na aba Quartos.',
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
                      onTap: () => _openGuestDetail(guest),
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

class _GuestRow extends StatelessWidget {
  final Guest guest;
  final VoidCallback onTap;

  const _GuestRow({
    required this.guest,
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
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: KonektoBrand.slate),
          ],
        ),
      ),
    );
  }
}

class _GuestFormDialog extends StatefulWidget {
  final List<Stay> activeStays;

  const _GuestFormDialog({required this.activeStays});

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
  final _wifiPasswordController = TextEditingController();

  DocumentType _documentType = DocumentType.cpf;
  PhoneNumber? _phone;
  PhoneNumber? _whatsapp;
  bool _whatsappSameAsPhone = true;
  String? _errorMessage;
  late String _selectedStayId;

  @override
  void initState() {
    super.initState();
    _selectedStayId = widget.activeStays.first.id;
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

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        documentNumber.isEmpty ||
        country.isEmpty ||
        phone == null) {
      setState(
        () => _errorMessage = 'Preencha nome, sobrenome, documento, telefone e país.',
      );
      return;
    }

    final whatsapp = _whatsappSameAsPhone ? phone : _whatsapp;
    final email = _emailController.text.trim();
    final address = _addressController.text.trim();
    final wifiPassword = _wifiPasswordController.text.trim();

    final personal = _GuestPersonalInput(
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
      wifiPassword: wifiPassword.isEmpty ? null : wifiPassword,
    );

    Navigator.of(context).pop(_GuestFormResult(personal: personal, stayId: _selectedStayId));
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
              DropdownButtonFormField<String>(
                initialValue: _selectedStayId,
                dropdownColor: KonektoBrand.surface,
                style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
                decoration: InputDecoration(
                  labelText: 'Quarto',
                  labelStyle: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate),
                  isDense: true,
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.borderStrong)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.gold)),
                ),
                items: [
                  for (final stay in widget.activeStays)
                    DropdownMenuItem(
                      value: stay.id,
                      child: Text('Quarto ${stay.roomNumber} (${stay.guests.length} hóspede${stay.guests.length == 1 ? '' : 's'})'),
                    ),
                ],
                onChanged: (value) => setState(() => _selectedStayId = value ?? widget.activeStays.first.id),
              ),
              const SizedBox(height: 10),
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
              _FormField(
                label: 'País',
                controller: _countryController,
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

