import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/guests_repository.dart';
import 'package:konekto_portal/models/guest.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

/// Tela "Hóspedes" — lista os hóspedes do hotel, permite criar (nome +
/// quarto, gera um código individual) e revogar acesso. Disponível pra
/// `gerente` e `recepcao` (diferente de Configurações).
class GuestsPage extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const GuestsPage({super.key, required this.session, required this.authRepository});

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
      final guests = await _repository.listGuests(hotelId: widget.session.hotelId, token: token);
      setState(() => _guests = guests);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createGuest() async {
    final result = await showDialog<_GuestFormResult>(
      context: context,
      builder: (context) => const _GuestFormDialog(),
    );
    if (result == null) return;

    final token = await _requireToken();
    if (token == null) return;

    try {
      final guest = await _repository.createGuest(
        hotelId: widget.session.hotelId,
        token: token,
        name: result.name,
        roomNumber: result.roomNumber,
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
        title: Text('Hóspede criado', style: KonektoBrand.display(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Passe esse código pro hóspede digitar no app:', style: KonektoBrand.body(fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      style: KonektoBrand.display(fontSize: 18, color: KonektoBrand.goldLight),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copiar',
                    icon: const Icon(Icons.copy_outlined, size: 18, color: KonektoBrand.slate),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: guest.accessCode));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copiado.')));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar')),
        ],
      ),
    );
  }

  Future<void> _revokeGuest(Guest guest) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KonektoBrand.surface,
        title: Text('Revogar acesso?', style: KonektoBrand.display(fontSize: 16)),
        content: Text(
          '"${guest.name}" (quarto ${guest.roomNumber}) não vai mais conseguir entrar no app com esse código.',
          style: KonektoBrand.body(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Revogar')),
        ],
      ),
    );
    if (confirmed != true) return;

    final token = await _requireToken();
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Hóspedes', style: KonektoBrand.display(fontSize: 18))),
              TextButton.icon(
                onPressed: _createGuest,
                icon: const Icon(Icons.person_add_alt_1, size: 18, color: KonektoBrand.goldLight),
                label: Text('Criar hóspede', style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.goldLight)),
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
              child: Text(_errorMessage!, style: KonektoBrand.body(fontSize: 12.5, color: const Color(0xFFF1A6A0))),
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
              child: Text('Nenhum hóspede cadastrado ainda.', style: KonektoBrand.body(fontSize: 13.5)),
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
                    if (guest != _guests.first) const Divider(height: 1, color: KonektoBrand.borderStrong),
                    _GuestRow(guest: guest, onRevoke: () => _revokeGuest(guest)),
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
  final VoidCallback onRevoke;

  const _GuestRow({required this.guest, required this.onRevoke});

  @override
  Widget build(BuildContext context) {
    final isActive = guest.status == GuestStatus.active;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(guest.name, style: KonektoBrand.body(fontSize: 14, fontWeight: FontWeight.w700, color: KonektoBrand.cream)),
                const SizedBox(height: 2),
                Text('Quarto ${guest.roomNumber}  ·  ${guest.accessCode}', style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate)),
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
          if (isActive) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Revogar acesso',
              icon: const Icon(Icons.block, size: 18, color: KonektoBrand.slate),
              onPressed: onRevoke,
            ),
          ],
        ],
      ),
    );
  }
}

class _GuestFormResult {
  final String name;
  final String roomNumber;

  const _GuestFormResult({required this.name, required this.roomNumber});
}

class _GuestFormDialog extends StatefulWidget {
  const _GuestFormDialog();

  @override
  State<_GuestFormDialog> createState() => _GuestFormDialogState();
}

class _GuestFormDialogState extends State<_GuestFormDialog> {
  final _nameController = TextEditingController();
  final _roomController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final room = _roomController.text.trim();
    if (name.isEmpty || room.isEmpty) return;
    Navigator.of(context).pop(_GuestFormResult(name: name, roomNumber: room));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KonektoBrand.surface,
      title: Text('Criar hóspede', style: KonektoBrand.display(fontSize: 16)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
              decoration: InputDecoration(
                labelText: 'Nome do hóspede',
                labelStyle: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate),
                isDense: true,
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.borderStrong)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.gold)),
              ),
            ),
            const SizedBox(height: 10),
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
