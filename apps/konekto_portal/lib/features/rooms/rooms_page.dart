import 'package:flutter/material.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/rooms_repository.dart';
import 'package:konekto_portal/data/stays_repository.dart';
import 'package:konekto_portal/features/rooms/stay_detail_page.dart';
import 'package:konekto_portal/models/room.dart';
import 'package:konekto_portal/models/stay.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

/// Tela "Quartos" — mapa visual de todos os quartos cadastrados (ver
/// Configurações → Quartos), cada um mostrando livre/ocupado. Tocar num
/// quarto ocupado abre o detalhe da estadia (`StayDetailPage`, com
/// hóspedes, avisos, valor em aberto, estender/fechar conta); tocar num
/// quarto livre abre um atalho pra iniciar uma nova estadia nele.
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Quartos', style: KonektoBrand.display(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            'Toque num quarto pra ver hóspedes, avisos e o valor em aberto — ou iniciar uma estadia se estiver livre.',
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
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final room in _rooms) _RoomCard(room: room, onTap: () => setState(() => _viewingRoomId = room.id)),
              ],
            ),
        ],
      ),
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

/// Detalhe de um quarto LIVRE — sem estadia pra mostrar, só a opção de
/// iniciar uma nova.
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
  String? _errorMessage;
  bool _isSubmitting = false;

  Future<void> _startStay() async {
    final dates = await showDialog<_StayDates>(context: context, builder: (context) => const _StayDatesDialog());
    if (dates == null) return;

    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(() => _errorMessage = 'Sessão expirada — saia e entre novamente.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _staysRepository.createStay(
        hotelId: widget.session.hotelId,
        token: token,
        input: NewStayInput(roomId: widget.room.id, checkInDate: dates.checkIn, checkOutDate: dates.checkOut),
      );
      widget.onStayCreated();
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Este quarto está livre.', style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(999)),
                        child: Text(
                          'Livre',
                          style: KonektoBrand.body(fontSize: 11, fontWeight: FontWeight.w600, color: KonektoBrand.slateSoft),
                        ),
                      ),
                    ],
                  ),
                  if (widget.room.description != null && widget.room.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(widget.room.description!, style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.slate)),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _startStay,
                      icon: _isSubmitting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: KonektoBrand.ink))
                          : const Icon(Icons.login, size: 18),
                      label: Text('Iniciar nova estadia', style: KonektoBrand.body(fontSize: 13.5, fontWeight: FontWeight.w700)),
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
          ],
        ),
      ),
    );
  }
}

class _StayDates {
  final DateTime checkIn;
  final DateTime checkOut;

  const _StayDates({required this.checkIn, required this.checkOut});
}

class _StayDatesDialog extends StatefulWidget {
  const _StayDatesDialog();

  @override
  State<_StayDatesDialog> createState() => _StayDatesDialogState();
}

class _StayDatesDialogState extends State<_StayDatesDialog> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  String? _errorMessage;

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

  void _submit() {
    final checkInDate = _checkInDate;
    final checkOutDate = _checkOutDate;
    if (checkInDate == null || checkOutDate == null) {
      setState(() => _errorMessage = 'Preencha as datas de estadia.');
      return;
    }
    if (checkOutDate.isBefore(checkInDate)) {
      setState(() => _errorMessage = 'A data de saída não pode ser antes da data de entrada.');
      return;
    }
    Navigator.of(context).pop(_StayDates(checkIn: checkInDate, checkOut: checkOutDate));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KonektoBrand.surface,
      title: Text('Iniciar estadia', style: KonektoBrand.display(fontSize: 16)),
      content: SizedBox(
        width: 340,
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
                Expanded(
                  child: _DatePickerField(label: 'Check-in', date: _checkInDate, onTap: () => _pickDate(isCheckIn: true)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DatePickerField(label: 'Check-out', date: _checkOutDate, onTap: () => _pickDate(isCheckIn: false)),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        TextButton(onPressed: _submit, child: const Text('Iniciar')),
      ],
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
