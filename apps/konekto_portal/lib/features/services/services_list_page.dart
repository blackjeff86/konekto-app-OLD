import 'package:flutter/material.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/service_repository.dart';
import 'package:konekto_portal/features/services/service_icons.dart';
import 'package:konekto_portal/features/services/service_items_page.dart';
import 'package:konekto_portal/models/service.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

/// Tela "Serviços" — lista os serviços do hotel (Room Service, Spa, cada
/// restaurante, e qualquer serviço novo que o gerente criar) e permite
/// criar/editar/habilitar/remover. Substitui os chips fixos que existiam
/// antes (Marca/Room service/Spa/Restaurantes/.../em breve).
class ServicesListPage extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const ServicesListPage({super.key, required this.session, required this.authRepository});

  @override
  State<ServicesListPage> createState() => _ServicesListPageState();
}

class _ServicesListPageState extends State<ServicesListPage> {
  final _repository = ServiceRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<Service> _services = const [];
  String? _managingServiceId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final services = await _repository.listServices(widget.session.hotelId);
      setState(() => _services = services);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _requireToken() async {
    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(() => _errorMessage = 'Sessão expirada — saia e entre novamente.');
    }
    return token;
  }

  Future<void> _createOrEditService({Service? existing}) async {
    final result = await showDialog<_ServiceFormResult>(
      context: context,
      builder: (context) => _ServiceFormDialog(existing: existing),
    );
    if (result == null) return;

    final token = await _requireToken();
    if (token == null) return;

    try {
      if (existing == null) {
        await _repository.createService(
          hotelId: widget.session.hotelId,
          token: token,
          name: result.name,
          slug: result.slug,
          icon: result.icon,
          description: result.description,
        );
      } else {
        await _repository.updateService(
          hotelId: widget.session.hotelId,
          serviceId: existing.id,
          token: token,
          name: result.name,
          icon: result.icon,
          description: result.description,
        );
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Serviço salvo.')));
      }
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _toggleEnabled(Service service) async {
    final token = await _requireToken();
    if (token == null) return;

    try {
      await _repository.updateService(
        hotelId: widget.session.hotelId,
        serviceId: service.id,
        token: token,
        enabled: !service.enabled,
      );
      await _load();
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _deleteService(Service service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KonektoBrand.surface,
        title: Text('Remover serviço?', style: KonektoBrand.display(fontSize: 16)),
        content: Text(
          '"${service.name}" e todos os seus itens serão removidos permanentemente.',
          style: KonektoBrand.body(fontSize: 13),
        ),
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
      await _repository.deleteService(hotelId: widget.session.hotelId, serviceId: service.id, token: token);
      await _load();
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final managingServiceId = _managingServiceId;
    if (managingServiceId != null) {
      return ServiceItemsPage(
        session: widget.session,
        authRepository: widget.authRepository,
        serviceId: managingServiceId,
        onBack: () => setState(() => _managingServiceId = null),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: KonektoBrand.gold));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Serviços do hotel', style: KonektoBrand.display(fontSize: 18)),
              ),
              TextButton.icon(
                onPressed: () => _createOrEditService(),
                icon: const Icon(Icons.add, size: 18, color: KonektoBrand.goldLight),
                label: Text('Criar serviço', style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.goldLight)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Cada card é um serviço que aparece no app do hóspede — crie quantos o hotel oferecer.',
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
          if (_services.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: KonektoBrand.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KonektoBrand.borderStrong),
              ),
              child: Text('Nenhum serviço criado ainda.', style: KonektoBrand.body(fontSize: 13.5)),
            )
          else
            for (final service in _services)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ServiceRow(
                  service: service,
                  onManageItems: () => setState(() => _managingServiceId = service.id),
                  onEdit: () => _createOrEditService(existing: service),
                  onToggleEnabled: () => _toggleEnabled(service),
                  onDelete: () => _deleteService(service),
                ),
              ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final Service service;
  final VoidCallback onManageItems;
  final VoidCallback onEdit;
  final VoidCallback onToggleEnabled;
  final VoidCallback onDelete;

  const _ServiceRow({
    required this.service,
    required this.onManageItems,
    required this.onEdit,
    required this.onToggleEnabled,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KonektoBrand.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KonektoBrand.borderStrong),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: KonektoBrand.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(serviceIconFor(service.icon), size: 22, color: KonektoBrand.goldLight),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name, style: KonektoBrand.body(fontSize: 14.5, fontWeight: FontWeight.w700, color: KonektoBrand.cream)),
                const SizedBox(height: 2),
                Text(
                  '${service.description}  ·  ${service.items.length} ${service.items.length == 1 ? 'item' : 'itens'}',
                  style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onManageItems,
            child: Text('Gerenciar itens', style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.goldLight)),
          ),
          Switch(
            value: service.enabled,
            activeTrackColor: KonektoBrand.gold.withValues(alpha: 0.5),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected) ? KonektoBrand.gold : KonektoBrand.slate,
            ),
            onChanged: (_) => onToggleEnabled(),
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

class _ServiceFormResult {
  final String name;
  final String slug;
  final String icon;
  final String description;

  const _ServiceFormResult({required this.name, required this.slug, required this.icon, required this.description});
}

class _ServiceFormDialog extends StatefulWidget {
  final Service? existing;

  const _ServiceFormDialog({this.existing});

  @override
  State<_ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<_ServiceFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _icon;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    _icon = existing?.icon ?? kServiceIconOptions.keys.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _slugify(String value) {
    final normalized = value.toLowerCase().trim();
    final withDashes = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return withDashes.replaceAll(RegExp(r'(^-+)|(-+$)'), '');
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(
      _ServiceFormResult(
        name: name,
        slug: widget.existing?.slug ?? _slugify(name),
        icon: _icon,
        description: _descriptionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KonektoBrand.surface,
      title: Text(widget.existing == null ? 'Criar serviço' : 'Editar serviço', style: KonektoBrand.display(fontSize: 16)),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
              decoration: InputDecoration(
                labelText: 'Nome',
                labelStyle: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate),
                isDense: true,
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.borderStrong)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.gold)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
              decoration: InputDecoration(
                labelText: 'Descrição',
                labelStyle: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate),
                isDense: true,
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.borderStrong)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.gold)),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Ícone', style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in kServiceIconOptions.entries)
                  InkWell(
                    onTap: () => setState(() => _icon = entry.key),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _icon == entry.key ? KonektoBrand.gold.withValues(alpha: 0.18) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _icon == entry.key ? KonektoBrand.gold.withValues(alpha: 0.6) : KonektoBrand.borderStrong,
                        ),
                      ),
                      child: Icon(entry.value, size: 18, color: _icon == entry.key ? KonektoBrand.goldLight : KonektoBrand.slate),
                    ),
                  ),
              ],
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
