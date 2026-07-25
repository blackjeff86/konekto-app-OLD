import 'package:flutter/material.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Equivalente a [GuestHomeContentParams] (ver `guest_home_content_params.dart`),
/// só que pro sistema de temas novo (Aura/Bosque/Elite/Pulse/Horizon —
/// [GuestTemplateTheme]) em vez do antigo (5 templates — `GuestAppTheme`).
/// Os dois ficam separados por ora: unificá-los é trabalho de Fase 4
/// (cutover), quando só um sistema de tema vai restar.
class GuestTemplateContentParams {
  final String tenantId;
  final String userName;
  final String roomNumber;
  final String wifiNetworkName;
  final String wifiPassword;
  final GuestTemplateTheme theme;
  final int notificationCount;
  final VoidCallback onNavigateToServices;
  final void Function(BuildContext context) onOpenNotices;
  final void Function(BuildContext context) onOpenMyOrders;
  final void Function(BuildContext context) onOpenHotelInfo;

  const GuestTemplateContentParams({
    required this.tenantId,
    required this.userName,
    required this.roomNumber,
    required this.wifiNetworkName,
    required this.wifiPassword,
    required this.theme,
    required this.onNavigateToServices,
    required this.onOpenNotices,
    required this.onOpenMyOrders,
    required this.onOpenHotelInfo,
    this.notificationCount = 0,
  });
}
