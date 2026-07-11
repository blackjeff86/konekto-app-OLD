import 'package:flutter/material.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/guests_repository.dart';
import 'package:konekto_portal/data/stays_repository.dart';
import 'package:konekto_portal/features/guests/guest_detail_page.dart';
import 'package:konekto_portal/models/guest.dart' show DocumentType, NewGuestInput;
import 'package:konekto_portal/models/stay.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

/// Detalhe de uma estadia (quarto) — todos os hóspedes vinculados, aviso
/// pra todos de uma vez, e o fechamento de conta (revoga todo mundo e
/// mostra um resumo de consumo antes de confirmar).
///
/// Renderizado NO LUGAR do conteúdo (não via `Navigator.push`) — mesmo
/// padrão de `ServiceItemsPage`/`onBack` — pra manter o menu lateral do
/// portal sempre visível. O detalhe de um hóspede aberto a partir daqui
/// (`_viewingGuestId`) segue o mesmo padrão, aninhado dentro desta página.
class StayDetailPage extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;
  final String stayId;
  final VoidCallback onBack;

  const StayDetailPage({
    super.key,
    required this.session,
    required this.authRepository,
    required this.stayId,
    required this.onBack,
  });

  @override
  State<StayDetailPage> createState() => _StayDetailPageState();
}

class _StayDetailPageState extends State<StayDetailPage> {
  final _repository = StaysRepository();
  final _guestsRepository = GuestsRepository();
  final _noticeController = TextEditingController();

  bool _isLoading = true;
  bool _isSendingNotice = false;
  String? _errorMessage;
  Stay? _stay;
  String? _viewingGuestId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noticeController.dispose();
    super.dispose();
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
      final stay = await _repository.getStay(hotelId: widget.session.hotelId, stayId: widget.stayId, token: token);
      setState(() => _stay = stay);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addGuest() async {
    final input = await showDialog<NewGuestInput>(
      context: context,
      builder: (context) => _AddGuestDialog(stayId: widget.stayId),
    );
    if (input == null) return;

    final token = await _requireToken();
    if (token == null) return;
    try {
      final guest = await _guestsRepository.createGuest(hotelId: widget.session.hotelId, token: token, input: input);
      await _load();
      if (mounted) await _showAccessCodeDialog(guest.accessCode);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _showAccessCodeDialog(String accessCode) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KonektoBrand.surface,
        title: Text('Hóspede criado', style: KonektoBrand.display(fontSize: 16)),
        content: Text('Código de acesso: $accessCode', style: KonektoBrand.body(fontSize: 14, color: KonektoBrand.goldLight)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar')),
        ],
      ),
    );
  }

  Future<void> _sendNotice() async {
    final message = _noticeController.text.trim();
    if (message.isEmpty) return;

    final token = await _requireToken();
    if (token == null) return;

    setState(() => _isSendingNotice = true);
    try {
      await _repository.sendNotice(hotelId: widget.session.hotelId, stayId: widget.stayId, token: token, message: message);
      _noticeController.clear();
      await _load();
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSendingNotice = false);
    }
  }

  double _consumptionTotal(Stay stay) {
    double total = 0;
    for (final guest in stay.guests) {
      for (final order in guest.orders) {
        if (order.price != null) total += order.price! * order.quantity;
      }
    }
    return total;
  }

  Future<void> _closeAccount(Stay stay) async {
    final total = _consumptionTotal(stay);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KonektoBrand.surface,
        title: Text('Fechar conta do quarto ${stay.roomNumber}?', style: KonektoBrand.display(fontSize: 16)),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Isso revoga o código de acesso de todos os ${stay.guests.length} hóspede${stay.guests.length == 1 ? '' : 's'} deste quarto — ninguém mais consegue entrar no app.',
                style: KonektoBrand.body(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text('Total consumido:', style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate)),
              Text(
                'R\$ ${total.toStringAsFixed(2)}',
                style: KonektoBrand.display(fontSize: 20, color: KonektoBrand.goldLight),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Fechar conta')),
        ],
      ),
    );
    if (confirmed != true) return;

    final token = await _requireToken();
    if (token == null) return;
    try {
      await _repository.closeStay(hotelId: widget.session.hotelId, stayId: widget.stayId, token: token);
      await _load();
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  void _openGuestDetail(StayGuestSummary guestSummary) {
    setState(() => _viewingGuestId = guestSummary.id);
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
      return const Center(child: CircularProgressIndicator(color: KonektoBrand.gold));
    }
    final stay = _stay;
    if (stay == null) {
      return Center(child: Text(_errorMessage ?? 'Não encontrado.', style: KonektoBrand.body(fontSize: 13.5)));
    }
    return _buildBody(stay);
  }

  Widget _buildBody(Stay stay) {
    final isActive = stay.status == StayStatus.active;
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
                Expanded(child: Text('Quarto ${stay.roomNumber}', style: KonektoBrand.display(fontSize: 18))),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_formatDate(stay.checkInDate)} até ${_formatDate(stay.checkOutDate)}',
                          style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? KonektoBrand.gold.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          stay.status.label,
                          style: KonektoBrand.body(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isActive ? KonektoBrand.goldLight : KonektoBrand.slateSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _closeAccount(stay),
                        icon: const Icon(Icons.receipt_long_outlined, size: 16, color: Color(0xFFF1A6A0)),
                        label: Text('Fechar conta', style: KonektoBrand.body(fontSize: 13, color: const Color(0xFFF1A6A0))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0x4DDC2626)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text('Hóspedes', style: KonektoBrand.display(fontSize: 15))),
                if (isActive)
                  TextButton.icon(
                    onPressed: _addGuest,
                    icon: const Icon(Icons.person_add_alt_1, size: 16, color: KonektoBrand.goldLight),
                    label: Text('Adicionar', style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.goldLight)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: KonektoBrand.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KonektoBrand.borderStrong),
              ),
              child: stay.guests.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Nenhum hóspede neste quarto ainda.', style: KonektoBrand.body(fontSize: 13.5)),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final guest in stay.guests) ...[
                          if (guest != stay.guests.first) const Divider(height: 1, color: KonektoBrand.borderStrong),
                          _StayGuestRow(guest: guest, onTap: () => _openGuestDetail(guest)),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            Text('Enviar aviso', style: KonektoBrand.display(fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              'Vai pra todos os hóspedes deste quarto de uma vez, dentro do app deles.',
              style: KonektoBrand.body(fontSize: 12.5),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _noticeController,
                    maxLines: 2,
                    style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
                    decoration: InputDecoration(
                      hintText: 'Ex: seu jantar está pronto, checkout às 12h...',
                      hintStyle: KonektoBrand.body(fontSize: 13, color: KonektoBrand.slateSoft),
                      isDense: true,
                      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.borderStrong)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.gold)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _isSendingNotice ? null : _sendNotice,
                  icon: _isSendingNotice
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, color: KonektoBrand.goldLight),
                ),
              ],
            ),
            if (stay.notices.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final notice in stay.notices) _NoticeLine(notice: notice),
            ],
          ],
        ),
      ),
    );
  }
}

class _StayGuestRow extends StatelessWidget {
  final StayGuestSummary guest;
  final VoidCallback onTap;

  const _StayGuestRow({required this.guest, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = guest.status == 'active';
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
                    style: KonektoBrand.body(fontSize: 14, fontWeight: FontWeight.w700, color: KonektoBrand.cream),
                  ),
                  const SizedBox(height: 2),
                  Text(guest.accessCode, style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate)),
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
                isActive ? 'Ativo' : 'Revogado',
                style: KonektoBrand.body(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? KonektoBrand.goldLight : KonektoBrand.slateSoft,
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

class _NoticeLine extends StatelessWidget {
  final StayNotice notice;

  const _NoticeLine({required this.notice});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: KonektoBrand.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: KonektoBrand.borderStrong),
        ),
        child: Text(notice.message, style: KonektoBrand.body(fontSize: 13, color: KonektoBrand.cream)),
      ),
    );
  }
}

/// Formulário enxuto pra adicionar um hóspede a uma Stay já conhecida —
/// sem os campos de quarto/datas (aqueles moram na Stay, não por pessoa).
class _AddGuestDialog extends StatefulWidget {
  final String stayId;

  const _AddGuestDialog({required this.stayId});

  @override
  State<_AddGuestDialog> createState() => _AddGuestDialogState();
}

class _AddGuestDialogState extends State<_AddGuestDialog> {
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

    if (firstName.isEmpty || lastName.isEmpty || documentNumber.isEmpty || country.isEmpty || phone == null) {
      setState(() => _errorMessage = 'Preencha nome, sobrenome, documento, telefone e país.');
      return;
    }

    final whatsapp = _whatsappSameAsPhone ? phone : _whatsapp;
    final email = _emailController.text.trim();
    final address = _addressController.text.trim();
    final wifiPassword = _wifiPasswordController.text.trim();

    Navigator.of(context).pop(
      NewGuestInput(
        stayId: widget.stayId,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KonektoBrand.surface,
      title: Text('Adicionar hóspede', style: KonektoBrand.display(fontSize: 16)),
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
                  Expanded(child: _FormField(label: 'Nome', controller: _firstNameController)),
                  const SizedBox(width: 10),
                  Expanded(child: _FormField(label: 'Sobrenome', controller: _lastNameController)),
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
                  Expanded(child: _FormField(label: 'Número do documento', controller: _documentNumberController)),
                ],
              ),
              const SizedBox(height: 10),
              IntlPhoneField(
                initialCountryCode: 'BR',
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
              _FormField(label: 'E-mail (opcional)', controller: _emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _FormField(label: 'Endereço (opcional)', controller: _addressController),
              const SizedBox(height: 10),
              _FormField(label: 'País', controller: _countryController),
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
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        TextButton(onPressed: _submit, child: const Text('Adicionar')),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _FormField({required this.label, required this.controller, this.keyboardType});

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
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.borderStrong)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.gold)),
      ),
    );
  }
}
