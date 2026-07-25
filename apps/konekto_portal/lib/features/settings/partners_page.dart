import 'package:flutter/material.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/partners_repository.dart';
import 'package:konekto_portal/models/partner.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

/// Cadastro de empresas parceiras que prestam algum serviço do hotel (ex:
/// um estúdio de massagem terceirizado) — vinculadas item a item do
/// catálogo em Configurações → Serviços, sem login/acesso próprio.
class PartnersPage extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const PartnersPage({
    super.key,
    required this.session,
    required this.authRepository,
  });

  @override
  State<PartnersPage> createState() => _PartnersPageState();
}

class _PartnersPageState extends State<PartnersPage> {
  final _repository = PartnersRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<Partner> _partners = const [];

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
      final partners = await _repository.listPartners(hotelId: widget.session.hotelId, token: token);
      setState(() => _partners = partners);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createOrEditPartner({Partner? existing}) async {
    final result = await showDialog<PartnerInput>(
      context: context,
      builder: (context) => _PartnerFormDialog(existing: existing),
    );
    if (result == null) return;

    final token = await _requireToken();
    if (token == null) return;

    try {
      if (existing == null) {
        await _repository.createPartner(hotelId: widget.session.hotelId, token: token, input: result);
      } else {
        await _repository.updatePartner(
          hotelId: widget.session.hotelId,
          partnerId: existing.id,
          token: token,
          input: result,
        );
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parceiro salvo.')));
      }
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _deletePartner(Partner partner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KonektoBrand.surface,
        title: Text('Remover parceiro?', style: KonektoBrand.display(fontSize: 16)),
        content: Text('"${partner.name}" será removido permanentemente.', style: KonektoBrand.body(fontSize: 13)),
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
      await _repository.deletePartner(hotelId: widget.session.hotelId, partnerId: partner.id, token: token);
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
              Expanded(child: Text('Parceiros', style: KonektoBrand.display(fontSize: 18))),
              TextButton.icon(
                onPressed: () => _createOrEditPartner(),
                icon: const Icon(Icons.add, size: 18, color: KonektoBrand.goldLight),
                label: Text('Cadastrar parceiro', style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.goldLight)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Empresas que prestam algum serviço do hotel (ex: um estúdio de massagem terceirizado). Vincule um parceiro a um item em Serviços pra decidir se o pagamento é cobrado pelo Konekto ou direto com o parceiro.',
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
          if (_partners.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: KonektoBrand.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KonektoBrand.borderStrong),
              ),
              child: Text('Nenhum parceiro cadastrado ainda.', style: KonektoBrand.body(fontSize: 13.5)),
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
                  for (final partner in _partners) ...[
                    if (partner != _partners.first) const Divider(height: 1, color: KonektoBrand.borderStrong),
                    _PartnerRow(
                      partner: partner,
                      onEdit: () => _createOrEditPartner(existing: partner),
                      onDelete: () => _deletePartner(partner),
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

class _PartnerRow extends StatelessWidget {
  final Partner partner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PartnerRow({required this.partner, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final subtitleParts = [
      if (partner.contactName != null) partner.contactName!,
      if (partner.phone != null) partner.phone!,
      if (partner.email != null) partner.email!,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partner.name,
                  style: KonektoBrand.body(fontSize: 14.5, fontWeight: FontWeight.w700, color: KonektoBrand.cream),
                ),
                if (subtitleParts.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitleParts.join('  ·  '), style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate)),
                ],
              ],
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

class _PartnerFormDialog extends StatefulWidget {
  final Partner? existing;

  const _PartnerFormDialog({this.existing});

  @override
  State<_PartnerFormDialog> createState() => _PartnerFormDialogState();
}

class _PartnerFormDialogState extends State<_PartnerFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _contactNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _notesController;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _contactNameController = TextEditingController(text: existing?.contactName ?? '');
    _phoneController = TextEditingController(text: existing?.phone ?? '');
    _emailController = TextEditingController(text: existing?.email ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Informe o nome do parceiro.');
      return;
    }

    final contactName = _contactNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final notes = _notesController.text.trim();

    Navigator.of(context).pop(
      PartnerInput(
        name: name,
        contactName: contactName.isEmpty ? null : contactName,
        phone: phone.isEmpty ? null : phone,
        email: email.isEmpty ? null : email,
        notes: notes.isEmpty ? null : notes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KonektoBrand.surface,
      title: Text(widget.existing == null ? 'Cadastrar parceiro' : 'Editar parceiro', style: KonektoBrand.display(fontSize: 16)),
      content: SizedBox(
        width: 400,
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
              _Field(label: 'Nome do parceiro', controller: _nameController),
              const SizedBox(height: 10),
              _Field(label: 'Pessoa de contato (opcional)', controller: _contactNameController),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _Field(label: 'Telefone (opcional)', controller: _phoneController)),
                  const SizedBox(width: 10),
                  Expanded(child: _Field(label: 'E-mail (opcional)', controller: _emailController)),
                ],
              ),
              const SizedBox(height: 10),
              _Field(label: 'Observações (opcional)', controller: _notesController, maxLines: 2),
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

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const _Field({required this.label, required this.controller, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
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
