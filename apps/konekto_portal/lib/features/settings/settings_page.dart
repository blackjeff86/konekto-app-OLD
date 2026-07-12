import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_role.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/hotel_config_repository.dart';
import 'package:konekto_portal/features/services/services_list_page.dart';
import 'package:konekto_portal/features/settings/coupons_page.dart';
import 'package:konekto_portal/features/settings/room_registry_page.dart';
import 'package:konekto_portal/features/staff/invite_staff_page.dart';
import 'package:konekto_portal/guest_app_config.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

const List<String> _kConfigSections = ['Marca', 'Serviços', 'Quartos', 'Cupons', 'Equipe'];

/// Shell de Configurações — só `gerente` acessa. Alterna entre a edição de
/// marca e a gestão de serviços dinâmicos (`ServicesListPage`).
class SettingsPage extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const SettingsPage({
    super.key,
    required this.session,
    required this.authRepository,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedSection = 0;

  bool get _isGerente => widget.session.role == StaffRole.gerente;

  @override
  Widget build(BuildContext context) {
    if (!_isGerente) {
      return Center(
        child: Text(
          'Só gerentes têm acesso a Configurações.',
          style: KonektoBrand.body(fontSize: 14),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _kConfigSections.length; i++)
              _SectionChip(
                label: _kConfigSections[i],
                selected: i == _selectedSection,
                onTap: () => setState(() => _selectedSection = i),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: switch (_selectedSection) {
            0 => _BrandingSection(
              session: widget.session,
              authRepository: widget.authRepository,
            ),
            1 => ServicesListPage(
              session: widget.session,
              authRepository: widget.authRepository,
            ),
            2 => RoomRegistryPage(
              session: widget.session,
              authRepository: widget.authRepository,
            ),
            3 => CouponsPage(
              session: widget.session,
              authRepository: widget.authRepository,
            ),
            4 => InviteStaffPage(
              session: widget.session,
              authRepository: widget.authRepository,
            ),
            _ => const SizedBox.shrink(),
          },
        ),
      ],
    );
  }
}

class _SectionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SectionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? KonektoBrand.gold.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? KonektoBrand.gold.withValues(alpha: 0.5)
                : KonektoBrand.borderStrong,
          ),
        ),
        child: Text(
          label,
          style: KonektoBrand.body(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? KonektoBrand.goldLight : KonektoBrand.slate,
          ),
        ),
      ),
    );
  }
}

class _BrandingSection extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const _BrandingSection({required this.session, required this.authRepository});

  @override
  State<_BrandingSection> createState() => _BrandingSectionState();
}

class _BrandingSectionState extends State<_BrandingSection> {
  final _repository = HotelConfigRepository();
  final _nameController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _primaryController = TextEditingController();
  final _secondaryController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _logoUrlController.dispose();
    _primaryController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await _repository.getConfig(widget.session.hotelId);
      final hotelInfo = config['hotelInfo'] as Map<String, dynamic>? ?? {};
      final colorPalette =
          config['colorPalette'] as Map<String, dynamic>? ?? {};
      _nameController.text = hotelInfo['name'] as String? ?? '';
      _logoUrlController.text = hotelInfo['logoUrl'] as String? ?? '';
      _primaryController.text = colorPalette['primary'] as String? ?? '';
      _secondaryController.text = colorPalette['secondary'] as String? ?? '';
    } on StateError catch (error) {
      _errorMessage = error.message;
    } on http.ClientException catch (error) {
      _errorMessage = 'Falha de conexão: ${error.message}';
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
      await _repository.updateBranding(
        hotelId: widget.session.hotelId,
        token: token,
        name: _nameController.text.trim(),
        logoUrl: _logoUrlController.text.trim(),
        primary: _primaryController.text.trim(),
        secondary: _secondaryController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Configurações salvas.')));
      }
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } on http.ClientException catch (error) {
      setState(() => _errorMessage = 'Falha de conexão: ${error.message}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: KonektoBrand.gold),
      );
    }

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _ReceptionQrCard(),
            const SizedBox(height: 24),
            _WifiSettingsCard(session: widget.session, authRepository: widget.authRepository),
            const SizedBox(height: 24),
            _PromoImagesCard(session: widget.session, authRepository: widget.authRepository),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: KonektoBrand.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KonektoBrand.borderStrong),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Marca do hotel',
                    style: KonektoBrand.display(fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nome, logo e cores usados no app do hóspede.',
                    style: KonektoBrand.body(fontSize: 12.5),
                  ),
                  const SizedBox(height: 24),
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
                  _SettingsField(
                    label: 'Nome do hotel',
                    controller: _nameController,
                  ),
                  const SizedBox(height: 14),
                  _SettingsField(
                    label: 'URL do logo',
                    controller: _logoUrlController,
                  ),
                  const SizedBox(height: 14),
                  _SettingsField(
                    label: 'Cor primária (hex)',
                    controller: _primaryController,
                  ),
                  const SizedBox(height: 14),
                  _SettingsField(
                    label: 'Cor secundária (hex)',
                    controller: _secondaryController,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KonektoBrand.gold,
                        foregroundColor: KonektoBrand.ink,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: KonektoBrand.ink,
                              ),
                            )
                          : Text(
                              'Salvar',
                              style: KonektoBrand.body(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: KonektoBrand.ink,
                              ),
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

/// Wi-Fi padrão do hotel — nome da rede + senha usados por qualquer
/// hóspede que não tenha uma senha individual sobrescrita no próprio
/// cadastro (isso é feito no formulário de hóspede, não aqui).
class _WifiSettingsCard extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const _WifiSettingsCard({required this.session, required this.authRepository});

  @override
  State<_WifiSettingsCard> createState() => _WifiSettingsCardState();
}

class _WifiSettingsCardState extends State<_WifiSettingsCard> {
  final _repository = HotelConfigRepository();
  final _networkController = TextEditingController();
  final _passwordController = TextEditingController();

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
    _networkController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final wifi = await _repository.getWifiSettings(hotelId: widget.session.hotelId);
      _networkController.text = wifi.networkName;
      _passwordController.text = wifi.password;
    } on StateError catch (error) {
      _errorMessage = error.message;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(() => _errorMessage = 'Sessão expirada — saia e entre novamente.');
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await _repository.updateWifiSettings(
        hotelId: widget.session.hotelId,
        token: token,
        networkName: _networkController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wi-Fi salvo.')));
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: KonektoBrand.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KonektoBrand.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Wi-Fi padrão', style: KonektoBrand.display(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            'Mostrado pro hóspede na tela inicial — a recepção pode dar uma senha diferente pra um hóspede específico no cadastro dele.',
            style: KonektoBrand.body(fontSize: 12.5),
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: KonektoBrand.gold))
          else ...[
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
            _SettingsField(label: 'Nome da rede', controller: _networkController),
            const SizedBox(height: 14),
            _SettingsField(label: 'Senha padrão', controller: _passwordController),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KonektoBrand.gold,
                  foregroundColor: KonektoBrand.ink,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: KonektoBrand.ink),
                      )
                    : Text('Salvar', style: KonektoBrand.body(fontSize: 14, fontWeight: FontWeight.w700, color: KonektoBrand.ink)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Carrossel de imagens de destaque mostrado na tela inicial do hóspede
/// (depois de entrar no app) — lista de URLs editável, sempre salva por
/// inteiro (não dá pra editar uma imagem isolada via API).
class _PromoImagesCard extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const _PromoImagesCard({required this.session, required this.authRepository});

  @override
  State<_PromoImagesCard> createState() => _PromoImagesCardState();
}

class _PromoImagesCardState extends State<_PromoImagesCard> {
  final _repository = HotelConfigRepository();
  final List<TextEditingController> _imageControllers = [];
  double _carouselHeight = 250;

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
    for (final controller in _imageControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final config = await _repository.getConfig(widget.session.hotelId);
      final hotelInfo = config['hotelInfo'] as Map<String, dynamic>? ?? {};
      final promoImages = hotelInfo['promoImages'] as Map<String, dynamic>? ?? {};
      final images = (promoImages['images'] as List<dynamic>?)?.cast<String>() ?? const [];
      _carouselHeight = (promoImages['carouselHeight'] as num?)?.toDouble() ?? 250;
      setState(() {
        _imageControllers.addAll(images.map((url) => TextEditingController(text: url)));
        if (_imageControllers.isEmpty) _imageControllers.add(TextEditingController());
      });
    } on StateError catch (error) {
      _errorMessage = error.message;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addRow() {
    setState(() => _imageControllers.add(TextEditingController()));
  }

  void _removeRow(int index) {
    setState(() => _imageControllers.removeAt(index).dispose());
  }

  Future<void> _save() async {
    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(() => _errorMessage = 'Sessão expirada — saia e entre novamente.');
      return;
    }
    final images = _imageControllers.map((c) => c.text.trim()).where((url) => url.isNotEmpty).toList();
    if (images.isEmpty) {
      setState(() => _errorMessage = 'Adicione pelo menos uma imagem.');
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await _repository.updatePromoImages(
        hotelId: widget.session.hotelId,
        token: token,
        images: images,
        carouselHeight: _carouselHeight,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Carrossel salvo.')));
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: KonektoBrand.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KonektoBrand.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Carrossel de destaque', style: KonektoBrand.display(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            'Imagens mostradas na tela inicial do hóspede depois que ele entra — use URLs de imagens hospedadas (ex: um link direto de foto).',
            style: KonektoBrand.body(fontSize: 12.5),
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: KonektoBrand.gold))
          else ...[
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
            for (var i = 0; i < _imageControllers.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _SettingsField(label: 'URL da imagem ${i + 1}', controller: _imageControllers[i])),
                  IconButton(
                    onPressed: _imageControllers.length > 1 ? () => _removeRow(i) : null,
                    icon: const Icon(Icons.remove_circle_outline, size: 20, color: KonektoBrand.slate),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            TextButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add, size: 16, color: KonektoBrand.goldLight),
              label: Text('Adicionar imagem', style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.goldLight)),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KonektoBrand.gold,
                  foregroundColor: KonektoBrand.ink,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: KonektoBrand.ink),
                      )
                    : Text('Salvar', style: KonektoBrand.body(fontSize: 14, fontWeight: FontWeight.w700, color: KonektoBrand.ink)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// QR code fixo (não muda por hóspede) apontando pro app do hóspede —
/// pensado pra imprimir e deixar na recepção. Quem escanear só abre o app;
/// o hóspede ainda digita seu próprio código individual depois.
class _ReceptionQrCard extends StatelessWidget {
  const _ReceptionQrCard();

  void _copyToClipboard(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copiado.')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KonektoBrand.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KonektoBrand.borderStrong),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: QrImageView(
              data: guestAppUrl,
              size: 72,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QR code de recepção',
                  style: KonektoBrand.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: KonektoBrand.cream,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Imprima e deixe na recepção — o hóspede escaneia, abre o app e digita o código individual dele.',
                  style: KonektoBrand.body(
                    fontSize: 12,
                    color: KonektoBrand.slate,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  guestAppUrl,
                  style: KonektoBrand.body(
                    fontSize: 12,
                    color: KonektoBrand.goldLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copiar link',
            icon: const Icon(
              Icons.copy_outlined,
              size: 18,
              color: KonektoBrand.slate,
            ),
            onPressed: () => _copyToClipboard(context, guestAppUrl),
          ),
        ],
      ),
    );
  }
}

class _SettingsField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _SettingsField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: KonektoBrand.body(fontSize: 14, color: KonektoBrand.cream),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: KonektoBrand.body(
          fontSize: 12.5,
          color: KonektoBrand.slate,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: KonektoBrand.borderStrong,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KonektoBrand.gold, width: 1.6),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
