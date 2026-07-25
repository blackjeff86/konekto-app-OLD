import 'package:flutter/material.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/hotel_config_repository.dart';
import 'package:konekto_portal/data/service_repository.dart';
import 'package:konekto_portal/features/services/service_icons.dart';
import 'package:konekto_portal/features/services/service_items_page.dart';
import 'package:konekto_portal/features/services/translation_language_section.dart';
import 'package:konekto_portal/models/service.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';
import 'package:konekto_portal/widgets/image_upload_field.dart';
import 'package:konekto_portal/widgets/weekday_chips.dart';

/// Tela "Serviços" — lista os serviços do hotel (Room Service, Spa, cada
/// restaurante, e qualquer serviço novo que o gerente criar) e permite
/// criar/editar/habilitar/remover. Substitui os chips fixos que existiam
/// antes (Marca/Room service/Spa/Restaurantes/.../em breve).
class ServicesListPage extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const ServicesListPage({
    super.key,
    required this.session,
    required this.authRepository,
  });

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
      setState(
        () => _errorMessage = 'Sessão expirada — saia e entre novamente.',
      );
    }
    return token;
  }

  Future<void> _createOrEditService({Service? existing}) async {
    final existingCategories = _services
        .map((service) => service.category)
        .toSet()
        .toList();
    final result = await showDialog<_ServiceFormResult>(
      context: context,
      builder: (context) => _ServiceFormDialog(
        existing: existing,
        existingCategories: existingCategories,
      ),
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
          type: result.type,
          category: result.category,
          operatingDaysOfWeek: result.operatingHoursApplicable
              ? result.operatingDaysOfWeek
              : null,
          operatingStartMinute: result.operatingHoursApplicable
              ? result.operatingStartMinute
              : null,
          operatingEndMinute: result.operatingHoursApplicable
              ? result.operatingEndMinute
              : null,
        );
      } else {
        await _repository.updateService(
          hotelId: widget.session.hotelId,
          serviceId: existing.id,
          token: token,
          name: result.name,
          icon: result.icon,
          description: result.description,
          category: result.category,
          manualTranslations: result.manualTranslations,
          includeOperatingHours: result.operatingHoursApplicable,
          operatingDaysOfWeek: result.operatingDaysOfWeek,
          operatingStartMinute: result.operatingStartMinute,
          operatingEndMinute: result.operatingEndMinute,
        );
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Serviço salvo.')));
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

  /// `position` é um contador global (não por categoria), mas como a UI só
  /// compara ordem DENTRO da mesma categoria, é seguro reatribuir aos
  /// serviços reordenados os mesmos valores de `position` que esse grupo
  /// já tinha (só permutados) — nunca colide com a posição de serviços de
  /// outra categoria, que nunca são comparados entre si na tela.
  Future<void> _reorderServicesInCategory(
    String category,
    int oldIndex,
    int newIndex,
  ) async {
    final categoryServices = _services
        .where((service) => service.category == category)
        .toList();
    if (newIndex > oldIndex) newIndex -= 1;

    final reordered = List<Service>.from(categoryServices);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    final originalPositions = categoryServices
        .map((service) => service.position)
        .toList();

    final token = await _requireToken();
    if (token == null) return;

    try {
      await Future.wait([
        for (var i = 0; i < reordered.length; i++)
          if (reordered[i].position != originalPositions[i])
            _repository.updateServicePosition(
              hotelId: widget.session.hotelId,
              serviceId: reordered[i].id,
              token: token,
              position: originalPositions[i],
            ),
      ]);
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
        title: Text(
          'Remover serviço?',
          style: KonektoBrand.display(fontSize: 16),
        ),
        content: Text(
          '"${service.name}" e todos os seus itens serão removidos permanentemente.',
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
      await _repository.deleteService(
        hotelId: widget.session.hotelId,
        serviceId: service.id,
        token: token,
      );
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
      return const Center(
        child: CircularProgressIndicator(color: KonektoBrand.gold),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Serviços do hotel',
                  style: KonektoBrand.display(fontSize: 18),
                ),
              ),
              TextButton.icon(
                onPressed: () => _createOrEditService(),
                icon: const Icon(
                  Icons.add,
                  size: 18,
                  color: KonektoBrand.goldLight,
                ),
                label: Text(
                  'Criar serviço',
                  style: KonektoBrand.body(
                    fontSize: 12.5,
                    color: KonektoBrand.goldLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Cada card é um serviço que aparece no app do hóspede — crie quantos o hotel oferecer.',
            style: KonektoBrand.body(fontSize: 12.5),
          ),
          const SizedBox(height: 20),
          _ServicesPageBannerCard(
            session: widget.session,
            authRepository: widget.authRepository,
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
          if (_services.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: KonektoBrand.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KonektoBrand.borderStrong),
              ),
              child: Text(
                'Nenhum serviço criado ainda.',
                style: KonektoBrand.body(fontSize: 13.5),
              ),
            )
          else
            for (final category
                in _services.map((service) => service.category).toSet()) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  category,
                  style: KonektoBrand.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: KonektoBrand.slate,
                  ),
                ),
              ),
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (oldIndex, newIndex) =>
                    _reorderServicesInCategory(category, oldIndex, newIndex),
                children: [
                  for (final service in _services.where(
                    (service) => service.category == category,
                  ))
                    Padding(
                      key: ValueKey(service.id),
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ServiceRow(
                        service: service,
                        onManageItems: () =>
                            setState(() => _managingServiceId = service.id),
                        onEdit: () => _createOrEditService(existing: service),
                        onToggleEnabled: () => _toggleEnabled(service),
                        onDelete: () => _deleteService(service),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

/// Banner mostrado no topo da tela "Serviços" do app do hóspede — vive num
/// `HotelContent` separado (`servicesPage.pageStyles.banner.imageUrl`), não
/// no `Hotel.config`, por isso tem repositório e card próprios aqui em vez
/// de entrar na aba Marca.
class _ServicesPageBannerCard extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const _ServicesPageBannerCard({
    required this.session,
    required this.authRepository,
  });

  @override
  State<_ServicesPageBannerCard> createState() =>
      _ServicesPageBannerCardState();
}

class _ServicesPageBannerCardState extends State<_ServicesPageBannerCard> {
  final _repository = HotelConfigRepository();
  final _imageUrlController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final imageUrl = await _repository.getServicesPageBannerImageUrl(
        hotelId: widget.session.hotelId,
      );
      _imageUrlController.text = imageUrl;
    } on StateError catch (error) {
      _errorMessage = error.message;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(
        () => _errorMessage = 'Sessão expirada — saia e entre novamente.',
      );
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await _repository.updateServicesPageBannerImageUrl(
        hotelId: widget.session.hotelId,
        token: token,
        imageUrl: _imageUrlController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Banner salvo.')));
      }
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KonektoBrand.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KonektoBrand.borderStrong),
      ),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: KonektoBrand.gold),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Banner da tela de Serviços',
                  style: KonektoBrand.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: KonektoBrand.cream,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Imagem mostrada no topo da lista de serviços no app do hóspede.',
                  style: KonektoBrand.body(
                    fontSize: 12,
                    color: KonektoBrand.slate,
                  ),
                ),
                const SizedBox(height: 14),
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
                  const SizedBox(height: 12),
                ],
                ImageUploadField(
                  label: 'URL da imagem',
                  controller: _imageUrlController,
                  hotelId: widget.session.hotelId,
                  authRepository: widget.authRepository,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: KonektoBrand.gold,
                            ),
                          )
                        : Text(
                            'Salvar',
                            style: KonektoBrand.body(
                              fontSize: 12.5,
                              color: KonektoBrand.goldLight,
                            ),
                          ),
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
            child: Icon(
              serviceIconFor(service.icon),
              size: 22,
              color: KonektoBrand.goldLight,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: KonektoBrand.body(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: KonektoBrand.cream,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${service.description}  ·  ${service.items.length} ${service.items.length == 1 ? 'item' : 'itens'}',
                  style: KonektoBrand.body(
                    fontSize: 12,
                    color: KonektoBrand.slate,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onManageItems,
            child: Text(
              'Gerenciar itens',
              style: KonektoBrand.body(
                fontSize: 12.5,
                color: KonektoBrand.goldLight,
              ),
            ),
          ),
          Switch(
            value: service.enabled,
            activeTrackColor: KonektoBrand.gold.withValues(alpha: 0.5),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? KonektoBrand.gold
                  : KonektoBrand.slate,
            ),
            onChanged: (_) => onToggleEnabled(),
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
  final ServiceType type;
  final String category;
  final FieldTranslations? manualTranslations;
  /// `true` só pra `roomService`/`restaurant` — horário de funcionamento
  /// não se aplica a `activity` (que já tem seu próprio controle fino por
  /// item).
  final bool operatingHoursApplicable;
  final List<int> operatingDaysOfWeek;
  final int? operatingStartMinute;
  final int? operatingEndMinute;

  const _ServiceFormResult({
    required this.name,
    required this.slug,
    required this.icon,
    required this.description,
    required this.type,
    required this.category,
    this.manualTranslations,
    required this.operatingHoursApplicable,
    this.operatingDaysOfWeek = const [],
    this.operatingStartMinute,
    this.operatingEndMinute,
  });
}

/// Sentinela pro item "Nova categoria" no dropdown — distinto de qualquer
/// nome de categoria real (mesmo padrão do seletor de estadia em
/// `guests_page.dart`).
const _newCategorySentinel = '__new_category__';

class _ServiceFormDialog extends StatefulWidget {
  final Service? existing;
  final List<String> existingCategories;

  const _ServiceFormDialog({this.existing, required this.existingCategories});

  @override
  State<_ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<_ServiceFormDialog> {
  final _categoryController = TextEditingController();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _nameEnController;
  late final TextEditingController _descriptionEnController;
  late final TextEditingController _nameEsController;
  late final TextEditingController _descriptionEsController;
  late String _icon;
  late ServiceType _type;
  late String _selectedCategory;
  bool _translationsDirty = false;

  late bool _operatingHoursEnabled;
  late TimeOfDay? _operatingStart;
  late TimeOfDay? _operatingEnd;
  late Set<int> _operatingSelectedDays;
  String? _operatingHoursError;

  bool get _operatingHoursApplicable =>
      (widget.existing?.type ?? _type) == ServiceType.roomService ||
      (widget.existing?.type ?? _type) == ServiceType.restaurant;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _operatingHoursEnabled = existing?.operatingStartMinute != null;
    _operatingStart = _timeOfDayFromMinute(existing?.operatingStartMinute);
    _operatingEnd = _timeOfDayFromMinute(existing?.operatingEndMinute);
    _operatingSelectedDays = existing?.operatingDaysOfWeek.toSet() ?? {};
    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    _nameEnController = TextEditingController(
      text: existing?.translations['en']?['name'] ?? '',
    );
    _descriptionEnController = TextEditingController(
      text: existing?.translations['en']?['description'] ?? '',
    );
    _nameEsController = TextEditingController(
      text: existing?.translations['es']?['name'] ?? '',
    );
    _descriptionEsController = TextEditingController(
      text: existing?.translations['es']?['description'] ?? '',
    );
    _icon = existing?.icon ?? kServiceIconOptions.keys.first;
    _type = existing?.type ?? ServiceType.activity;

    if (existing != null &&
        !widget.existingCategories.contains(existing.category)) {
      // Categoria do serviço editado pode já não estar na lista (ex: era a
      // única com esse nome e foi renomeada em outro serviço); trata como
      // "nova" pra não sumir do formulário.
      _selectedCategory = _newCategorySentinel;
      _categoryController.text = existing.category;
    } else {
      _selectedCategory =
          existing?.category ??
          (widget.existingCategories.isEmpty
              ? _newCategorySentinel
              : widget.existingCategories.first);
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

  Future<void> _pickOperatingTime({required bool isStart}) async {
    final initial =
        (isStart ? _operatingStart : _operatingEnd) ??
        const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _operatingStart = picked;
      } else {
        _operatingEnd = picked;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _nameEnController.dispose();
    _descriptionEnController.dispose();
    _nameEsController.dispose();
    _descriptionEsController.dispose();
    super.dispose();
  }

  String _slugify(String value) {
    final normalized = value.toLowerCase().trim();
    final withDashes = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return withDashes.replaceAll(RegExp(r'(^-+)|(-+$)'), '');
  }

  void _submit() {
    final name = _nameController.text.trim();
    final category = _selectedCategory == _newCategorySentinel
        ? _categoryController.text.trim()
        : _selectedCategory;
    if (name.isEmpty || category.isEmpty) return;

    List<int> operatingDaysOfWeek = const [];
    int? operatingStartMinute;
    int? operatingEndMinute;

    if (_operatingHoursApplicable && _operatingHoursEnabled) {
      operatingDaysOfWeek = _operatingSelectedDays.toList()..sort();
      final start = _operatingStart;
      final end = _operatingEnd;

      if (operatingDaysOfWeek.isEmpty) {
        setState(
          () => _operatingHoursError = 'Selecione pelo menos um dia da semana.',
        );
        return;
      }
      if (start == null || end == null) {
        setState(
          () => _operatingHoursError = 'Informe o horário de início e fim.',
        );
        return;
      }
      operatingStartMinute = _minuteFromTimeOfDay(start);
      operatingEndMinute = _minuteFromTimeOfDay(end);
      if (operatingStartMinute == operatingEndMinute) {
        setState(
          () => _operatingHoursError =
              'O horário de início e fim não podem ser iguais.',
        );
        return;
      }
    }
    _operatingHoursError = null;

    FieldTranslations? manualTranslations;
    if (_translationsDirty) {
      final en = <String, String>{
        if (_nameEnController.text.trim().isNotEmpty)
          'name': _nameEnController.text.trim(),
        if (_descriptionEnController.text.trim().isNotEmpty)
          'description': _descriptionEnController.text.trim(),
      };
      final es = <String, String>{
        if (_nameEsController.text.trim().isNotEmpty)
          'name': _nameEsController.text.trim(),
        if (_descriptionEsController.text.trim().isNotEmpty)
          'description': _descriptionEsController.text.trim(),
      };
      manualTranslations = {
        if (en.isNotEmpty) 'en': en,
        if (es.isNotEmpty) 'es': es,
      };
    }

    Navigator.of(context).pop(
      _ServiceFormResult(
        name: name,
        slug: widget.existing?.slug ?? _slugify(name),
        category: category,
        icon: _icon,
        description: _descriptionController.text.trim(),
        type: widget.existing?.type ?? _type,
        manualTranslations: manualTranslations,
        operatingHoursApplicable: _operatingHoursApplicable,
        operatingDaysOfWeek: operatingDaysOfWeek,
        operatingStartMinute: operatingStartMinute,
        operatingEndMinute: operatingEndMinute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KonektoBrand.surface,
      title: Text(
        widget.existing == null ? 'Criar serviço' : 'Editar serviço',
        style: KonektoBrand.display(fontSize: 16),
      ),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.existing == null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Comportamento no app do hóspede',
                    style: KonektoBrand.body(
                      fontSize: 12,
                      color: KonektoBrand.slate,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in ServiceType.values)
                      ChoiceChip(
                        label: Text(type.label),
                        selected: _type == type,
                        onSelected: (_) => setState(() => _type = type),
                        selectedColor: KonektoBrand.gold,
                        checkmarkColor: KonektoBrand.ink,
                        backgroundColor: Colors.transparent,
                        side: BorderSide(
                          color: _type == type
                              ? KonektoBrand.gold
                              : KonektoBrand.borderStrong,
                        ),
                        labelStyle: KonektoBrand.body(
                          fontSize: 12.5,
                          fontWeight: _type == type
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: _type == type
                              ? KonektoBrand.ink
                              : KonektoBrand.slate,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  switch (_type) {
                    ServiceType.roomService =>
                      'Item por item, com quantidade e observação (ex: cardápio de quarto).',
                    ServiceType.restaurant =>
                      'Cardápio só informativo — a reserva é de uma mesa, não de um prato.',
                    ServiceType.activity =>
                      'Cada item abre um modal de dia/horário (ex: spa, eventos, passeios).',
                  },
                  style: KonektoBrand.body(
                    fontSize: 11.5,
                    color: KonektoBrand.slateSoft,
                  ),
                ),
                const SizedBox(height: 14),
              ] else ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Comportamento: ${widget.existing!.type.label}',
                    style: KonektoBrand.body(
                      fontSize: 12,
                      color: KonektoBrand.slate,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Categoria',
                  style: KonektoBrand.body(
                    fontSize: 12,
                    color: KonektoBrand.slate,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                dropdownColor: KonektoBrand.surface,
                style: KonektoBrand.body(
                  fontSize: 13.5,
                  color: KonektoBrand.cream,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: KonektoBrand.borderStrong),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: KonektoBrand.gold),
                  ),
                ),
                items: [
                  for (final category in widget.existingCategories)
                    DropdownMenuItem(value: category, child: Text(category)),
                  const DropdownMenuItem(
                    value: _newCategorySentinel,
                    child: Text('+ Nova categoria'),
                  ),
                ],
                onChanged: (value) => setState(
                  () => _selectedCategory = value ?? _newCategorySentinel,
                ),
              ),
              if (_selectedCategory == _newCategorySentinel) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _categoryController,
                  style: KonektoBrand.body(
                    fontSize: 13.5,
                    color: KonektoBrand.cream,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nome da nova categoria',
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
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                style: KonektoBrand.body(
                  fontSize: 13.5,
                  color: KonektoBrand.cream,
                ),
                decoration: InputDecoration(
                  labelText: 'Nome',
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
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                style: KonektoBrand.body(
                  fontSize: 13.5,
                  color: KonektoBrand.cream,
                ),
                decoration: InputDecoration(
                  labelText: 'Descrição',
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
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ícone',
                  style: KonektoBrand.body(
                    fontSize: 12,
                    color: KonektoBrand.slate,
                  ),
                ),
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
                          color: _icon == entry.key
                              ? KonektoBrand.gold.withValues(alpha: 0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _icon == entry.key
                                ? KonektoBrand.gold.withValues(alpha: 0.6)
                                : KonektoBrand.borderStrong,
                          ),
                        ),
                        child: Icon(
                          entry.value,
                          size: 18,
                          color: _icon == entry.key
                              ? KonektoBrand.goldLight
                              : KonektoBrand.slate,
                        ),
                      ),
                    ),
                ],
              ),
              if (_operatingHoursApplicable) ...[
                const SizedBox(height: 14),
                _ServiceOperatingHoursSection(
                  enabled: _operatingHoursEnabled,
                  onEnabledChanged: (value) =>
                      setState(() => _operatingHoursEnabled = value),
                  operatingStart: _operatingStart,
                  operatingEnd: _operatingEnd,
                  onPickStart: () => _pickOperatingTime(isStart: true),
                  onPickEnd: () => _pickOperatingTime(isStart: false),
                  formatTime: _formatTimeOfDay,
                  selectedDays: _operatingSelectedDays,
                  onToggleDay: (day) => setState(() {
                    if (_operatingSelectedDays.contains(day)) {
                      _operatingSelectedDays.remove(day);
                    } else {
                      _operatingSelectedDays.add(day);
                    }
                  }),
                  error: _operatingHoursError,
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

/// Horário de funcionamento do serviço inteiro — só pra `roomService`
/// (bloqueia pedido fora do horário, ex: cozinha que fecha de madrugada) e
/// `restaurant` (bloqueia reserva fora do horário). Sem duração/capacidade
/// (diferente de `_SchedulingSection`, usada pro agendamento por item de
/// atividade) — aqui é só "o serviço está aberto ou não nesse dia/hora".
class _ServiceOperatingHoursSection extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final TimeOfDay? operatingStart;
  final TimeOfDay? operatingEnd;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final String Function(TimeOfDay) formatTime;
  final Set<int> selectedDays;
  final ValueChanged<int> onToggleDay;
  final String? error;

  const _ServiceOperatingHoursSection({
    required this.enabled,
    required this.onEnabledChanged,
    required this.operatingStart,
    required this.operatingEnd,
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
                  'Horário de funcionamento',
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
                  child: OutlinedButton(
                    onPressed: onPickStart,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KonektoBrand.goldLight,
                      side: const BorderSide(color: KonektoBrand.borderStrong),
                    ),
                    child: Text(
                      operatingStart == null
                          ? 'Início'
                          : 'Início: ${formatTime(operatingStart!)}',
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
                      operatingEnd == null
                          ? 'Fim'
                          : 'Fim: ${formatTime(operatingEnd!)}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Se o fim for antes do início, entende-se que o funcionamento atravessa a meia-noite (ex: 19h às 01h).',
              style: KonektoBrand.body(fontSize: 11, color: KonektoBrand.slateSoft),
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
