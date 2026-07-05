import 'package:flutter/material.dart';

/// Carrega a imagem de um item de catálogo (room service, spa, restaurantes,
/// eventos, passeios), que pode vir de duas fontes: um asset local
/// empacotado no app (conteúdo semeado originalmente, `imageUrl` é só um
/// nome de arquivo relativo) ou uma URL de rede real (itens adicionados
/// depois pelo portal, que não tem como empacotar um asset local dentro do
/// app). Decide com base no prefixo da URL.
class TenantImage extends StatelessWidget {
  final String? imageUrl;
  final String Function(String fileName) assetPathBuilder;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const TenantImage({
    super.key,
    required this.imageUrl,
    required this.assetPathBuilder,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  bool get _isNetworkUrl {
    final url = imageUrl;
    return url != null && (url.startsWith('http://') || url.startsWith('https://'));
  }

  @override
  Widget build(BuildContext context) {
    final image = _isNetworkUrl
        ? Image.network(
            imageUrl!,
            height: height,
            width: width,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _placeholder(),
          )
        : Image.asset(
            assetPathBuilder(imageUrl?.split('/').last ?? 'placeholder.png'),
            height: height,
            width: width,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _placeholder(),
          );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _placeholder() {
    return Container(
      height: height,
      width: width,
      color: const Color(0xFFEFF2F4),
      child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF9099A6)),
    );
  }
}
