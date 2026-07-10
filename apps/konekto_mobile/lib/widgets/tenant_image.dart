import 'package:flutter/material.dart';

/// Carrega a imagem de um item de catálogo (room service, spa, restaurantes,
/// eventos, passeios), que pode vir de duas fontes: um asset local
/// empacotado no app (conteúdo semeado originalmente, `imageUrl` já é o
/// caminho completo do asset, ex.
/// `assets/tenant_assets/hotels/{{tenantId}}/images/spa/massagem.png`) ou uma
/// URL de rede real (itens adicionados depois pelo portal, que não tem como
/// empacotar um asset local dentro do app). Decide com base no prefixo da
/// URL. O placeholder `{{tenantId}}` (deixado por alguns dados semeados) é
/// substituído pelo [hotelId] real antes de resolver o asset.
class TenantImage extends StatelessWidget {
  final String? imageUrl;
  final String hotelId;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const TenantImage({
    super.key,
    required this.imageUrl,
    required this.hotelId,
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
    final url = imageUrl;
    Widget image;
    if (url == null || url.isEmpty) {
      image = _placeholder();
    } else if (_isNetworkUrl) {
      image = Image.network(
        url,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    } else {
      image = Image.asset(
        url.replaceAll('{{tenantId}}', hotelId),
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

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
