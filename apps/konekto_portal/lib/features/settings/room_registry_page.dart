import 'package:flutter/material.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/rooms_repository.dart';
import 'package:konekto_portal/models/room.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

/// Cadastro de quartos físicos do hotel — seção de Configurações, só
/// `gerente` (mesmo padrão de Serviços). É o cadastro que alimenta o mapa
/// de quartos na aba "Quartos" e o seletor de quarto ao abrir uma estadia.
class RoomRegistryPage extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const RoomRegistryPage({super.key, required this.session, required this.authRepository});

  @override
  State<RoomRegistryPage> createState() => _RoomRegistryPageState();
}

class _RoomRegistryPageState extends State<RoomRegistryPage> {
  final _repository = RoomsRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<Room> _rooms = const [];

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

  Future<void> _createOrEditRoom({Room? existing}) async {
    final result = await showDialog<RoomInput>(
      context: context,
      builder: (context) => _RoomFormDialog(existing: existing),
    );
    if (result == null) return;

    final token = await _requireToken();
    if (token == null) return;

    try {
      if (existing == null) {
        await _repository.createRoom(hotelId: widget.session.hotelId, token: token, input: result);
      } else {
        await _repository.updateRoom(hotelId: widget.session.hotelId, roomId: existing.id, token: token, input: result);
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quarto salvo.')));
      }
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _deleteRoom(Room room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KonektoBrand.surface,
        title: Text('Remover quarto?', style: KonektoBrand.display(fontSize: 16)),
        content: Text('"Quarto ${room.number}" será removido permanentemente.', style: KonektoBrand.body(fontSize: 13)),
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
      await _repository.deleteRoom(hotelId: widget.session.hotelId, roomId: room.id, token: token);
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
              Expanded(child: Text('Quartos do hotel', style: KonektoBrand.display(fontSize: 18))),
              TextButton.icon(
                onPressed: () => _createOrEditRoom(),
                icon: const Icon(Icons.add, size: 18, color: KonektoBrand.goldLight),
                label: Text('Cadastrar quarto', style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.goldLight)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'O cadastro aqui alimenta o mapa de quartos e o seletor de quarto ao abrir uma estadia.',
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
              child: Text('Nenhum quarto cadastrado ainda.', style: KonektoBrand.body(fontSize: 13.5)),
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
                  for (final room in _rooms) ...[
                    if (room != _rooms.first) const Divider(height: 1, color: KonektoBrand.borderStrong),
                    _RoomRow(
                      room: room,
                      onEdit: () => _createOrEditRoom(existing: room),
                      onDelete: () => _deleteRoom(room),
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

class _RoomRow extends StatelessWidget {
  final Room room;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoomRow({required this.room, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: room.isOccupied ? KonektoBrand.gold.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.meeting_room_outlined,
              size: 20,
              color: room.isOccupied ? KonektoBrand.goldLight : KonektoBrand.slate,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quarto ${room.number}', style: KonektoBrand.body(fontSize: 14.5, fontWeight: FontWeight.w700, color: KonektoBrand.cream)),
                if (room.description != null && room.description!.isNotEmpty)
                  Text(room.description!, style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: room.isOccupied ? KonektoBrand.gold.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              room.isOccupied ? 'Ocupado' : 'Livre',
              style: KonektoBrand.body(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: room.isOccupied ? KonektoBrand.goldLight : KonektoBrand.slateSoft,
              ),
            ),
          ),
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

class _RoomFormDialog extends StatefulWidget {
  final Room? existing;

  const _RoomFormDialog({this.existing});

  @override
  State<_RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends State<_RoomFormDialog> {
  late final TextEditingController _numberController;
  late final TextEditingController _descriptionController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(text: widget.existing?.number ?? '');
    _descriptionController = TextEditingController(text: widget.existing?.description ?? '');
  }

  @override
  void dispose() {
    _numberController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final number = _numberController.text.trim();
    if (number.isEmpty) {
      setState(() => _errorMessage = 'Preencha o número do quarto.');
      return;
    }
    final description = _descriptionController.text.trim();
    Navigator.of(context).pop(RoomInput(number: number, description: description.isEmpty ? null : description));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KonektoBrand.surface,
      title: Text(widget.existing == null ? 'Cadastrar quarto' : 'Editar quarto', style: KonektoBrand.display(fontSize: 16)),
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
              controller: _numberController,
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
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
              decoration: InputDecoration(
                labelText: 'Descrição (opcional — tipo, comodidades, etc.)',
                labelStyle: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate),
                isDense: true,
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.borderStrong)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.gold)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        TextButton(onPressed: _submit, child: const Text('Salvar')),
      ],
    );
  }
}
