import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:konekto_portal/api_config.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/data/upload_repository.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

const Map<String, String> _kExtensionToContentType = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
  'gif': 'image/gif',
  'avif': 'image/avif',
};

/// Campo de imagem compartilhado — usado nos 5 lugares do portal que
/// precisam de uma imagem (logo, carrossel, banner de Serviços, item do
/// cardápio, cupom). Mantém o campo de URL (staff que já tem uma imagem
/// hospedada em outro lugar ainda pode colar direto) e adiciona um botão
/// "Enviar imagem" (sobe o arquivo pro Vercel Blob via `UploadRepository`
/// e preenche a URL sozinho) mais um preview ao vivo — sem isso, staff só
/// descobria se a imagem ficou certa abrindo o app do hóspede depois.
class ImageUploadField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String hotelId;
  final AuthRepository authRepository;
  final ValueChanged<String>? onUploaded;

  const ImageUploadField({
    super.key,
    required this.label,
    required this.controller,
    required this.hotelId,
    required this.authRepository,
    this.onUploaded,
  });

  @override
  State<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<ImageUploadField> {
  final _repository = UploadRepository();

  bool _isUploading = false;
  String? _errorMessage;
  String _previewUrl = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _previewUrl = widget.controller.text.trim();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _previewUrl = widget.controller.text.trim());
    });
  }

  // Dado semeado antigo pode ter um caminho de asset local (ex:
  // "assets/tenant_assets/hotels/hotel_1/images/x.png"), empacotado só
  // dentro do app do hóspede — o portal não tem esse arquivo no próprio
  // bundle, então não tem como pré-visualizar. Mesma distinção que
  // `TenantImage` já faz do lado do app do hóspede.
  bool get _isNetworkUrl => _previewUrl.startsWith('http://') || _previewUrl.startsWith('https://');

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _kExtensionToContentType.keys.toList(),
      withData: true,
    );
    final file = result?.files.singleOrNull;
    if (file == null || file.bytes == null) return;

    final extension = (file.extension ?? '').toLowerCase();
    final contentType = _kExtensionToContentType[extension];
    if (contentType == null) {
      setState(() => _errorMessage = 'Formato não suportado — use JPEG, PNG, WebP, GIF ou AVIF.');
      return;
    }

    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(() => _errorMessage = 'Sessão expirada — saia e entre novamente.');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });
    try {
      final url = await _repository.uploadImage(
        hotelId: widget.hotelId,
        token: token,
        fileName: file.name,
        contentType: contentType,
        bytes: file.bytes!,
      );
      widget.controller.text = url;
      setState(() => _previewUrl = url);
      widget.onUploaded?.call(url);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                style: KonektoBrand.body(fontSize: 13, color: KonektoBrand.cream),
                decoration: InputDecoration(
                  labelText: widget.label,
                  labelStyle: KonektoBrand.body(fontSize: 12, color: KonektoBrand.slate),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.03),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 46,
              child: OutlinedButton.icon(
                onPressed: _isUploading ? null : _pickAndUpload,
                style: OutlinedButton.styleFrom(
                  foregroundColor: KonektoBrand.goldLight,
                  side: const BorderSide(color: KonektoBrand.borderStrong),
                ),
                icon: _isUploading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: KonektoBrand.goldLight),
                      )
                    : const Icon(Icons.upload_outlined, size: 16),
                label: const Text('Enviar imagem'),
              ),
            ),
          ],
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 6),
          Text(_errorMessage!, style: KonektoBrand.body(fontSize: 11.5, color: const Color(0xFFF1A6A0))),
        ],
        if (_previewUrl.isNotEmpty) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                border: Border.all(color: KonektoBrand.borderStrong),
                borderRadius: BorderRadius.circular(10),
              ),
              child: !_isNetworkUrl
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Essa é uma imagem padrão do sistema, não uma URL — envie um arquivo pra substituir e ver o preview.',
                          textAlign: TextAlign.center,
                          style: KonektoBrand.body(fontSize: 11.5, color: KonektoBrand.slate),
                        ),
                      ),
                    )
                  : Image.network(
                      '$apiBaseUrl/api/image-proxy?url=${Uri.encodeComponent(_previewUrl)}',
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: KonektoBrand.gold),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          'Não foi possível carregar essa imagem.',
                          style: KonektoBrand.body(fontSize: 11.5, color: KonektoBrand.slate),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ],
    );
  }
}
