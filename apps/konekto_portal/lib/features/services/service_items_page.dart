import 'package:flutter/material.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/service_repository.dart';
import 'package:konekto_portal/models/service.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

/// Gestão de itens de um serviço específico — generaliza o padrão que
/// `room_service_settings_page.dart` estabeleceu na Fase 3 (lista + diálogo
/// de item), agora servindo qualquer serviço em vez de só Room Service.
class ServiceItemsPage extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;
  final String serviceId;
  final VoidCallback onBack;

  const ServiceItemsPage({
    super.key,
    required this.session,
    required this.authRepository,
    required this.serviceId,
    required this.onBack,
  });

  @override
  State<ServiceItemsPage> createState() => _ServiceItemsPageState();
}

class _ServiceItemsPageState extends State<ServiceItemsPage> {
  final _repository = ServiceRepository();

  bool _isLoading = true;
  String? _errorMessage;
  Service? _service;

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
      final service = await _repository.getService(widget.session.hotelId, widget.serviceId);
      setState(() => _service = service);
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

  Future<void> _addOrEditItem({ServiceItem? existing}) async {
    final result = await showDialog<ServiceItem>(
      context: context,
      builder: (context) => _ItemFormDialog(existing: existing),
    );
    if (result == null) return;

    final token = await _requireToken();
    if (token == null) return;

    try {
      if (existing == null) {
        await _repository.createItem(
          hotelId: widget.session.hotelId,
          serviceId: widget.serviceId,
          token: token,
          item: result,
        );
      } else {
        await _repository.updateItem(
          hotelId: widget.session.hotelId,
          serviceId: widget.serviceId,
          itemId: existing.id,
          token: token,
          item: result,
        );
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item salvo.')));
      }
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _removeItem(ServiceItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KonektoBrand.surface,
        title: Text('Remover item?', style: KonektoBrand.display(fontSize: 16)),
        content: Text('"${item.name}" será removido.', style: KonektoBrand.body(fontSize: 13)),
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
      await _repository.deleteItem(
        hotelId: widget.session.hotelId,
        serviceId: widget.serviceId,
        itemId: item.id,
        token: token,
      );
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

    final service = _service;
    if (service == null) {
      return Center(
        child: Text(_errorMessage ?? 'Não foi possível carregar o serviço.', style: KonektoBrand.body(fontSize: 14)),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, size: 18, color: KonektoBrand.slate),
              ),
              Expanded(child: Text(service.name, style: KonektoBrand.display(fontSize: 18))),
              TextButton.icon(
                onPressed: () => _addOrEditItem(),
                icon: const Icon(Icons.add, size: 18, color: KonektoBrand.goldLight),
                label: Text('Adicionar item', style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.goldLight)),
              ),
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
            decoration: BoxDecoration(
              color: KonektoBrand.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KonektoBrand.borderStrong),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (service.items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Nenhum item nesse serviço ainda.', style: KonektoBrand.body(fontSize: 12.5)),
                  )
                else
                  for (final item in service.items) ...[
                    const Divider(height: 1, color: KonektoBrand.borderStrong),
                    _ItemRow(item: item, onEdit: () => _addOrEditItem(existing: item), onRemove: () => _removeItem(item)),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final ServiceItem item;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _ItemRow({required this.item, required this.onEdit, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final price = item.price;
    final subtitleParts = <String>[
      if (price != null) 'R\$ ${price.toStringAsFixed(2)}' else 'Sob consulta',
      if (item.category != null) item.category!,
      if (item.location != null) item.location!,
      if (item.extraInfo != null) item.extraInfo!,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: KonektoBrand.body(fontSize: 13.5, fontWeight: FontWeight.w600, color: KonektoBrand.cream)),
                Text(subtitleParts.join(' · '), style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate)),
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
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _ItemFormDialog extends StatefulWidget {
  final ServiceItem? existing;

  const _ItemFormDialog({this.existing});

  @override
  State<_ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<_ItemFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _locationController;
  late final TextEditingController _categoryController;
  late final TextEditingController _extraInfoController;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    _priceController = TextEditingController(text: existing?.price?.toString() ?? '');
    _imageUrlController = TextEditingController(text: existing?.imageUrl ?? '');
    _locationController = TextEditingController(text: existing?.location ?? '');
    _categoryController = TextEditingController(text: existing?.category ?? '');
    _extraInfoController = TextEditingController(text: existing?.extraInfo ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    _extraInfoController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final priceText = _priceController.text.trim().replaceAll(',', '.');
    Navigator.of(context).pop(
      ServiceItem(
        id: widget.existing?.id ?? '',
        name: name,
        description: _descriptionController.text.trim(),
        price: priceText.isEmpty ? null : double.tryParse(priceText),
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        extraInfo: _extraInfoController.text.trim().isEmpty ? null : _extraInfoController.text.trim(),
        position: widget.existing?.position ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KonektoBrand.surface,
      title: Text(widget.existing == null ? 'Adicionar item' : 'Editar item', style: KonektoBrand.display(fontSize: 16)),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(label: 'Nome', controller: _nameController),
              const SizedBox(height: 10),
              _DialogField(label: 'Descrição', controller: _descriptionController, maxLines: 2),
              const SizedBox(height: 10),
              _DialogField(label: 'Preço (deixe vazio se não for comprável)', controller: _priceController, keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _DialogField(label: 'URL da imagem (opcional)', controller: _imageUrlController),
              const SizedBox(height: 10),
              _DialogField(label: 'Local (opcional)', controller: _locationController),
              const SizedBox(height: 10),
              _DialogField(label: 'Categoria (opcional)', controller: _categoryController),
              const SizedBox(height: 10),
              _DialogField(label: 'Informação extra (opcional)', controller: _extraInfoController),
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

class _DialogField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;

  const _DialogField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
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
