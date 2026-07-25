import 'package:flutter/material.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/partners_repository.dart';
import 'package:konekto_portal/data/service_repository.dart';
import 'package:konekto_portal/features/services/translation_language_section.dart';
import 'package:konekto_portal/models/partner.dart';
import 'package:konekto_portal/models/service.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';
import 'package:konekto_portal/widgets/image_upload_field.dart';
import 'package:konekto_portal/widgets/weekday_chips.dart';

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
      final service = await _repository.getService(
        widget.session.hotelId,
        widget.serviceId,
      );
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
      setState(
        () => _errorMessage = 'Sessão expirada — saia e entre novamente.',
      );
    }
    return token;
  }

  Future<void> _addOrEditItem({ServiceItem? existing}) async {
    final result = await showDialog<_ItemFormResult>(
      context: context,
      builder: (context) => _ItemFormDialog(
        existing: existing,
        hotelId: widget.session.hotelId,
        authRepository: widget.authRepository,
        serviceType: _service?.type,
      ),
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
          item: result.item,
        );
      } else {
        await _repository.updateItem(
          hotelId: widget.session.hotelId,
          serviceId: widget.serviceId,
          itemId: existing.id,
          token: token,
          item: result.item,
          manualTranslations: result.manualTranslations,
        );
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Item salvo.')));
      }
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _addOrEditTableType({RestaurantTableType? existing}) async {
    final result = await showDialog<_TableTypeFormResult>(
      context: context,
      builder: (context) => _TableTypeFormDialog(existing: existing),
    );
    if (result == null) return;

    final token = await _requireToken();
    if (token == null) return;

    try {
      if (existing == null) {
        await _repository.createTableType(
          hotelId: widget.session.hotelId,
          serviceId: widget.serviceId,
          token: token,
          label: result.label,
          seats: result.seats,
          quantity: result.quantity,
        );
      } else {
        await _repository.updateTableType(
          hotelId: widget.session.hotelId,
          serviceId: widget.serviceId,
          tableTypeId: existing.id,
          token: token,
          label: result.label,
          seats: result.seats,
          quantity: result.quantity,
        );
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tipo de mesa salvo.')));
      }
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _removeTableType(RestaurantTableType tableType) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KonektoBrand.surface,
        title: Text('Remover tipo de mesa?', style: KonektoBrand.display(fontSize: 16)),
        content: Text(
          '"${tableType.label ?? 'Mesa de ${tableType.seats} lugares'}" será removido.',
          style: KonektoBrand.body(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final token = await _requireToken();
    if (token == null) return;

    try {
      await _repository.deleteTableType(
        hotelId: widget.session.hotelId,
        serviceId: widget.serviceId,
        tableTypeId: tableType.id,
        token: token,
      );
      await _load();
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  /// Mesmo racional de permutar posições existentes (não renumerar do
  /// zero) usado em `_reorderServicesInCategory` — aqui não tem múltiplas
  /// categorias competindo, mas manter o mesmo padrão evita reatribuir
  /// posições desnecessariamente pros itens que não mudaram de lugar.
  Future<void> _reorderItems(int oldIndex, int newIndex) async {
    final service = _service;
    if (service == null) return;
    if (newIndex > oldIndex) newIndex -= 1;

    final items = List<ServiceItem>.from(service.items);
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);

    final originalPositions = service.items
        .map((item) => item.position)
        .toList();

    final token = await _requireToken();
    if (token == null) return;

    try {
      await Future.wait([
        for (var i = 0; i < items.length; i++)
          if (items[i].position != originalPositions[i])
            _repository.updateItemPosition(
              hotelId: widget.session.hotelId,
              serviceId: widget.serviceId,
              itemId: items[i].id,
              token: token,
              position: originalPositions[i],
            ),
      ]);
      await _load();
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
        content: Text(
          '"${item.name}" será removido.',
          style: KonektoBrand.body(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remover'),
          ),
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
      return const Center(
        child: CircularProgressIndicator(color: KonektoBrand.gold),
      );
    }

    final service = _service;
    if (service == null) {
      return Center(
        child: Text(
          _errorMessage ?? 'Não foi possível carregar o serviço.',
          style: KonektoBrand.body(fontSize: 14),
        ),
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
                icon: const Icon(
                  Icons.arrow_back,
                  size: 18,
                  color: KonektoBrand.slate,
                ),
              ),
              Expanded(
                child: Text(
                  service.name,
                  style: KonektoBrand.display(fontSize: 18),
                ),
              ),
              TextButton.icon(
                onPressed: () => _addOrEditItem(),
                icon: const Icon(
                  Icons.add,
                  size: 18,
                  color: KonektoBrand.goldLight,
                ),
                label: Text(
                  'Adicionar item',
                  style: KonektoBrand.body(
                    fontSize: 12.5,
                    color: KonektoBrand.goldLight,
                  ),
                ),
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
          if (service.type == ServiceType.restaurant) ...[
            _RestaurantTableTypesSection(
              tableTypes: service.tableTypes,
              onAdd: () => _addOrEditTableType(),
              onEdit: (tableType) => _addOrEditTableType(existing: tableType),
              onRemove: _removeTableType,
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
                    child: Text(
                      'Nenhum item nesse serviço ainda.',
                      style: KonektoBrand.body(fontSize: 12.5),
                    ),
                  )
                else
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    onReorder: _reorderItems,
                    children: [
                      for (var i = 0; i < service.items.length; i++)
                        Container(
                          key: ValueKey(service.items[i].id),
                          decoration: BoxDecoration(
                            border: i == 0
                                ? null
                                : const Border(
                                    top: BorderSide(
                                      color: KonektoBrand.borderStrong,
                                    ),
                                  ),
                          ),
                          child: _ItemRow(
                            item: service.items[i],
                            onEdit: () =>
                                _addOrEditItem(existing: service.items[i]),
                            onRemove: () => _removeItem(service.items[i]),
                          ),
                        ),
                    ],
                  ),
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

  const _ItemRow({
    required this.item,
    required this.onEdit,
    required this.onRemove,
  });

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
                Text(
                  item.name,
                  style: KonektoBrand.body(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: KonektoBrand.cream,
                  ),
                ),
                Text(
                  subtitleParts.join(' · '),
                  style: KonektoBrand.body(
                    fontSize: 12,
                    color: KonektoBrand.slate,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: KonektoBrand.slate,
            ),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'Remover',
            icon: const Icon(
              Icons.delete_outline,
              size: 18,
              color: KonektoBrand.slate,
            ),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _ItemFormResult {
  final ServiceItem item;
  final FieldTranslations? manualTranslations;

  const _ItemFormResult({required this.item, this.manualTranslations});
}

class _ItemFormDialog extends StatefulWidget {
  final ServiceItem? existing;
  final String hotelId;
  final AuthRepository authRepository;
  final ServiceType? serviceType;

  const _ItemFormDialog({
    this.existing,
    required this.hotelId,
    required this.authRepository,
    this.serviceType,
  });

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

  late final TextEditingController _nameEnController;
  late final TextEditingController _descriptionEnController;
  late final TextEditingController _locationEnController;
  late final TextEditingController _categoryEnController;
  late final TextEditingController _extraInfoEnController;
  late final TextEditingController _nameEsController;
  late final TextEditingController _descriptionEsController;
  late final TextEditingController _locationEsController;
  late final TextEditingController _categoryEsController;
  late final TextEditingController _extraInfoEsController;
  bool _translationsDirty = false;

  late bool _schedulingEnabled;
  late final TextEditingController _durationController;
  late final TextEditingController _capacityController;
  late TimeOfDay? _availabilityStart;
  late TimeOfDay? _availabilityEnd;
  late Set<int> _selectedDays;
  String? _schedulingError;

  late bool _isMinibarItem;

  final _partnersRepository = PartnersRepository();
  late String? _selectedPartnerId;
  late ServiceItemPaymentMode _paymentMode;
  List<Partner> _partners = const [];
  bool _isLoadingPartners = true;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    _isMinibarItem = existing?.isMinibarItem ?? false;
    _selectedPartnerId = existing?.partnerId;
    _paymentMode = existing?.paymentMode ?? ServiceItemPaymentMode.hotel;
    _loadPartners();
    _schedulingEnabled = existing?.durationMinutes != null;
    _durationController = TextEditingController(
      text: existing?.durationMinutes?.toString() ?? '',
    );
    _capacityController = TextEditingController(
      text: existing?.capacityPerSlot?.toString() ?? '',
    );
    _availabilityStart = _timeOfDayFromMinute(existing?.availabilityStartMinute);
    _availabilityEnd = _timeOfDayFromMinute(existing?.availabilityEndMinute);
    _selectedDays = existing?.availableDaysOfWeek.toSet() ?? {};
    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    _priceController = TextEditingController(
      text: existing?.price?.toString() ?? '',
    );
    _imageUrlController = TextEditingController(text: existing?.imageUrl ?? '');
    _locationController = TextEditingController(text: existing?.location ?? '');
    _categoryController = TextEditingController(text: existing?.category ?? '');
    _extraInfoController = TextEditingController(
      text: existing?.extraInfo ?? '',
    );

    final en = existing?.translations['en'];
    final es = existing?.translations['es'];
    _nameEnController = TextEditingController(text: en?['name'] ?? '');
    _descriptionEnController = TextEditingController(
      text: en?['description'] ?? '',
    );
    _locationEnController = TextEditingController(text: en?['location'] ?? '');
    _categoryEnController = TextEditingController(text: en?['category'] ?? '');
    _extraInfoEnController = TextEditingController(
      text: en?['extraInfo'] ?? '',
    );
    _nameEsController = TextEditingController(text: es?['name'] ?? '');
    _descriptionEsController = TextEditingController(
      text: es?['description'] ?? '',
    );
    _locationEsController = TextEditingController(text: es?['location'] ?? '');
    _categoryEsController = TextEditingController(text: es?['category'] ?? '');
    _extraInfoEsController = TextEditingController(
      text: es?['extraInfo'] ?? '',
    );
  }

  Future<void> _loadPartners() async {
    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      if (mounted) setState(() => _isLoadingPartners = false);
      return;
    }
    try {
      final partners = await _partnersRepository.listPartners(hotelId: widget.hotelId, token: token);
      if (mounted) setState(() => _partners = partners);
    } on StateError {
      // Não crítico — o item ainda pode ser salvo sem parceiro.
    } finally {
      if (mounted) setState(() => _isLoadingPartners = false);
    }
  }

  TimeOfDay? _timeOfDayFromMinute(int? minute) {
    if (minute == null) return null;
    return TimeOfDay(hour: minute ~/ 60, minute: minute % 60);
  }

  int _minuteFromTimeOfDay(TimeOfDay time) => time.hour * 60 + time.minute;

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickAvailabilityTime({required bool isStart}) async {
    final initial =
        (isStart ? _availabilityStart : _availabilityEnd) ??
        const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _availabilityStart = picked;
      } else {
        _availabilityEnd = picked;
      }
    });
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
    _nameEnController.dispose();
    _descriptionEnController.dispose();
    _locationEnController.dispose();
    _categoryEnController.dispose();
    _extraInfoEnController.dispose();
    _nameEsController.dispose();
    _descriptionEsController.dispose();
    _locationEsController.dispose();
    _categoryEsController.dispose();
    _extraInfoEsController.dispose();
    _durationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final priceText = _priceController.text.trim().replaceAll(',', '.');

    int? durationMinutes;
    int? capacityPerSlot;
    List<int> availableDaysOfWeek = const [];
    int? availabilityStartMinute;
    int? availabilityEndMinute;

    if (_schedulingEnabled) {
      durationMinutes = int.tryParse(_durationController.text.trim());
      capacityPerSlot = int.tryParse(_capacityController.text.trim());
      availableDaysOfWeek = _selectedDays.toList()..sort();
      final start = _availabilityStart;
      final end = _availabilityEnd;

      if (durationMinutes == null || durationMinutes <= 0) {
        setState(() => _schedulingError = 'Informe a duração em minutos.');
        return;
      }
      if (capacityPerSlot == null || capacityPerSlot <= 0) {
        setState(() => _schedulingError = 'Informe a capacidade por horário.');
        return;
      }
      if (availableDaysOfWeek.isEmpty) {
        setState(() => _schedulingError = 'Selecione pelo menos um dia da semana.');
        return;
      }
      if (start == null || end == null) {
        setState(() => _schedulingError = 'Informe o horário de início e fim.');
        return;
      }
      availabilityStartMinute = _minuteFromTimeOfDay(start);
      availabilityEndMinute = _minuteFromTimeOfDay(end);
      if (availabilityEndMinute <= availabilityStartMinute) {
        setState(() => _schedulingError = 'O horário de fim precisa ser depois do início.');
        return;
      }
      if (durationMinutes > availabilityEndMinute - availabilityStartMinute) {
        setState(() => _schedulingError = 'A duração não cabe na janela de horário informada.');
        return;
      }
    }
    _schedulingError = null;

    FieldTranslations? manualTranslations;
    if (_translationsDirty) {
      final en = <String, String>{
        if (_nameEnController.text.trim().isNotEmpty)
          'name': _nameEnController.text.trim(),
        if (_descriptionEnController.text.trim().isNotEmpty)
          'description': _descriptionEnController.text.trim(),
        if (_locationEnController.text.trim().isNotEmpty)
          'location': _locationEnController.text.trim(),
        if (_categoryEnController.text.trim().isNotEmpty)
          'category': _categoryEnController.text.trim(),
        if (_extraInfoEnController.text.trim().isNotEmpty)
          'extraInfo': _extraInfoEnController.text.trim(),
      };
      final es = <String, String>{
        if (_nameEsController.text.trim().isNotEmpty)
          'name': _nameEsController.text.trim(),
        if (_descriptionEsController.text.trim().isNotEmpty)
          'description': _descriptionEsController.text.trim(),
        if (_locationEsController.text.trim().isNotEmpty)
          'location': _locationEsController.text.trim(),
        if (_categoryEsController.text.trim().isNotEmpty)
          'category': _categoryEsController.text.trim(),
        if (_extraInfoEsController.text.trim().isNotEmpty)
          'extraInfo': _extraInfoEsController.text.trim(),
      };
      manualTranslations = {
        if (en.isNotEmpty) 'en': en,
        if (es.isNotEmpty) 'es': es,
      };
    }

    Navigator.of(context).pop(
      _ItemFormResult(
        item: ServiceItem(
          id: widget.existing?.id ?? '',
          name: name,
          description: _descriptionController.text.trim(),
          price: priceText.isEmpty ? null : double.tryParse(priceText),
          imageUrl: _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
          extraInfo: _extraInfoController.text.trim().isEmpty
              ? null
              : _extraInfoController.text.trim(),
          position: widget.existing?.position ?? 0,
          durationMinutes: durationMinutes,
          capacityPerSlot: capacityPerSlot,
          availableDaysOfWeek: availableDaysOfWeek,
          availabilityStartMinute: availabilityStartMinute,
          availabilityEndMinute: availabilityEndMinute,
          isMinibarItem: _isMinibarItem,
          partnerId: _selectedPartnerId,
          paymentMode: _selectedPartnerId == null ? ServiceItemPaymentMode.hotel : _paymentMode,
        ),
        manualTranslations: manualTranslations,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KonektoBrand.surface,
      title: Text(
        widget.existing == null ? 'Adicionar item' : 'Editar item',
        style: KonektoBrand.display(fontSize: 16),
      ),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(label: 'Nome', controller: _nameController),
              const SizedBox(height: 10),
              _DialogField(
                label: 'Descrição',
                controller: _descriptionController,
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              _DialogField(
                label: 'Preço (deixe vazio se não for comprável)',
                controller: _priceController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              ImageUploadField(
                label: 'URL da imagem (opcional)',
                controller: _imageUrlController,
                hotelId: widget.hotelId,
                authRepository: widget.authRepository,
              ),
              const SizedBox(height: 10),
              _DialogField(
                label: 'Local (opcional)',
                controller: _locationController,
              ),
              const SizedBox(height: 10),
              _DialogField(
                label: 'Categoria (opcional)',
                controller: _categoryController,
              ),
              const SizedBox(height: 10),
              _DialogField(
                label: 'Informação extra (opcional)',
                controller: _extraInfoController,
              ),
              if (widget.serviceType == ServiceType.roomService) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    border: Border.all(color: KonektoBrand.borderStrong),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Item de frigobar (hóspede pode informar consumo)',
                          style: KonektoBrand.body(fontSize: 13, color: KonektoBrand.cream),
                        ),
                      ),
                      Switch(
                        value: _isMinibarItem,
                        onChanged: (value) => setState(() => _isMinibarItem = value),
                        activeThumbColor: KonektoBrand.gold,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _PartnerSection(
                isLoading: _isLoadingPartners,
                partners: _partners,
                selectedPartnerId: _selectedPartnerId,
                onPartnerChanged: (value) => setState(() {
                  _selectedPartnerId = value;
                  if (value == null) _paymentMode = ServiceItemPaymentMode.hotel;
                }),
                paymentMode: _paymentMode,
                onPaymentModeChanged: (value) => setState(() => _paymentMode = value),
              ),
              if (widget.serviceType == ServiceType.activity) ...[
                const SizedBox(height: 14),
                _SchedulingSection(
                  enabled: _schedulingEnabled,
                  onEnabledChanged: (value) =>
                      setState(() => _schedulingEnabled = value),
                  durationController: _durationController,
                  capacityController: _capacityController,
                  availabilityStart: _availabilityStart,
                  availabilityEnd: _availabilityEnd,
                  onPickStart: () => _pickAvailabilityTime(isStart: true),
                  onPickEnd: () => _pickAvailabilityTime(isStart: false),
                  formatTime: _formatTimeOfDay,
                  selectedDays: _selectedDays,
                  onToggleDay: (day) => setState(() {
                    if (_selectedDays.contains(day)) {
                      _selectedDays.remove(day);
                    } else {
                      _selectedDays.add(day);
                    }
                  }),
                  error: _schedulingError,
                ),
              ],
              if (widget.existing != null) ...[
                const SizedBox(height: 14),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  iconColor: KonektoBrand.slate,
                  collapsedIconColor: KonektoBrand.slate,
                  title: Text(
                    'Traduções (opcional)',
                    style: KonektoBrand.body(
                      fontSize: 12.5,
                      color: KonektoBrand.slate,
                    ),
                  ),
                  children: [
                    const SizedBox(height: 8),
                    TranslationLanguageSection(
                      languageLabel: 'English',
                      onAnyFieldChanged: () => _translationsDirty = true,
                      fields: [
                        TranslationFieldController(
                          label: 'Nome (EN)',
                          controller: _nameEnController,
                        ),
                        TranslationFieldController(
                          label: 'Descrição (EN)',
                          controller: _descriptionEnController,
                        ),
                        TranslationFieldController(
                          label: 'Local (EN)',
                          controller: _locationEnController,
                        ),
                        TranslationFieldController(
                          label: 'Categoria (EN)',
                          controller: _categoryEnController,
                        ),
                        TranslationFieldController(
                          label: 'Informação extra (EN)',
                          controller: _extraInfoEnController,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TranslationLanguageSection(
                      languageLabel: 'Español',
                      onAnyFieldChanged: () => _translationsDirty = true,
                      fields: [
                        TranslationFieldController(
                          label: 'Nombre (ES)',
                          controller: _nameEsController,
                        ),
                        TranslationFieldController(
                          label: 'Descripción (ES)',
                          controller: _descriptionEsController,
                        ),
                        TranslationFieldController(
                          label: 'Local (ES)',
                          controller: _locationEsController,
                        ),
                        TranslationFieldController(
                          label: 'Categoría (ES)',
                          controller: _categoryEsController,
                        ),
                        TranslationFieldController(
                          label: 'Información extra (ES)',
                          controller: _extraInfoEsController,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
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

/// Configuração de horário de funcionamento/duração/capacidade de um item
/// de atividade (spa, eventos, passeios) — controla se o hóspede vê um
/// seletor de horários disponíveis (agendamento habilitado) ou o dia/hora
/// livre de sempre (desabilitado, `durationMinutes: null`).
/// Vínculo com uma empresa parceira (ex: estúdio de massagem terceirizado)
/// — aparece em qualquer tipo de serviço, diferente do frigobar/agendamento
/// (que só fazem sentido pra tipos específicos). O modo de pagamento só é
/// editável quando um parceiro está selecionado.
class _PartnerSection extends StatelessWidget {
  final bool isLoading;
  final List<Partner> partners;
  final String? selectedPartnerId;
  final ValueChanged<String?> onPartnerChanged;
  final ServiceItemPaymentMode paymentMode;
  final ValueChanged<ServiceItemPaymentMode> onPaymentModeChanged;

  const _PartnerSection({
    required this.isLoading,
    required this.partners,
    required this.selectedPartnerId,
    required this.onPartnerChanged,
    required this.paymentMode,
    required this.onPaymentModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: KonektoBrand.borderStrong),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Parceiro (opcional)', style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate)),
          const SizedBox(height: 6),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: KonektoBrand.gold)),
            )
          else
            DropdownButtonFormField<String?>(
              initialValue: selectedPartnerId,
              dropdownColor: KonektoBrand.surface,
              style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream),
              decoration: const InputDecoration(
                isDense: true,
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.borderStrong)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: KonektoBrand.gold)),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Nenhum — o próprio hotel presta')),
                for (final partner in partners) DropdownMenuItem(value: partner.id, child: Text(partner.name)),
              ],
              onChanged: onPartnerChanged,
            ),
          if (selectedPartnerId != null) ...[
            const SizedBox(height: 12),
            Text('Pagamento', style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final mode in ServiceItemPaymentMode.values)
                  ChoiceChip(
                    label: Text(mode.label),
                    selected: paymentMode == mode,
                    onSelected: (_) => onPaymentModeChanged(mode),
                    selectedColor: KonektoBrand.gold,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    labelStyle: KonektoBrand.body(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: paymentMode == mode ? KonektoBrand.ink : KonektoBrand.slate,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SchedulingSection extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final TextEditingController durationController;
  final TextEditingController capacityController;
  final TimeOfDay? availabilityStart;
  final TimeOfDay? availabilityEnd;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final String Function(TimeOfDay) formatTime;
  final Set<int> selectedDays;
  final ValueChanged<int> onToggleDay;
  final String? error;

  const _SchedulingSection({
    required this.enabled,
    required this.onEnabledChanged,
    required this.durationController,
    required this.capacityController,
    required this.availabilityStart,
    required this.availabilityEnd,
    required this.onPickStart,
    required this.onPickEnd,
    required this.formatTime,
    required this.selectedDays,
    required this.onToggleDay,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: KonektoBrand.borderStrong),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Habilitar agendamento com horários',
                  style: KonektoBrand.body(fontSize: 13, color: KonektoBrand.cream),
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onEnabledChanged,
                activeThumbColor: KonektoBrand.gold,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DialogField(
                    label: 'Duração (minutos)',
                    controller: durationController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DialogField(
                    label: 'Capacidade por horário',
                    controller: capacityController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPickStart,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KonektoBrand.goldLight,
                      side: const BorderSide(color: KonektoBrand.borderStrong),
                    ),
                    child: Text(
                      availabilityStart == null
                          ? 'Início'
                          : 'Início: ${formatTime(availabilityStart!)}',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPickEnd,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KonektoBrand.goldLight,
                      side: const BorderSide(color: KonektoBrand.borderStrong),
                    ),
                    child: Text(
                      availabilityEnd == null
                          ? 'Fim'
                          : 'Fim: ${formatTime(availabilityEnd!)}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            WeekdayChips(selectedDays: selectedDays, onToggleDay: onToggleDay),
          ],
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: KonektoBrand.body(fontSize: 12, color: const Color(0xFFF1A6A0)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Inventário de tipos de mesa de um restaurante (ex: "10 mesas de 4
/// lugares") — o hóspede reserva por tamanho de mesa, não por mesa física
/// específica. Sem isso configurado, reserva de mesa continua sem
/// checagem de capacidade (comportamento legado).
class _RestaurantTableTypesSection extends StatelessWidget {
  final List<RestaurantTableType> tableTypes;
  final VoidCallback onAdd;
  final ValueChanged<RestaurantTableType> onEdit;
  final ValueChanged<RestaurantTableType> onRemove;

  const _RestaurantTableTypesSection({
    required this.tableTypes,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KonektoBrand.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KonektoBrand.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Tipos de mesa',
                    style: KonektoBrand.display(fontSize: 15),
                  ),
                ),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18, color: KonektoBrand.goldLight),
                  label: Text(
                    'Adicionar tipo de mesa',
                    style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.goldLight),
                  ),
                ),
              ],
            ),
          ),
          if (tableTypes.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                'Nenhum tipo de mesa cadastrado ainda — sem isso, a reserva de mesa não limita quantidade.',
                style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.slate),
              ),
            )
          else
            for (var i = 0; i < tableTypes.length; i++)
              Container(
                decoration: BoxDecoration(
                  border: i == 0
                      ? null
                      : const Border(top: BorderSide(color: KonektoBrand.borderStrong)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tableTypes[i].label ?? 'Mesa de ${tableTypes[i].seats} lugares',
                          style: KonektoBrand.body(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: KonektoBrand.cream,
                          ),
                        ),
                      ),
                      Text(
                        '${tableTypes[i].quantity} mesa(s)',
                        style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.slate),
                      ),
                      IconButton(
                        tooltip: 'Editar',
                        icon: const Icon(Icons.edit_outlined, size: 18, color: KonektoBrand.slate),
                        onPressed: () => onEdit(tableTypes[i]),
                      ),
                      IconButton(
                        tooltip: 'Remover',
                        icon: const Icon(Icons.delete_outline, size: 18, color: KonektoBrand.slate),
                        onPressed: () => onRemove(tableTypes[i]),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _TableTypeFormResult {
  final String? label;
  final int seats;
  final int quantity;

  const _TableTypeFormResult({this.label, required this.seats, required this.quantity});
}

class _TableTypeFormDialog extends StatefulWidget {
  final RestaurantTableType? existing;

  const _TableTypeFormDialog({this.existing});

  @override
  State<_TableTypeFormDialog> createState() => _TableTypeFormDialogState();
}

class _TableTypeFormDialogState extends State<_TableTypeFormDialog> {
  late final TextEditingController _labelController;
  late final TextEditingController _seatsController;
  late final TextEditingController _quantityController;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _labelController = TextEditingController(text: existing?.label ?? '');
    _seatsController = TextEditingController(text: existing?.seats.toString() ?? '');
    _quantityController = TextEditingController(text: existing?.quantity.toString() ?? '');
  }

  @override
  void dispose() {
    _labelController.dispose();
    _seatsController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() {
    final seats = int.tryParse(_seatsController.text.trim());
    final quantity = int.tryParse(_quantityController.text.trim());
    if (seats == null || seats <= 0) {
      setState(() => _error = 'Informe a quantidade de lugares (maior que zero).');
      return;
    }
    if (quantity == null || quantity < 0) {
      setState(() => _error = 'Informe a quantidade de mesas (zero ou mais).');
      return;
    }

    final label = _labelController.text.trim();
    Navigator.of(context).pop(
      _TableTypeFormResult(
        label: label.isEmpty ? null : label,
        seats: seats,
        quantity: quantity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KonektoBrand.surface,
      title: Text(
        widget.existing == null ? 'Adicionar tipo de mesa' : 'Editar tipo de mesa',
        style: KonektoBrand.display(fontSize: 16),
      ),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(
              label: 'Rótulo (opcional, ex: Mesa externa)',
              controller: _labelController,
            ),
            const SizedBox(height: 10),
            _DialogField(
              label: 'Lugares por mesa',
              controller: _seatsController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            _DialogField(
              label: 'Quantidade de mesas desse tipo',
              controller: _quantityController,
              keyboardType: TextInputType.number,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: KonektoBrand.body(fontSize: 12, color: const Color(0xFFF1A6A0)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: _submit, child: const Text('Salvar')),
      ],
    );
  }
}
