import 'package:flutter/material.dart';
import 'package:konekto/theme/guest_app_theme.dart';

/// Agrupa os parâmetros que toda Home de template recebe — evita repetir a
/// mesma lista de campos em cada `XxxHomeContent` (Amara/Verde/Casa hoje,
/// Aura/Bosque/Elite/Pulse na Fase 3 do White Label).
class GuestHomeContentParams {
  final String tenantId;
  final String userName;
  final String roomNumber;
  final String wifiNetworkName;
  final String wifiPassword;
  final GuestAppTheme theme;
  final int notificationCount;
  final VoidCallback onNavigateToServices;
  final void Function(BuildContext context) onOpenNotices;
  final void Function(BuildContext context) onOpenMyOrders;
  final void Function(BuildContext context) onOpenHotelInfo;

  const GuestHomeContentParams({
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
