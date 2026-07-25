import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/guests_repository.dart';
import 'package:konekto_portal/data/orders_repository.dart';
import 'package:konekto_portal/data/rooms_repository.dart';
import 'package:konekto_portal/data/service_repository.dart';
import 'package:konekto_portal/data/stays_repository.dart';
import 'package:konekto_portal/features/guests/guest_detail_page.dart';
import 'package:konekto_portal/models/guest.dart'
    show DocumentType, NewGuestInput;
import 'package:konekto_portal/models/order.dart' show OrderStatus;
import 'package:konekto_portal/models/room.dart';
import 'package:konekto_portal/models/service.dart' show Service, ServiceItem, ServiceType;
import 'package:konekto_portal/models/stay.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';
import 'package:konekto_portal/utils/input_formatters.dart';
import 'package:konekto_portal/widgets/copyable_code_box.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatDateTime(DateTime date) {
  return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _StayOrderEntry {
  final String guestName;
  final GuestOrderSummary order;

  const _StayOrderEntry({required this.guestName, required this.order});
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
  final _roomsRepository = RoomsRepository();
  final _ordersRepository = OrdersRepository();
  final _serviceRepository = ServiceRepository();
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
      final stay = await _repository.getStay(
        hotelId: widget.session.hotelId,
        stayId: widget.stayId,
        token: token,
      );
      setState(() => _stay = stay);
      unawaited(_markMessagesRead());
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addGuest() async {
    final input = await showDialog<NewGuestInput>(
      context: context,
      builder: (context) => _AddGuestDialog(
        stayId: widget.stayId,
        hotelId: widget.session.hotelId,
        authRepository: widget.authRepository,
      ),
    );
    if (input == null) return;

    final token = await _requireToken();
    if (token == null) return;
    try {
      final guest = await _guestsRepository.createGuest(
        hotelId: widget.session.hotelId,
        token: token,
        input: input,
      );
      await _load();
      if (mounted) await _showAccessCodeDialog(guest.accessCode);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _launchConsumption(Stay stay) async {
    List<Service> services;
    try {
      services = await _serviceRepository.listServices(widget.session.hotelId);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
      return;
    }
    final minibarItems = <ServiceItem>[
      for (final service in services)
        if (service.type == ServiceType.roomService)
          for (final item in service.items)
            if (item.isMinibarItem) item,
    ];
    if (minibarItems.isEmpty) {
      setState(() => _errorMessage = 'Nenhum item de frigobar cadastrado ainda — marque um item de Serviço de Quarto como frigobar em Configurações.');
      return;
    }
    if (!mounted) return;

    final input = await showDialog<_ConsumptionInput>(
      context: context,
      builder: (context) => _LaunchConsumptionDialog(guests: stay.guests, minibarItems: minibarItems),
    );
    if (input == null) return;

    final token = await _requireToken();
    if (token == null) return;
    try {
      await _ordersRepository.recordConsumption(
        hotelId: widget.session.hotelId,
        stayId: widget.stayId,
        token: token,
        guestId: input.guestId,
        serviceItemId: input.serviceItemId,
        quantity: input.quantity,
      );
      await _load();
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _showAccessCodeDialog(String accessCode) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KonektoBrand.surface,
        title: Text(
          'Hóspede criado',
          style: KonektoBrand.display(fontSize: 16),
        ),
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _noticeController.text.trim();
    if (message.isEmpty) return;

    final token = await _requireToken();
    if (token == null) return;

    setState(() => _isSendingNotice = true);
    try {
      await _repository.sendMessage(
        hotelId: widget.session.hotelId,
        stayId: widget.stayId,
        token: token,
        message: message,
      );
      _noticeController.clear();
      await _load();
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSendingNotice = false);
    }
  }

  Future<void> _markMessagesRead() async {
    final token = await widget.authRepository.getStoredToken();
    if (token == null) return;
    try {
      await _repository.markMessagesRead(
        hotelId: widget.session.hotelId,
        stayId: widget.stayId,
        token: token,
      );
    } on StateError {
      // Não crítico — se falhar, o badge só demora mais pra zerar.
    }
  }

  // Mesma regra de `computeStayBill` no backend: exclui pedidos cancelados
  // e pedidos pagos diretamente ao parceiro (o Konekto não cobra nada por
  // eles) — só soma o que de fato entra na conta que o hóspede paga pelo
  // app.
  double _consumptionTotal(Stay stay) {
    double total = 0;
    for (final guest in stay.guests) {
      for (final order in guest.orders) {
        if (order.status == OrderStatus.cancelled) continue;
        if (order.isPartnerPaid) continue;
        if (order.price != null) total += order.price! * order.quantity;
      }
    }
    return total;
  }

  List<_ChatEntry> _mergedChatEntries(Stay stay) {
    final entries = <_ChatEntry>[
      ...stay.notices.map(_NoticeEntry.new),
      ...stay.messages.map(_MessageEntry.new),
    ];
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  List<_StayOrderEntry> _allOrders(Stay stay) {
    final entries = <_StayOrderEntry>[
      for (final guest in stay.guests)
        for (final order in guest.orders)
          _StayOrderEntry(guestName: guest.fullName, order: order),
    ];
    entries.sort((a, b) => b.order.createdAt.compareTo(a.order.createdAt));
    return entries;
  }

  Future<void> _closeAccount(Stay stay) async {
    final total = _consumptionTotal(stay);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KonektoBrand.surface,
        title: Text(
          'Fechar conta do quarto ${stay.roomNumber}?',
          style: KonektoBrand.display(fontSize: 16),
        ),
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
              Text(
                'Total consumido:',
                style: KonektoBrand.body(
                  fontSize: 12,
                  color: KonektoBrand.slate,
                ),
              ),
              Text(
                'R\$ ${total.toStringAsFixed(2)}',
                style: KonektoBrand.display(
                  fontSize: 20,
                  color: KonektoBrand.goldLight,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Fechar conta'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final token = await _requireToken();
    if (token == null) return;
    try {
      await _repository.closeStay(
        hotelId: widget.session.hotelId,
        stayId: widget.stayId,
        token: token,
      );
      await _load();
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _extendStay(Stay stay) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: stay.checkOutDate,
      firstDate: stay.checkInDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: 'Nova data de saída',
    );
    if (picked == null) return;

    final token = await _requireToken();
    if (token == null) return;
    try {
      await _repository.extendStay(
        hotelId: widget.session.hotelId,
        stayId: widget.stayId,
        token: token,
        checkOutDate: picked,
      );
      await _load();
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _changeRoom(Stay stay) async {
    final token = await _requireToken();
    if (token == null) return;

    List<Room> freeRooms;
    try {
      final rooms = await _roomsRepository.listRooms(
        hotelId: widget.session.hotelId,
        token: token,
      );
      freeRooms = rooms
          .where((room) => !room.isOccupied && room.number != stay.roomNumber)
          .toList();
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
      return;
    }

    if (freeRooms.isEmpty) {
      setState(
        () => _errorMessage =
            'Não há outro quarto livre pra mover essa estadia agora.',
      );
      return;
    }

    if (!mounted) return;
    final selectedRoomId = await showDialog<String>(
      context: context,
      builder: (context) => _RoomPickerDialog(rooms: freeRooms),
    );
    if (selectedRoomId == null) return;

    final freshToken = await _requireToken();
    if (freshToken == null) return;
    try {
      await _repository.changeRoom(
        hotelId: widget.session.hotelId,
        stayId: widget.stayId,
        token: freshToken,
        roomId: selectedRoomId,
      );
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
      return const Center(
        child: CircularProgressIndicator(color: KonektoBrand.gold),
      );
    }
    final stay = _stay;
    if (stay == null) {
      return Center(
        child: Text(
          _errorMessage ?? 'Não encontrado.',
          style: KonektoBrand.body(fontSize: 13.5),
        ),
      );
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
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: KonektoBrand.slate,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Quarto ${stay.roomNumber}',
                    style: KonektoBrand.display(fontSize: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                          style: KonektoBrand.body(
                            fontSize: 13.5,
                            color: KonektoBrand.cream,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? KonektoBrand.gold.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          stay.status.label,
                          style: KonektoBrand.body(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? KonektoBrand.goldLight
                                : KonektoBrand.slateSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        'Valor em aberto:',
                        style: KonektoBrand.body(
                          fontSize: 12.5,
                          color: KonektoBrand.slate,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'R\$ ${_consumptionTotal(stay).toStringAsFixed(2)}',
                        style: KonektoBrand.display(
                          fontSize: 16,
                          color: KonektoBrand.goldLight,
                        ),
                      ),
                    ],
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _extendStay(stay),
                            icon: const Icon(
                              Icons.event_repeat_outlined,
                              size: 16,
                              color: KonektoBrand.goldLight,
                            ),
                            label: Text(
                              'Estender estadia',
                              style: KonektoBrand.body(
                                fontSize: 13,
                                color: KonektoBrand.goldLight,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: KonektoBrand.borderStrong,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _changeRoom(stay),
                            icon: const Icon(
                              Icons.swap_horiz_outlined,
                              size: 16,
                              color: KonektoBrand.goldLight,
                            ),
                            label: Text(
                              'Trocar quarto',
                              style: KonektoBrand.body(
                                fontSize: 13,
                                color: KonektoBrand.goldLight,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: KonektoBrand.borderStrong,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _closeAccount(stay),
                        icon: const Icon(
                          Icons.receipt_long_outlined,
                          size: 16,
                          color: Color(0xFFF1A6A0),
                        ),
                        label: Text(
                          'Fechar conta',
                          style: KonektoBrand.body(
                            fontSize: 13,
                            color: const Color(0xFFF1A6A0),
                          ),
                        ),
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
                Expanded(
                  child: Text(
                    'Hóspedes',
                    style: KonektoBrand.display(fontSize: 15),
                  ),
                ),
                if (isActive)
                  TextButton.icon(
                    onPressed: _addGuest,
                    icon: const Icon(
                      Icons.person_add_alt_1,
                      size: 16,
                      color: KonektoBrand.goldLight,
                    ),
                    label: Text(
                      'Adicionar',
                      style: KonektoBrand.body(
                        fontSize: 12.5,
                        color: KonektoBrand.goldLight,
                      ),
                    ),
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
                      child: Text(
                        'Nenhum hóspede neste quarto ainda.',
                        style: KonektoBrand.body(fontSize: 13.5),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final guest in stay.guests) ...[
                          if (guest != stay.guests.first)
                            const Divider(
                              height: 1,
                              color: KonektoBrand.borderStrong,
                            ),
                          _StayGuestRow(
                            guest: guest,
                            onTap: () => _openGuestDetail(guest),
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chat com o hóspede',
              style: KonektoBrand.display(fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Visível pra todos os hóspedes deste quarto — eles podem responder pelo app.',
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
                    style: KonektoBrand.body(
                      fontSize: 13.5,
                      color: KonektoBrand.cream,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Ex: seu jantar está pronto, checkout às 12h...',
                      hintStyle: KonektoBrand.body(
                        fontSize: 13,
                        color: KonektoBrand.slateSoft,
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
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _isSendingNotice ? null : _sendMessage,
                  icon: _isSendingNotice
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: KonektoBrand.goldLight),
                ),
              ],
            ),
            if (stay.notices.isNotEmpty || stay.messages.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final entry in _mergedChatEntries(stay))
                _ChatEntryLine(entry: entry),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text('Pedidos', style: KonektoBrand.display(fontSize: 15)),
                ),
                if (isActive)
                  TextButton.icon(
                    onPressed: () => _launchConsumption(stay),
                    icon: const Icon(Icons.kitchen_outlined, size: 16, color: KonektoBrand.goldLight),
                    label: Text(
                      'Lançar consumo',
                      style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.goldLight),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Todos os pedidos e reservas feitos pelos hóspedes deste quarto — é o que forma o valor em aberto acima.',
              style: KonektoBrand.body(fontSize: 12.5),
            ),
            const SizedBox(height: 8),
            _buildOrdersList(stay),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(Stay stay) {
    final entries = _allOrders(stay);
    return Container(
      decoration: BoxDecoration(
        color: KonektoBrand.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KonektoBrand.borderStrong),
      ),
      child: entries.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Nenhum pedido registrado ainda.',
                style: KonektoBrand.body(fontSize: 13.5),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in entries) ...[
                  if (entry != entries.first)
                    const Divider(height: 1, color: KonektoBrand.borderStrong),
                  _StayOrderRow(
                    entry: entry,
                    showGuestName: stay.guests.length > 1,
                  ),
                ],
              ],
            ),
    );
  }
}

/// Escolha do quarto de destino ao mover uma estadia — só lista quartos
/// livres (já filtrado antes de abrir), pra não dar pra escolher um quarto
/// ocupado só pra descobrir o erro depois de confirmar.
class _RoomPickerDialog extends StatefulWidget {
  final List<Room> rooms;

  const _RoomPickerDialog({required this.rooms});

  @override
  State<_RoomPickerDialog> createState() => _RoomPickerDialogState();
}

class _RoomPickerDialogState extends State<_RoomPickerDialog> {
  late String _selectedRoomId = widget.rooms.first.id;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KonektoBrand.surface,
      title: Text('Trocar quarto', style: KonektoBrand.display(fontSize: 16)),
      content: SizedBox(
        width: 320,
        child: DropdownButtonFormField<String>(
          initialValue: _selectedRoomId,
          dropdownColor: KonektoBrand.surface,
          style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
          decoration: const InputDecoration(
            isDense: true,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: KonektoBrand.borderStrong),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: KonektoBrand.gold),
            ),
          ),
          items: [
            for (final room in widget.rooms)
              DropdownMenuItem(
                value: room.id,
                child: Text('Quarto ${room.number}'),
              ),
          ],
          onChanged: (value) =>
              setState(() => _selectedRoomId = value ?? _selectedRoomId),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selectedRoomId),
          child: const Text('Mover'),
        ),
      ],
    );
  }
}

class _ConsumptionInput {
  final String guestId;
  final String serviceItemId;
  final int quantity;

  const _ConsumptionInput({required this.guestId, required this.serviceItemId, required this.quantity});
}

/// Diálogo da recepção pra lançar um consumo de frigobar em nome de um
/// hóspede da estadia (ex: item notado faltando na conferência do quarto).
class _LaunchConsumptionDialog extends StatefulWidget {
  final List<StayGuestSummary> guests;
  final List<ServiceItem> minibarItems;

  const _LaunchConsumptionDialog({required this.guests, required this.minibarItems});

  @override
  State<_LaunchConsumptionDialog> createState() => _LaunchConsumptionDialogState();
}

class _LaunchConsumptionDialogState extends State<_LaunchConsumptionDialog> {
  late String _selectedGuestId = widget.guests.first.id;
  late String _selectedItemId = widget.minibarItems.first.id;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KonektoBrand.surface,
      title: Text('Lançar consumo', style: KonektoBrand.display(fontSize: 16)),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hóspede', style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedGuestId,
              dropdownColor: KonektoBrand.surface,
              style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
              decoration: const InputDecoration(
                isDense: true,
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.borderStrong)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.gold)),
              ),
              items: [
                for (final guest in widget.guests) DropdownMenuItem(value: guest.id, child: Text(guest.fullName)),
              ],
              onChanged: (value) => setState(() => _selectedGuestId = value ?? _selectedGuestId),
            ),
            const SizedBox(height: 14),
            Text('Item de frigobar', style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedItemId,
              dropdownColor: KonektoBrand.surface,
              style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
              decoration: const InputDecoration(
                isDense: true,
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.borderStrong)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.gold)),
              ),
              items: [
                for (final item in widget.minibarItems)
                  DropdownMenuItem(
                    value: item.id,
                    child: Text(item.price != null ? '${item.name} · R\$ ${item.price!.toStringAsFixed(2)}' : item.name),
                  ),
              ],
              onChanged: (value) => setState(() => _selectedItemId = value ?? _selectedItemId),
            ),
            const SizedBox(height: 14),
            Text('Quantidade', style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate)),
            const SizedBox(height: 6),
            Row(
              children: [
                IconButton(
                  onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  icon: const Icon(Icons.remove_circle_outline, color: KonektoBrand.goldLight),
                ),
                Text('$_quantity', style: KonektoBrand.display(fontSize: 16)),
                IconButton(
                  onPressed: () => setState(() => _quantity++),
                  icon: const Icon(Icons.add_circle_outline, color: KonektoBrand.goldLight),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            _ConsumptionInput(guestId: _selectedGuestId, serviceItemId: _selectedItemId, quantity: _quantity),
          ),
          child: const Text('Lançar'),
        ),
      ],
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
                    style: KonektoBrand.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: KonektoBrand.cream,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    guest.accessCode,
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
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: KonektoBrand.slate,
            ),
          ],
        ),
      ),
    );
  }
}

class _StayOrderRow extends StatelessWidget {
  final _StayOrderEntry entry;
  final bool showGuestName;

  const _StayOrderRow({required this.entry, required this.showGuestName});

  Color _statusColor(OrderStatus status) {
    return switch (status) {
      OrderStatus.pending => KonektoBrand.goldLight,
      OrderStatus.inProgress => KonektoBrand.goldLight,
      OrderStatus.completed => KonektoBrand.slateSoft,
      OrderStatus.cancelled => const Color(0xFFF1A6A0),
    };
  }

  @override
  Widget build(BuildContext context) {
    final order = entry.order;
    final statusColor = _statusColor(order.status);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order.quantity}x ${order.itemName}',
                  style: KonektoBrand.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: KonektoBrand.cream,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  showGuestName
                      ? '${entry.guestName} · ${_formatDateTime(order.createdAt)}'
                      : _formatDateTime(order.createdAt),
                  style: KonektoBrand.body(
                    fontSize: 12,
                    color: KonektoBrand.slate,
                  ),
                ),
                if (order.note != null && order.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    order.note!,
                    style: KonektoBrand.body(
                      fontSize: 12,
                      color: KonektoBrand.slateSoft,
                    ),
                  ),
                ],
                if (order.couponTitle != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_offer_outlined,
                        size: 12,
                        color: KonektoBrand.goldLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${order.couponTitle} (-R\$ ${order.discountAmount?.toStringAsFixed(2) ?? '0.00'})',
                        style: KonektoBrand.body(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: KonektoBrand.goldLight,
                        ),
                      ),
                    ],
                  ),
                ],
                if (order.isStaffRecorded) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Lançado pela recepção',
                    style: KonektoBrand.body(fontSize: 11, color: KonektoBrand.slateSoft).copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
                if (order.isPartnerPaid) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Pago diretamente ao parceiro${order.partnerName != null ? ' (${order.partnerName})' : ''} — não entra na conta do quarto',
                    style: KonektoBrand.body(fontSize: 11, color: KonektoBrand.slateSoft).copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                order.price != null
                    ? 'R\$ ${(order.price! * order.quantity).toStringAsFixed(2)}'
                    : '—',
                style: KonektoBrand.display(
                  fontSize: 14,
                  color: KonektoBrand.goldLight,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  order.status.label(order.isBooking),
                  style: KonektoBrand.body(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

sealed class _ChatEntry {
  DateTime get createdAt;
}

class _NoticeEntry extends _ChatEntry {
  final StayNotice notice;
  _NoticeEntry(this.notice);
  @override
  DateTime get createdAt => notice.createdAt;
}

class _MessageEntry extends _ChatEntry {
  final StayMessage message;
  _MessageEntry(this.message);
  @override
  DateTime get createdAt => message.createdAt;
}

class _ChatEntryLine extends StatelessWidget {
  final _ChatEntry entry;

  const _ChatEntryLine({required this.entry});

  @override
  Widget build(BuildContext context) {
    return switch (entry) {
      _NoticeEntry(:final notice) => _bubble(
        label: 'Aviso (histórico)',
        body: notice.message,
        createdAt: notice.createdAt,
        color: KonektoBrand.slateSoft,
      ),
      _MessageEntry(:final message) => _bubble(
        label: message.senderType == MessageSender.staff
            ? 'Recepção'
            : (message.guestFirstName ?? 'Hóspede'),
        body: message.body,
        createdAt: message.createdAt,
        color: message.senderType == MessageSender.staff
            ? KonektoBrand.goldLight
            : KonektoBrand.slate,
      ),
    };
  }

  Widget _bubble({
    required String label,
    required String body,
    required DateTime createdAt,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: KonektoBrand.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: KonektoBrand.borderStrong),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: KonektoBrand.body(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              style: KonektoBrand.body(fontSize: 13, color: KonektoBrand.cream),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(createdAt),
              style: KonektoBrand.body(fontSize: 11, color: KonektoBrand.slate),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formulário enxuto pra adicionar um hóspede a uma Stay já conhecida —
/// sem os campos de quarto/datas (aqueles moram na Stay, não por pessoa).
class _AddGuestDialog extends StatefulWidget {
  final String stayId;
  final String hotelId;
  final AuthRepository authRepository;

  const _AddGuestDialog({
    required this.stayId,
    required this.hotelId,
    required this.authRepository,
  });

  @override
  State<_AddGuestDialog> createState() => _AddGuestDialogState();
}

class _AddGuestDialogState extends State<_AddGuestDialog> {
  final _guestsRepository = GuestsRepository();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _documentFocusNode = FocusNode();
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
  bool _isSearching = false;
  String? _lookupBanner;
  bool _lookupBannerFound = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Mesmo racional de `_FreeRoomDetailState` (ocupar quarto vago): busca
    // automaticamente ao sair do campo de documento, não só no clique do
    // botão "Buscar".
    _documentFocusNode.addListener(() {
      if (!_documentFocusNode.hasFocus && _documentNumberController.text.trim().isNotEmpty) {
        _searchGuest();
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _documentNumberController.dispose();
    _documentFocusNode.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _wifiPasswordController.dispose();
    super.dispose();
  }

  Future<void> _searchGuest() async {
    // CPF é sempre buscado só em dígitos — o cadastro é salvo sem máscara
    // (mesmo formato usado antes da máscara visual existir), então buscar
    // com pontuação nunca bate com um hóspede que já se hospedou antes.
    final documentNumber = _documentType == DocumentType.cpf
        ? stripNonDigits(_documentNumberController.text.trim())
        : _documentNumberController.text.trim();
    if (documentNumber.isEmpty) {
      setState(() => _errorMessage = 'Digite o número do documento pra buscar.');
      return;
    }
    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(() => _errorMessage = 'Sessão expirada — saia e entre novamente.');
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _lookupBanner = null;
    });
    try {
      final result = await _guestsRepository.lookupByDocument(
        hotelId: widget.hotelId,
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
        // `initialValue` do IntlPhoneField só preenche a exibição — o
        // pacote nunca chama `onChanged` sozinho por causa disso, então sem
        // atribuir aqui o `_phone`/`_whatsapp` ficam `null` e a validação do
        // formulário barra o envio mesmo com os campos visualmente cheios.
        _phone = PhoneNumber(countryISOCode: 'BR', countryCode: result.phoneCountryCode, number: result.phoneNumber);
        _whatsapp = result.whatsappNumber != null
            ? PhoneNumber(
                countryISOCode: 'BR',
                countryCode: result.whatsappCountryCode ?? result.phoneCountryCode,
                number: result.whatsappNumber!,
              )
            : null;
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

  void _submit() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final documentNumber = _documentType == DocumentType.cpf
        ? stripNonDigits(_documentNumberController.text.trim())
        : _documentNumberController.text.trim();
    final country = _countryController.text.trim();
    final phone = _phone;

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        documentNumber.isEmpty ||
        country.isEmpty ||
        phone == null) {
      setState(
        () => _errorMessage =
            'Preencha nome, sobrenome, documento, telefone e país.',
      );
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
        phoneNumber: stripNonDigits(phone.number),
        whatsappCountryCode: whatsapp?.countryCode,
        whatsappNumber: whatsapp != null
            ? stripNonDigits(whatsapp.number)
            : null,
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
      title: Text(
        'Adicionar hóspede',
        style: KonektoBrand.display(fontSize: 16),
      ),
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
                      focusNode: _documentFocusNode,
                      inputFormatters: _documentType == DocumentType.cpf
                          ? [CpfInputFormatter()]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isSearching ? null : _searchGuest,
                      icon: _isSearching
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.search,
                              size: 16,
                              color: KonektoBrand.goldLight,
                            ),
                      label: Text(
                        'Buscar',
                        style: KonektoBrand.body(
                          fontSize: 12.5,
                          color: KonektoBrand.goldLight,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: KonektoBrand.borderStrong),
                      ),
                    ),
                  ),
                ],
              ),
              if (_lookupBanner != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: (_lookupBannerFound ? KonektoBrand.gold : KonektoBrand.slate).withValues(alpha: 0.1),
                    border: Border.all(
                      color: (_lookupBannerFound ? KonektoBrand.gold : KonektoBrand.slate).withValues(alpha: 0.35),
                    ),
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
                      Expanded(
                        child: Text(
                          _lookupBanner!,
                          style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.cream),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              IntlPhoneField(
                key: ValueKey('phone-$_prefillGeneration'),
                initialCountryCode: 'BR',
                initialValue: _prefillPhone,
                disableLengthCheck: true,
                inputFormatters: [BrazilPhoneInputFormatter()],
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
                  key: ValueKey('whatsapp-$_prefillGeneration'),
                  initialCountryCode: 'BR',
                  initialValue: _prefillWhatsapp,
                  disableLengthCheck: true,
                  inputFormatters: [BrazilPhoneInputFormatter()],
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: _submit, child: const Text('Adicionar')),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;

  const _FormField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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
