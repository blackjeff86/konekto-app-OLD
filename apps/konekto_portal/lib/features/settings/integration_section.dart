import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:konekto_portal/api_config.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/integration_repository.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

/// Integração com o PMS/sistema de hotelaria que o hotel já usa —
/// diferente das outras seções de Configurações, aqui não editamos dado
/// nenhum: geramos uma chave de API pra esse sistema (ou um middleware
/// tipo Zapier/Make/n8n) empurrar reservas/hóspedes/cardápio pro Konekto,
/// e configuramos um webhook pra onde o Konekto manda os pedidos feitos
/// pelo hóspede no app.
class IntegrationSection extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const IntegrationSection({
    super.key,
    required this.session,
    required this.authRepository,
  });

  @override
  State<IntegrationSection> createState() => _IntegrationSectionState();
}

class _IntegrationSectionState extends State<IntegrationSection> {
  final _repository = IntegrationRepository();
  final _webhookController = TextEditingController();

  IntegrationStatus? _status;
  bool _isLoading = true;
  bool _isRotating = false;
  bool _isSavingWebhook = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _webhookController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(() {
        _errorMessage = 'Sessão expirada — saia e entre novamente.';
        _isLoading = false;
      });
      return;
    }
    try {
      final status = await _repository.getStatus(
        hotelId: widget.session.hotelId,
        token: token,
      );
      _status = status;
      _webhookController.text = status.webhookUrl ?? '';
    } on StateError catch (error) {
      _errorMessage = error.message;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rotateKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KonektoBrand.surface,
        title: Text(
          _status?.configured == true ? 'Gerar nova chave?' : 'Gerar chave de integração?',
          style: KonektoBrand.display(fontSize: 16),
        ),
        content: Text(
          _status?.configured == true
              ? 'A chave atual deixa de funcionar imediatamente — quem já usa precisa trocar pela nova.'
              : 'Essa chave é o que o PMS (ou o middleware que o hotel usar) precisa pra enviar dados pro Konekto.',
          style: KonektoBrand.body(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Gerar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(() => _errorMessage = 'Sessão expirada — saia e entre novamente.');
      return;
    }

    setState(() {
      _isRotating = true;
      _errorMessage = null;
    });
    try {
      final apiKey = await _repository.rotateApiKey(
        hotelId: widget.session.hotelId,
        token: token,
      );
      await _load();
      if (mounted) await _showApiKeyDialog(apiKey);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isRotating = false);
    }
  }

  Future<void> _showApiKeyDialog(String apiKey) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: KonektoBrand.surface,
        title: Text('Chave gerada', style: KonektoBrand.display(fontSize: 16)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Essa chave não vai ser mostrada de novo — copie e guarde num lugar seguro antes de fechar.',
                style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.gold),
              ),
              const SizedBox(height: 16),
              _CopyableField(
                value: apiKey,
                onCopy: () => _copyToClipboard(apiKey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copiado.')));
  }

  Future<void> _saveWebhook() async {
    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(() => _errorMessage = 'Sessão expirada — saia e entre novamente.');
      return;
    }
    setState(() {
      _isSavingWebhook = true;
      _errorMessage = null;
    });
    try {
      final url = _webhookController.text.trim();
      await _repository.setWebhookUrl(
        hotelId: widget.session.hotelId,
        token: token,
        webhookUrl: url.isEmpty ? null : url,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL do webhook salva.')),
        );
      }
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSavingWebhook = false);
    }
  }

  String _formatTimestamp(DateTime? date) {
    if (date == null) return 'Nunca';
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: KonektoBrand.gold));
    }

    final status = _status;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Integração com o PMS', style: KonektoBrand.display(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              'Conecte o sistema que o hotel já usa (ou um middleware como Zapier/Make/n8n) pra que reservas, '
              'hóspedes e cardápio sincronizem automaticamente pro Konekto, e os pedidos feitos pelo hóspede '
              'no app voltem pro sistema do hotel.',
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
                child: Text(
                  _errorMessage!,
                  style: KonektoBrand.body(fontSize: 12.5, color: const Color(0xFFF1A6A0)),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: KonektoBrand.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KonektoBrand.borderStrong),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Chave de API', style: KonektoBrand.display(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    status?.configured == true
                        ? 'Chave atual: ${status!.apiKeyPrefix}••••  ·  última sincronização recebida: ${_formatTimestamp(status.lastInboundSyncAt)}'
                        : 'Nenhuma chave gerada ainda.',
                    style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.slate),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _isRotating ? null : _rotateKey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KonektoBrand.gold,
                        foregroundColor: KonektoBrand.ink,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: _isRotating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: KonektoBrand.ink),
                            )
                          : Text(
                              status?.configured == true ? 'Gerar nova chave' : 'Gerar chave',
                              style: KonektoBrand.body(fontSize: 14, fontWeight: FontWeight.w700, color: KonektoBrand.ink),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: KonektoBrand.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KonektoBrand.borderStrong),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Webhook de pedidos', style: KonektoBrand.display(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    'URL do sistema do hotel (ou middleware) que recebe cada pedido feito pelo hóspede no app. '
                    'Último envio: ${_formatTimestamp(status?.lastOutboundAt)}'
                    '${status?.lastOutboundOk == false ? ' (falhou)' : ''}',
                    style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.slate),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _webhookController,
                    style: KonektoBrand.body(fontSize: 14, color: KonektoBrand.cream),
                    decoration: InputDecoration(
                      labelText: 'URL do webhook',
                      hintText: 'https://...',
                      labelStyle: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.slate),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.03),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: KonektoBrand.borderStrong, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: KonektoBrand.gold, width: 1.6),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _isSavingWebhook ? null : _saveWebhook,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KonektoBrand.gold,
                        foregroundColor: KonektoBrand.ink,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: _isSavingWebhook
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: KonektoBrand.ink),
                            )
                          : Text(
                              'Salvar',
                              style: KonektoBrand.body(fontSize: 14, fontWeight: FontWeight.w700, color: KonektoBrand.ink),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _HowToConnectPanel(),
          ],
        ),
      ),
    );
  }
}

class _HowToConnectPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KonektoBrand.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KonektoBrand.borderStrong),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text('Como conectar', style: KonektoBrand.display(fontSize: 16)),
          collapsedIconColor: KonektoBrand.slate,
          iconColor: KonektoBrand.gold,
          childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Text(
              'Use a chave gerada acima como Bearer token nesses endpoints. Reenviar o mesmo id sempre atualiza '
              '(nunca duplica).',
              style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.slate),
            ),
            const SizedBox(height: 16),
            const _EndpointDoc(
              method: 'PUT',
              path: '/api/integrations/v1/reservations/{id}',
              description: 'Cria/atualiza uma reserva de quarto (com os hóspedes vinculados).',
            ),
            const SizedBox(height: 12),
            const _EndpointDoc(
              method: 'PUT',
              path: '/api/integrations/v1/menu-categories/{id}',
              description: 'Cria/atualiza uma categoria do cardápio/serviços.',
            ),
            const SizedBox(height: 12),
            const _EndpointDoc(
              method: 'PUT',
              path: '/api/integrations/v1/menu-items/{id}',
              description: 'Cria/atualiza um item dentro de uma categoria já sincronizada.',
            ),
            const SizedBox(height: 16),
            Text('Exemplo', style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                'curl -X PUT $apiBaseUrl/api/integrations/v1/menu-categories/cat-001 \\\n'
                '  -H "Authorization: Bearer SUA_CHAVE" \\\n'
                '  -H "Content-Type: application/json" \\\n'
                '  -d \'{"name":"Room Service","icon":"room_service","description":"","type":"room_service","category":"Room Service"}\'',
                style: KonektoBrand.body(fontSize: 11.5, color: KonektoBrand.cream),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndpointDoc extends StatelessWidget {
  final String method;
  final String path;
  final String description;

  const _EndpointDoc({required this.method, required this.path, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: KonektoBrand.gold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                method,
                style: KonektoBrand.body(fontSize: 11, fontWeight: FontWeight.w700, color: KonektoBrand.gold),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                path,
                style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.cream),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(description, style: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate)),
      ],
    );
  }
}

class _CopyableField extends StatelessWidget {
  final String value;
  final VoidCallback onCopy;

  const _CopyableField({required this.value, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              value,
              style: KonektoBrand.body(fontSize: 13, color: KonektoBrand.cream),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Copiar',
            icon: const Icon(Icons.copy_outlined, size: 18, color: KonektoBrand.slate),
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}
