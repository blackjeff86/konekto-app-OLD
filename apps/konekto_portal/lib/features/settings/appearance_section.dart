import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/hotel_config_repository.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

/// Réplica local (só o essencial pra desenhar a prévia) dos tokens fixos de
/// cada infra do app do hóspede — ver `apps/konekto_mobile/lib/theme/guest_infra.dart`
/// pra origem/fonte de verdade desses valores. Duplicado aqui de propósito:
/// portal e app do hóspede são pacotes Flutter separados, sem código
/// compartilhado entre eles.
class _InfraOption {
  final String id;
  final String name;
  final String tagline;
  final String description;
  final Color bg;
  final Color card;
  final Color text;
  final Color muted;
  final Color accent;
  final Color accentSoft;
  final String headlineFontFamily;

  const _InfraOption({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.bg,
    required this.card,
    required this.text,
    required this.muted,
    required this.accent,
    required this.accentSoft,
    required this.headlineFontFamily,
  });
}

const _kInfraOptions = [
  _InfraOption(
    id: 'amara_bay',
    name: 'Amara Bay',
    tagline: 'RESORT',
    description: 'Boutique quente — terracota e tipografia serifada.',
    bg: Color(0xFFFBF6EE),
    card: Colors.white,
    text: Color(0xFF2B2420),
    muted: Color(0xFF9C8A78),
    accent: Color(0xFFC1694F),
    accentSoft: Color(0xFFF1E7D9),
    headlineFontFamily: 'Source Serif 4',
  ),
  _InfraOption(
    id: 'verde_pousada',
    name: 'Verde Pousada',
    tagline: 'POUSADA',
    description: 'Editorial sereno — verde sálvia, sem serifa.',
    bg: Color(0xFFFCFCFA),
    card: Colors.white,
    text: Color(0xFF293029),
    muted: Color(0xFF6C7A6E),
    accent: Color(0xFF5B7F66),
    accentSoft: Color(0xFFEEF1EC),
    headlineFontFamily: 'Inter',
  ),
];

/// Escolha da infraestrutura visual do app do hóspede (Amara Bay / Verde
/// Pousada) — separada da aba "Marca" porque não é dado de identidade do
/// hotel (nome/logo/cores), é a escolha do sistema de design inteiro
/// (layout, tipografia, raios) que o app do hóspede vai usar.
class AppearanceSection extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const AppearanceSection({super.key, required this.session, required this.authRepository});

  @override
  State<AppearanceSection> createState() => _AppearanceSectionState();
}

class _AppearanceSectionState extends State<AppearanceSection> {
  final _repository = HotelConfigRepository();
  String _selectedInfra = 'verde_pousada';

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final config = await _repository.getConfig(widget.session.hotelId);
      _selectedInfra = config['infra'] as String? ?? 'verde_pousada';
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
      await _repository.updateInfra(hotelId: widget.session.hotelId, token: token, infra: _selectedInfra);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aparência salva.')));
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
      return const Center(child: CircularProgressIndicator(color: KonektoBrand.gold));
    }

    final selectedOption = _kInfraOptions.firstWhere((option) => option.id == _selectedInfra, orElse: () => _kInfraOptions.last);

    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: KonektoBrand.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KonektoBrand.borderStrong),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Aparência do app do hóspede', style: KonektoBrand.display(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(
                    'Escolha o sistema visual usado nas telas do hóspede — cores, tipografia e layout mudam juntos.',
                    style: KonektoBrand.body(fontSize: 12.5),
                  ),
                  const SizedBox(height: 24),
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
                  for (final option in _kInfraOptions) ...[
                    _InfraCard(
                      option: option,
                      selected: _selectedInfra == option.id,
                      onTap: () => setState(() => _selectedInfra = option.id),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 12),
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
              ),
            ),
          ),
          const SizedBox(width: 40),
          Expanded(
            child: Column(
              children: [
                Text('Prévia — $_selectedInfraDisplayName', style: KonektoBrand.body(fontSize: 12.5, fontWeight: FontWeight.w600, color: KonektoBrand.slate)),
                const SizedBox(height: 16),
                _PhonePreview(option: selectedOption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _selectedInfraDisplayName => _kInfraOptions.firstWhere((option) => option.id == _selectedInfra, orElse: () => _kInfraOptions.last).name;
}

class _InfraCard extends StatelessWidget {
  final _InfraOption option;
  final bool selected;
  final VoidCallback onTap;

  const _InfraCard({required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? option.accent.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? option.accent : KonektoBrand.borderStrong, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, color: option.accent.withValues(alpha: 0.16)),
              child: Center(
                child: Text(
                  'Aa',
                  style: GoogleFonts.getFont(option.headlineFontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: option.accent),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.name, style: KonektoBrand.body(fontSize: 15, fontWeight: FontWeight.w700, color: KonektoBrand.cream)),
                  const SizedBox(height: 2),
                  Text(option.description, style: KonektoBrand.body(fontSize: 12.5)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? option.accent : KonektoBrand.slate,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/// Mockup estático (sem dados reais) da tela Início do app do hóspede,
/// estilizado com os tokens da infra selecionada — ajuda o hotel a decidir
/// entre as duas sem precisar abrir o app do hóspede de verdade. Moldura
/// fixa de um iPhone recente (Dynamic Island, cantos bem arredondados),
/// sempre 272×560px — o conteúdo é desenhado numa tela de referência e
/// escalado com [FittedBox] pra caber exatamente nesse tamanho, então
/// qualquer ajuste de conteúdo continua encaixando sem estourar.
class _PhonePreview extends StatelessWidget {
  final _InfraOption option;

  const _PhonePreview({required this.option});

  static const double _frameWidth = 272;
  static const double _frameHeight = 560;
  static const double _bezel = 10;
  static const double _islandTopInset = 34;

  @override
  Widget build(BuildContext context) {
    TextStyle headline({double fontSize = 16, FontWeight fontWeight = FontWeight.w700, Color? color}) =>
        GoogleFonts.getFont(option.headlineFontFamily, fontSize: fontSize, fontWeight: fontWeight, color: color ?? option.text);
    TextStyle body({double fontSize = 12, FontWeight fontWeight = FontWeight.w400, Color? color}) =>
        GoogleFonts.getFont('Inter', fontSize: fontSize, fontWeight: fontWeight, color: color ?? option.text);

    return Container(
      width: _frameWidth,
      height: _frameHeight,
      padding: const EdgeInsets.all(_bezel),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(46),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 32, offset: const Offset(0, 16))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Container(
          color: option.bg,
          child: Stack(
            children: [
              Positioned.fill(
                top: _islandTopInset,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: 220,
                      child: option.id == 'verde_pousada'
                          ? _buildVerdeContent(headline, body)
                          : _buildAmaraContent(headline, body),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 76,
                    height: 22,
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmaraContent(
    TextStyle Function({double fontSize, FontWeight fontWeight, Color? color}) headline,
    TextStyle Function({double fontSize, FontWeight fontWeight, Color? color}) body,
  ) {
    const tiles = ['Serviço de quarto', 'Mapa do local', 'Histórico', 'Avisos'];
    const tileIcons = [Icons.room_service_outlined, Icons.map_outlined, Icons.history, Icons.campaign_outlined];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: option.accentSoft, borderRadius: BorderRadius.circular(11)),
              child: Icon(Icons.door_front_door_outlined, color: option.accent, size: 22),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.name, style: headline(fontSize: 17)),
                  Text(option.tagline, style: body(fontSize: 11, color: option.muted, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.notifications_none, size: 22, color: option.muted),
            const SizedBox(width: 8),
            Icon(Icons.person_outline, size: 22, color: option.muted),
          ],
        ),
        const SizedBox(height: 16),
        Stack(
          children: [
            Container(
              height: 126,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [option.muted.withValues(alpha: 0.35), Colors.black.withValues(alpha: 0.55)],
                ),
              ),
            ),
            Positioned(
              left: 14,
              bottom: 14,
              right: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                    child: Text('✓ CHECK-IN CONFIRMADO', style: body(fontSize: 8, fontWeight: FontWeight.w700, color: option.accent)),
                  ),
                  const SizedBox(height: 6),
                  Text('Bem-vindo, Hóspede', style: headline(fontSize: 18, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(color: option.card, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Icon(Icons.wifi, size: 20, color: option.accent),
              const SizedBox(width: 11),
              Expanded(child: Text('Quarto 000 · Wi-Fi', style: body(fontSize: 13, fontWeight: FontWeight.w600))),
              Icon(Icons.chevron_right, size: 20, color: option.muted),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Nossos serviços', style: headline(fontSize: 16)),
        const SizedBox(height: 11),
        Row(
          children: [
            Expanded(child: _previewTile(tiles[0], tileIcons[0], body, false)),
            const SizedBox(width: 11),
            Expanded(child: _previewTile(tiles[1], tileIcons[1], body, false)),
          ],
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            Expanded(child: _previewTile(tiles[2], tileIcons[2], body, false)),
            const SizedBox(width: 11),
            Expanded(child: _previewTile(tiles[3], tileIcons[3], body, true)),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(color: option.card, borderRadius: BorderRadius.circular(999)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(Icons.home, size: 21, color: option.accent),
              Icon(Icons.grid_view_outlined, size: 21, color: option.muted),
              Icon(Icons.event_note_outlined, size: 21, color: option.muted),
              Icon(Icons.person_outline, size: 21, color: option.muted),
            ],
          ),
        ),
      ],
    );
  }

  /// Verde Pousada: editorial, sem hero — saudação com nome do hóspede em
  /// destaque, acordeão fino de wifi/quarto, serviços em lista vertical.
  /// Espelha a estrutura real implementada em `TenantHomeBody._buildVerdeContent`
  /// (apps/konekto_mobile).
  Widget _buildVerdeContent(
    TextStyle Function({double fontSize, FontWeight fontWeight, Color? color}) headline,
    TextStyle Function({double fontSize, FontWeight fontWeight, Color? color}) body,
  ) {
    const rows = ['Serviços', 'Histórico', 'Mapa do local', 'Avisos'];
    const rowIcons = [Icons.room_service_outlined, Icons.history, Icons.map_outlined, Icons.campaign_outlined];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(border: Border.all(color: option.muted.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(9)),
              child: Icon(Icons.layers_outlined, color: option.accent, size: 16),
            ),
            const SizedBox(width: 9),
            Expanded(child: Text(option.name, style: headline(fontSize: 15))),
            Icon(Icons.notifications_none, size: 18, color: option.muted),
            const SizedBox(width: 10),
            Icon(Icons.person_outline, size: 18, color: option.muted),
          ],
        ),
        const SizedBox(height: 30),
        Text(
          'BEM-VINDO(A) DE VOLTA',
          style: body(fontSize: 9.5, fontWeight: FontWeight.w600, color: option.muted).copyWith(letterSpacing: 1.1),
        ),
        const SizedBox(height: 5),
        Text('Hóspede', style: headline(fontSize: 23)),
        const SizedBox(height: 5),
        Text('Check-in realizado · Quarto 000', style: body(fontSize: 11.5, color: option.muted)),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: option.accentSoft, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(Icons.home_outlined, size: 16, color: option.accent),
              const SizedBox(width: 9),
              Expanded(child: Text('Wi-Fi & detalhes do quarto', style: body(fontSize: 11.5, fontWeight: FontWeight.w600))),
              Icon(Icons.keyboard_arrow_down, size: 18, color: option.muted),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text('Nossos serviços', style: headline(fontSize: 15)),
        const SizedBox(height: 4),
        for (var i = 0; i < rows.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: i == rows.length - 1 ? null : Border(bottom: BorderSide(color: option.muted.withValues(alpha: 0.15))),
            ),
            child: Row(
              children: [
                Icon(rowIcons[i], size: 16, color: option.accent),
                const SizedBox(width: 10),
                Expanded(child: Text(rows[i], style: body(fontSize: 12, fontWeight: FontWeight.w600))),
                Icon(Icons.chevron_right, size: 16, color: option.muted),
              ],
            ),
          ),
      ],
    );
  }

  Widget _previewTile(String label, IconData icon, TextStyle Function({double fontSize, FontWeight fontWeight, Color? color}) body, bool highlighted) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: highlighted ? option.accent : option.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: highlighted ? Colors.white.withValues(alpha: 0.2) : option.accentSoft,
            ),
            child: Icon(icon, size: 15, color: highlighted ? Colors.white : option.accent),
          ),
          const SizedBox(height: 7),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(fontSize: 12, fontWeight: FontWeight.w600, color: highlighted ? Colors.white : null)),
        ],
      ),
    );
  }
}
