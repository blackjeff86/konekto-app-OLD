import 'package:flutter/material.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/stays_repository.dart';
import 'package:konekto_portal/features/rooms/stay_detail_page.dart';
import 'package:konekto_portal/models/stay.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

/// Tela "Quartos" — cada estadia agrupa um ou mais hóspedes (marido,
/// esposa, filhos) do mesmo quarto, cada um com seu próprio código de
/// acesso. Ponto de entrada pra criar uma reserva de quarto, ver todo
/// mundo hospedado nela, mandar um aviso pra todos de uma vez, e fechar a
/// conta no check-out.
class RoomsPage extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const RoomsPage({super.key, required this.session, required this.authRepository});

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  final _repository = StaysRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<Stay> _stays = const [];

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
      final stays = await _repository.listStays(hotelId: widget.session.hotelId, token: token);
      setState(() => _stays = stays);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createStay() async {
    final input = await showDialog<NewStayInput>(
      context: context,
      builder: (context) => const _StayFormDialog(),
    );
    if (input == null) return;

    final token = await _requireToken();
    if (token == null) return;

    try {
      await _repository.createStay(hotelId: widget.session.hotelId, token: token, input: input);
      await _load();
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _openStay(Stay stay) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StayDetailPage(session: widget.session, authRepository: widget.authRepository, stayId: stay.id),
      ),
    );
    await _load();
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
              Expanded(child: Text('Quartos', style: KonektoBrand.display(fontSize: 18))),
              TextButton.icon(
                onPressed: _createStay,
                icon: const Icon(Icons.add_home_outlined, size: 18, color: KonektoBrand.goldLight),
                label: Text('Nova estadia', style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.goldLight)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Cada estadia é um quarto — adicione quantos hóspedes precisar dentro dela, cada um com seu próprio código.',
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
          if (_stays.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: KonektoBrand.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KonektoBrand.borderStrong),
              ),
              child: Text('Nenhuma estadia criada ainda.', style: KonektoBrand.body(fontSize: 13.5)),
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
                  for (final stay in _stays) ...[
                    if (stay != _stays.first) const Divider(height: 1, color: KonektoBrand.borderStrong),
                    _StayRow(stay: stay, onTap: () => _openStay(stay)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StayRow extends StatelessWidget {
  final Stay stay;
  final VoidCallback onTap;

  const _StayRow({required this.stay, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = stay.status == StayStatus.active;
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
                    'Quarto ${stay.roomNumber}',
                    style: KonektoBrand.body(fontSize: 14, fontWeight: FontWeight.w700, color: KonektoBrand.cream),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${stay.guests.length} hóspede${stay.guests.length == 1 ? '' : 's'}  ·  ${_formatDate(stay.checkInDate)}–${_formatDate(stay.checkOutDate)}',
                    style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate),
                  ),
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
                stay.status.label,
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

class _StayFormDialog extends StatefulWidget {
  const _StayFormDialog();

  @override
  State<_StayFormDialog> createState() => _StayFormDialogState();
}

class _StayFormDialogState extends State<_StayFormDialog> {
  final _roomController = TextEditingController();
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  String? _errorMessage;

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
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

  void _submit() {
    final roomNumber = _roomController.text.trim();
    final checkInDate = _checkInDate;
    final checkOutDate = _checkOutDate;

    if (roomNumber.isEmpty || checkInDate == null || checkOutDate == null) {
      setState(() => _errorMessage = 'Preencha o número do quarto e as datas de estadia.');
      return;
    }
    if (checkOutDate.isBefore(checkInDate)) {
      setState(() => _errorMessage = 'A data de saída não pode ser antes da data de entrada.');
      return;
    }

    Navigator.of(context).pop(NewStayInput(roomNumber: roomNumber, checkInDate: checkInDate, checkOutDate: checkOutDate));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KonektoBrand.surface,
      title: Text('Nova estadia', style: KonektoBrand.display(fontSize: 16)),
      content: SizedBox(
        width: 360,
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
            TextField(
              controller: _roomController,
              style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
              decoration: InputDecoration(
                labelText: 'Número do quarto',
                labelStyle: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate),
                isDense: true,
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.borderStrong)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.gold)),
              ),
            ),
            const SizedBox(height: 10),
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
        TextButton(onPressed: _submit, child: const Text('Criar')),
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
