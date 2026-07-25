import 'package:flutter/material.dart';
import 'package:konekto/theme/guest_app_theme.dart';
import 'package:konekto/widgets/tenant_image.dart';

/// Logo do hotel (`hotelInfo.logoUrl`) — cai num ícone genérico quando o
/// hotel ainda não configurou um logo no portal. Igual em todos os
/// templates; só o ícone de fallback e o estilo (preenchido/contorno) mudam
/// por infra.
class TenantLogo extends StatelessWidget {
  final GuestAppTheme theme;
  final String tenantId;
  final double size;
  final BorderRadius borderRadius;
  final IconData fallbackIcon;
  final bool filled;

  const TenantLogo({
    super.key,
    required this.theme,
    required this.tenantId,
    required this.size,
    required this.borderRadius,
    required this.fallbackIcon,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final logoUrl = theme.logoUrl;
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: filled ? theme.accentSoft : null,
        border: filled ? null : Border.all(color: theme.borderColor),
        borderRadius: borderRadius,
      ),
      child: hasLogo
          ? TenantImage(imageUrl: logoUrl, hotelId: tenantId, fit: BoxFit.contain, width: size, height: size)
          : Icon(fallbackIcon, color: theme.accent, size: size * 0.5),
    );
  }
}
