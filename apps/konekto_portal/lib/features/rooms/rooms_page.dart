import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/guests_repository.dart';
import 'package:konekto_portal/data/rooms_repository.dart';
import 'package:konekto_portal/data/stays_repository.dart';
import 'package:konekto_portal/features/rooms/stay_detail_page.dart';
import 'package:konekto_portal/models/guest.dart';
import 'package:konekto_portal/models/room.dart';
import 'package:konekto_portal/models/stay.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';
import 'package:konekto_portal/utils/input_formatters.dart';
import 'package:konekto_portal/widgets/copyable_code_box.dart';

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

/// Tela "Quartos" — mapa visual de todos os quartos cadastrados (ver
/// Configurações → Quartos), separado em duas seções (vagos/ocupados) pra
/// ficar claro de relance quem precisa de atenção. Tocar num quarto
/// ocupado abre o detalhe da estadia (`StayDetailPage`, com hóspedes,
/// avisos, valor em aberto, estender/fechar conta); tocar num quarto vago
/// abre o formulário de ocupação (datas + cadastro do hóspede, com busca
/// por documento pra reaproveitar quem já se hospedou antes).
class RoomsPage extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const RoomsPage({super.key, required this.session, required this.authRepository});

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  final _repository = RoomsRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<Room> _rooms = const [];
  String? _viewingRoomId;

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
      final rooms = await _repository.listRooms(hotelId: widget.session.hotelId, token: token);
      setState(() => _rooms = rooms);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewingRoomId = _viewingRoomId;
    if (viewingRoomId != null) {
      final matches = _rooms.where((room) => room.id == viewingRoomId);
      final room = matches.isEmpty ? null : matches.first;
      if (room == null) {
        // Quarto sumiu da lista (removido em outra aba, ex.) — volta pro mapa.
        _viewingRoomId = null;
      } else if (room.isOccupied) {
        return StayDetailPage(
          session: widget.session,
          authRepository: widget.authRepository,
          stayId: room.activeStay!.id,
          onBack: () {
            setState(() => _viewingRoomId = null);
            _load();
          },
        );
      } else {
        return _FreeRoomDetail(
          session: widget.session,
          authRepository: widget.authRepository,
          room: room,
          onBack: () => setState(() => _viewingRoomId = null),
          onStayCreated: _load,
        );
      }
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: KonektoBrand.gold));
    }

    final freeRooms = _rooms.where((room) => !room.isOccupied).toList();
    final occupiedRooms = _rooms.where((room) => room.isOccupied).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Quartos', style: KonektoBrand.display(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            'Toque num quarto vago pra registrar um hóspede e iniciar a estadia — ou num quarto ocupado pra ver hóspedes, avisos e o valor em aberto.',
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
          if (_rooms.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: KonektoBrand.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KonektoBrand.borderStrong),
              ),
              child: Text(
                'Nenhum quarto cadastrado ainda — cadastre em Configurações → Quartos.',
                style: KonektoBrand.body(fontSize: 13.5),
              ),
            )
          else ...[
            _RoomSection(
              title: 'Quartos vagos',
              count: freeRooms.length,
              rooms: freeRooms,
              onTapRoom: (room) => setState(() => _viewingRoomId = room.id),
            ),
            const SizedBox(height: 28),
            _RoomSection(
              title: 'Quartos ocupados',
              count: occupiedRooms.length,
              rooms: occupiedRooms,
              onTapRoom: (room) => setState(() => _viewingRoomId = room.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoomSection extends StatelessWidget {
  final String title;
  final int count;
  final List<Room> rooms;
  final ValueChanged<Room> onTapRoom;

  const _RoomSection({required this.title, required this.count, required this.rooms, required this.onTapRoom});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(title, style: KonektoBrand.display(fontSize: 15)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(999)),
              child: Text('$count', style: KonektoBrand.body(fontSize: 11.5, fontWeight: FontWeight.w600, color: KonektoBrand.slate)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (rooms.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: KonektoBrand.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KonektoBrand.borderStrong),
            ),
            child: Text('Nenhum quarto nessa situação agora.', style: KonektoBrand.body(fontSize: 13)),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [for (final room in rooms) _RoomCard(room: room, onTap: () => onTapRoom(room))],
          ),
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback onTap;

  const _RoomCard({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final occupied = room.isOccupied;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 172,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: KonektoBrand.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: occupied ? KonektoBrand.gold.withValues(alpha: 0.5) : KonektoBrand.borderStrong),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  occupied ? Icons.bed_outlined : Icons.meeting_room_outlined,
                  size: 22,
                  color: occupied ? KonektoBrand.goldLight : KonektoBrand.slate,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: occupied ? KonektoBrand.gold.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    occupied ? 'Ocupado' : 'Livre',
                    style: KonektoBrand.body(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: occupied ? KonektoBrand.goldLight : KonektoBrand.slateSoft,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Quarto ${room.number}', style: KonektoBrand.body(fontSize: 15, fontWeight: FontWeight.w700, color: KonektoBrand.cream)),
            if (occupied) ...[
              const SizedBox(height: 4),
              Text(
                '${room.activeStay!.guestCount} hóspede${room.activeStay!.guestCount == 1 ? '' : 's'}',
                style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate),
              ),
              const SizedBox(height: 4),
              Text(
                'R\$ ${room.activeStay!.consumptionTotal.toStringAsFixed(2)}',
                style: KonektoBrand.body(fontSize: 12.5, fontWeight: FontWeight.w600, color: KonektoBrand.goldLight),
              ),
            ] else if (room.description != null && room.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                room.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Detalhe de um quarto VAGO — informações do quarto + o formulário
/// completo de ocupação bem abaixo, na mesma página (nada de modal): datas
/// da estadia e o cadastro do hóspede, que pode ser buscado pelo documento
/// (reaproveita os dados de quem já se hospedou antes) ou preenchido do
/// zero se for realmente um hóspede novo.
class _FreeRoomDetail extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;
  final Room room;
  final VoidCallback onBack;
  final VoidCallback onStayCreated;

  const _FreeRoomDetail({
    required this.session,
    required this.authRepository,
    required this.room,
    required this.onBack,
    required this.onStayCreated,
  });

  @override
  State<_FreeRoomDetail> createState() => _FreeRoomDetailState();
}

class _FreeRoomDetailState extends State<_FreeRoomDetail> {
  final _staysRepository = StaysRepository();
  final _guestsRepository = GuestsRepository();

  final _documentNumberController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _countryController = TextEditingController();
  final _wifiPasswordController = TextEditingController();

  DocumentType _documentType = DocumentType.cpf;
  PhoneNumber? _phone;
  PhoneNumber? _whatsapp;
  bool _whatsappSameAsPhone = true;
  String? _prefillPhone;
  String? _prefillWhatsapp;
  int _prefillGeneration = 0;

  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  bool _isSearching = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _lookupBanner;
  bool _lookupBannerFound = false;

  @override
  void dispose() {
    _documentNumberController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _wifiPasswordController.dispose();
    super.dispose();
  }

  Future<String?> _requireToken() async {
    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(() => _errorMessage = 'Sessão expirada — saia e entre novamente.');
    }
    return token;
  }

  Future<void> _pickDate({required bool isCheckIn}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? (_checkInDate ?? now) : (_checkOutDate ?? _checkInDate ?? now),
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

  Future<void> _searchGuest() async {
    final documentNumber = _documentNumberController.text.trim();
    if (documentNumber.isEmpty) {
      setState(() => _errorMessage = 'Digite o número do documento pra buscar.');
      return;
    }
    final token = await _requireToken();
    if (token == null) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _lookupBanner = null;
    });
    try {
      final result = await _guestsRepository.lookupByDocument(
        hotelId: widget.session.hotelId,
        token: token,
        documentNumber: documentNumber,
      );
      if (result == null) {
        setState(() {
          _lookupBanner = 'Nenhum cadastro encontrado com esse documento — preencha os dados de um novo hóspede.';
          _lookupBannerFound = false;
        });
        return;
      }
      setState(() {
        _documentType = result.documentType;
        _firstNameController.text = result.firstName;
        _lastNameController.text = result.lastName;
        _emailController.text = result.email ?? '';
        _addressController.text = result.address ?? '';
        _countryController.text = result.country;
        _prefillPhone = BrazilPhoneInputFormatter.format(result.phoneNumber);
        _prefillWhatsapp = result.whatsappNumber != null ? BrazilPhoneInputFormatter.format(result.whatsappNumber!) : null;
        _whatsappSameAsPhone = result.whatsappNumber == null || result.whatsappNumber == result.phoneNumber;
        _prefillGeneration++;
        _lookupBanner = 'Hóspede encontrado: ${result.firstName} ${result.lastName} — dados preenchidos, revise se necessário.';
        _lookupBannerFound = true;
      });
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _submit() async {
    final checkInDate = _checkInDate;
    final checkOutDate = _checkOutDate;
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final documentNumber = _documentNumberController.text.trim();
    final country = _countryController.text.trim();
    final phone = _phone;

    if (checkInDate == null || checkOutDate == null) {
      setState(() => _errorMessage = 'Preencha as datas de check-in e check-out.');
      return;
    }
    if (checkOutDate.isBefore(checkInDate)) {
      setState(() => _errorMessage = 'A data de saída não pode ser antes da data de entrada.');
      return;
    }
    if (firstName.isEmpty || lastName.isEmpty || documentNumber.isEmpty || country.isEmpty || phone == null) {
      setState(() => _errorMessage = 'Preencha nome, sobrenome, documento, telefone e país do hóspede.');
      return;
    }

    final token = await _requireToken();
    if (token == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final stay = await _staysRepository.createStay(
        hotelId: widget.session.hotelId,
        token: token,
        input: NewStayInput(roomId: widget.room.id, checkInDate: checkInDate, checkOutDate: checkOutDate),
      );
      final whatsapp = _whatsappSameAsPhone ? phone : _whatsapp;
      final email = _emailController.text.trim();
      final address = _addressController.text.trim();
      final wifiPassword = _wifiPasswordController.text.trim();

      final guest = await _guestsRepository.createGuest(
        hotelId: widget.session.hotelId,
        token: token,
        input: NewGuestInput(
          stayId: stay.id,
          firstName: firstName,
          lastName: lastName,
          documentType: _documentType,
          documentNumber: documentNumber,
          phoneCountryCode: phone.countryCode,
          phoneNumber: stripNonDigits(phone.number),
          whatsappCountryCode: whatsapp?.countryCode,
          whatsappNumber: whatsapp != null ? stripNonDigits(whatsapp.number) : null,
          email: email.isEmpty ? null : email,
          address: address.isEmpty ? null : address,
          country: country,
          wifiPassword: wifiPassword.isEmpty ? null : wifiPassword,
        ),
      );
      widget.onStayCreated();
      if (mounted) await _showAccessCodeDialog(guest.accessCode);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showAccessCodeDialog(String accessCode) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KonektoBrand.surface,
        title: Text('Hóspede registrado', style: KonektoBrand.display(fontSize: 16)),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Código de acesso:', style: KonektoBrand.body(fontSize: 13)),
              const SizedBox(height: 8),
              CopyableCodeBox(value: accessCode),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar')),
        ],
      ),
    );
  }

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
                IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back, size: 18, color: KonektoBrand.slate)),
                Expanded(child: Text('Quarto ${widget.room.number}', style: KonektoBrand.display(fontSize: 18))),
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
              child: Row(
                children: [
                  Expanded(child: Text('Este quarto está livre.', style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(999)),
                    child: Text('Livre', style: KonektoBrand.body(fontSize: 11, fontWeight: FontWeight.w600, color: KonektoBrand.slateSoft)),
                  ),
                ],
              ),
            ),
            if (widget.room.description != null && widget.room.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(widget.room.description!, style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.slate)),
            ],
            const SizedBox(height: 24),
            Text('Nova estadia', style: KonektoBrand.display(fontSize: 15)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _DatePickerField(label: 'Check-in', date: _checkInDate, onTap: () => _pickDate(isCheckIn: true))),
                const SizedBox(width: 10),
                Expanded(child: _DatePickerField(label: 'Check-out', date: _checkOutDate, onTap: () => _pickDate(isCheckIn: false))),
              ],
            ),
            const SizedBox(height: 24),
            Text('Hóspede', style: KonektoBrand.display(fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              'Busque pelo documento pra reaproveitar o cadastro de quem já se hospedou antes, ou preencha um hóspede novo.',
              style: KonektoBrand.body(fontSize: 12.5),
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
                  child: _FormField(
                    label: _documentType == DocumentType.cpf ? 'CPF' : 'Número do documento',
                    controller: _documentNumberController,
                    inputFormatters: _documentType == DocumentType.cpf ? [CpfInputFormatter()] : null,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _isSearching ? null : _searchGuest,
                    icon: _isSearching
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.search, size: 16, color: KonektoBrand.goldLight),
                    label: Text('Buscar', style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.goldLight)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: KonektoBrand.borderStrong)),
                  ),
                ),
              ],
            ),
            if (_lookupBanner != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: (_lookupBannerFound ? KonektoBrand.gold : KonektoBrand.slate).withValues(alpha: 0.1),
                  border: Border.all(color: (_lookupBannerFound ? KonektoBrand.gold : KonektoBrand.slate).withValues(alpha: 0.35)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      _lookupBannerFound ? Icons.check_circle_outline : Icons.info_outline,
                      size: 16,
                      color: _lookupBannerFound ? KonektoBrand.goldLight : KonektoBrand.slate,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_lookupBanner!, style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.cream))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _FormField(label: 'Nome', controller: _firstNameController)),
                const SizedBox(width: 10),
                Expanded(child: _FormField(label: 'Sobrenome', controller: _lastNameController)),
              ],
            ),
            const SizedBox(height: 10),
            IntlPhoneField(
              key: ValueKey('phone-$_prefillGeneration'),
              initialCountryCode: 'BR',
              initialValue: _prefillPhone,
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
              title: Text('WhatsApp é o mesmo número do telefone', style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.slate)),
            ),
            if (!_whatsappSameAsPhone) ...[
              const SizedBox(height: 4),
              IntlPhoneField(
                key: ValueKey('whatsapp-$_prefillGeneration'),
                initialCountryCode: 'BR',
                initialValue: _prefillWhatsapp,
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
            _FormField(label: 'E-mail (opcional)', controller: _emailController, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 10),
            _FormField(label: 'Endereço (opcional)', controller: _addressController),
            const SizedBox(height: 10),
            _FormField(label: 'País', controller: _countryController),
            const SizedBox(height: 10),
            _FormField(label: 'Senha de wifi (opcional — vazio usa a padrão do hotel)', controller: _wifiPasswordController),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: KonektoBrand.ink))
                    : const Icon(Icons.login, size: 18),
                label: Text('Registrar hóspede e iniciar estadia', style: KonektoBrand.body(fontSize: 13.5, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KonektoBrand.gold,
                  foregroundColor: KonektoBrand.ink,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ),
          ],
        ),
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
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.gold)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date != null ? _formatDate(date!) : 'Selecionar',
              style: KonektoBrand.body(fontSize: 13.5, color: date != null ? KonektoBrand.cream : KonektoBrand.slateSoft),
            ),
            const Icon(Icons.calendar_today_outlined, size: 15, color: KonektoBrand.slate),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _FormField({required this.label, required this.controller, this.keyboardType, this.inputFormatters});

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
