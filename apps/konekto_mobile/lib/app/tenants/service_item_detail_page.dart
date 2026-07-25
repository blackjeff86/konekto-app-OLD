import 'package:flutter/material.dart';
import 'package:konekto/app/tenants/booking_sheet.dart';
import 'package:konekto/app/tenants/order_quantity_note_sheet.dart';
import 'package:konekto/data/coupons_repository.dart';
import 'package:konekto/data/guest_claim_repository.dart';
import 'package:konekto/data/orders_repository.dart';
import 'package:konekto/data/tenant_repository.dart';
import 'package:konekto/data/tenant_repository_provider.dart';
import 'package:konekto/l10n/app_localizations.dart';
import 'package:konekto/models/coupon.dart';
import 'package:konekto/models/service.dart';
import 'package:konekto/theme/guest_app_theme.dart';
import 'package:konekto/widgets/tenant_image.dart';

/// Detalhe de um item de serviço — substitui as 5 telas antigas de detalhe
/// (room_service_detail, spa_detail, restaurant_detail, event_detail,
/// passeios_detail) por uma única tela genérica.
///
/// Comportamento escolhido por [serviceType]:
/// - **`roomService`**: [showOrderQuantityNoteSheet] (quantidade +
///   observação) — `item.price != null` mostra "Adicionar ao pedido",
///   `item.price == null` mostra "Solicitar".
/// - **`activity`** (spa, eventos, passeios): [showBookingSheet] (dia +
///   horário) — botão sempre "Reservar".
/// - **`restaurant`**: só informativo, sem botão — o cardápio é pra
///   consulta; a reserva é da MESA como um todo, feita pelo botão no
///   rodapé de `ServiceItemsListPage`, não item a item.
///
/// O seletor de "pessoa alocada no quarto" ainda não existe aqui — depende
/// da entidade Stay (reserva de quarto), planejada pra depois; por
/// enquanto a reserva sempre fica em nome de quem está logado.
///
/// Pedido real: faz um `POST /api/orders` de verdade usando o guest token
/// salvo em `GuestClaimRepository`. Só cai no SnackBar de simulação no modo
/// asset (`USE_API=false`, sem backend real pra vincular o pedido) — no
/// modo API (produção) o hóspede sempre tem token, já que a entrada no app
/// exige um claim bem-sucedido.
class ServiceItemDetailPage extends StatefulWidget {
  final Map<String, dynamic> tenantConfig;
  final String serviceId;
  final String serviceName;
  final ServiceType serviceType;
  final Service service;
  final ServiceItem item;
  final String hotelId;
  final GuestAppTheme theme;
  /// `true` quando aberto a partir da tela de Frigobar — o hóspede está
  /// informando um consumo que já aconteceu, não pedindo algo pra
  /// preparar. O mesmo item (`item.isMinibarItem`) pode ser aberto também
  /// via Serviço de Quarto normalmente (`false`) — ex: pedir mais uma
  /// água pra ser entregue, em vez de informar que já bebeu uma do
  /// frigobar. É o CAMINHO de navegação que decide o comportamento, não
  /// só a flag do item.
  final bool isMinibarReportFlow;

  const ServiceItemDetailPage({
    super.key,
    required this.tenantConfig,
    required this.serviceId,
    required this.serviceName,
    required this.serviceType,
    required this.service,
    required this.item,
    required this.hotelId,
    required this.theme,
    this.isMinibarReportFlow = false,
  });

  @override
  State<ServiceItemDetailPage> createState() => _ServiceItemDetailPageState();
}

class _ServiceItemDetailPageState extends State<ServiceItemDetailPage> {
  final GuestClaimRepository _guestClaimRepository = GuestClaimRepository();
  final OrdersRepository _ordersRepository = OrdersRepository();
  final CouponsRepository _couponsRepository = CouponsRepository();
  final TenantRepository _tenantRepository = createTenantRepository();
  bool _isSubmitting = false;

  GuestAppTheme get theme => widget.theme;
  ServiceItem get item => widget.item;

  /// Só bloqueia Serviço de Quarto — `activity` já tem seu próprio controle
  /// fino por item, e `restaurant` nem mostra este botão (reserva é de
  /// mesa, no rodapé de `ServiceItemsListPage`). O fluxo de informar
  /// consumo do frigobar nunca bloqueia por horário — o frigobar físico do
  /// quarto está sempre acessível, mesmo que o serviço em que o item vive
  /// tenha horário de funcionamento restrito (ex: cozinha fechada de
  /// madrugada). Pedir o mesmo item pelo Serviço de Quarto normal continua
  /// respeitando o horário, porque aí é um pedido de verdade pra entregar.
  bool get _isClosedRoomService =>
      widget.serviceType == ServiceType.roomService && !widget.isMinibarReportFlow && !widget.service.isOpenNow;

  Future<List<TimeSlot>> _loadAvailability(DateTime date) async {
    final json = await _tenantRepository.getItemAvailability(
      hotelId: widget.hotelId,
      serviceId: widget.serviceId,
      itemId: item.id,
      date: date,
    );
    final rawSlots = json['slots'] as List<dynamic>? ?? const [];
    return rawSlots
        .map(
          (raw) => TimeSlot(
            time: (raw as Map<String, dynamic>)['time'] as String,
            available: raw['available'] as bool,
          ),
        )
        .toList();
  }

  Future<void> _confirm(BuildContext context) async {
    switch (widget.serviceType) {
      case ServiceType.roomService:
        await _confirmOrder(context);
      case ServiceType.activity:
        await _confirmBooking(context);
      case ServiceType.restaurant:
        break;
    }
  }

  Future<void> _confirmOrder(BuildContext context) async {
    if (_isClosedRoomService) return;
    final l10n = AppLocalizations.of(context)!;
    final bool isPurchasable = item.price != null;

    // Informar consumo do frigobar: o hóspede está relatando algo que já
    // aconteceu, não pedindo algo pra preparar — não faz sentido oferecer
    // cupom aqui.
    var availableCoupons = const <Coupon>[];
    if (isPurchasable && !widget.isMinibarReportFlow) {
      final guestToken = await _guestClaimRepository.getStoredToken();
      if (guestToken != null) {
        try {
          availableCoupons = await _couponsRepository.listAvailable(
            token: guestToken,
          );
        } on StateError {
          availableCoupons = const [];
        }
      }
    }
    if (!context.mounted) return;

    final result = await showOrderQuantityNoteSheet(
      context,
      itemName: item.name,
      fontFamily: theme.tokens.bodyFontFamily,
      headlineFontFamily: theme.tokens.headlineFontFamily,
      primaryColor: theme.accent,
      backgroundColor: theme.bg,
      bodyTextColor: theme.mutedColor,
      confirmLabel: widget.isMinibarReportFlow ? l10n.reportConsumptionButton : (isPurchasable ? l10n.addToOrder : l10n.requestButton),
      itemPrice: item.price,
      availableCoupons: availableCoupons,
    );
    if (result == null) return;
    if (!context.mounted) return;

    await _submitOrder(
      context,
      quantity: result.quantity,
      note: result.note,
      couponId: result.couponId,
      successMessage: widget.isMinibarReportFlow ? l10n.consumptionRecorded : (isPurchasable ? l10n.orderSent : l10n.requestSent),
    );
  }

  Future<void> _confirmBooking(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final schedulingEnabled = item.durationMinutes != null;
    final result = await showBookingSheet(
      context,
      itemName: item.name,
      fontFamily: theme.tokens.bodyFontFamily,
      headlineFontFamily: theme.tokens.headlineFontFamily,
      primaryColor: theme.accent,
      backgroundColor: theme.bg,
      bodyTextColor: theme.mutedColor,
      schedulingEnabled: schedulingEnabled,
      loadAvailability: schedulingEnabled ? _loadAvailability : null,
    );
    if (result == null) return;
    if (!context.mounted) return;

    await _submitOrder(
      context,
      quantity: 1,
      scheduledFor: result.dateTime,
      successMessage: l10n.reservationConfirmed,
    );
  }

  Future<void> _submitOrder(
    BuildContext context, {
    required int quantity,
    String? note,
    DateTime? scheduledFor,
    String? couponId,
    required String successMessage,
  }) async {
    final guestToken = await _guestClaimRepository.getStoredToken();
    if (guestToken == null) {
      if (!context.mounted) return;
      _showSnackBar(context, message: successMessage, color: theme.accent);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _ordersRepository.createOrder(
        serviceId: widget.serviceId,
        serviceItemId: item.id,
        token: guestToken,
        quantity: quantity,
        note: note,
        scheduledFor: scheduledFor,
        couponId: couponId,
        isConsumptionReport: widget.isMinibarReportFlow,
      );
      if (!context.mounted) return;
      _showSnackBar(context, message: successMessage, color: theme.accent);
    } on StateError catch (error) {
      if (!context.mounted) return;
      _showSnackBar(
        context,
        message: error.message,
        color: Colors.red.shade700,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color color,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: theme.body(color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final bool isPurchasable = item.price != null;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(theme.tokens.heroRadius),
                      bottomRight: Radius.circular(theme.tokens.heroRadius),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: TenantImage(
                    imageUrl: item.imageUrl,
                    hotelId: widget.hotelId,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(theme.tokens.heroRadius),
                      bottomRight: Radius.circular(theme.tokens.heroRadius),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: theme.textColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.serviceName,
                    style: theme.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.mutedColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.localizedName(languageCode),
                    style: theme.headline(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPurchasable
                        ? 'R\$ ${item.price!.toStringAsFixed(2)}'
                        : l10n.priceOnRequest,
                    style: theme.body(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: theme.accent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.localizedDescription(languageCode),
                    style: theme.body(
                      fontSize: 15,
                      color: theme.mutedColor,
                      height: 1.5,
                    ),
                  ),
                  if (item.localizedLocation(languageCode) != null) ...[
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.place_outlined,
                      label: item.localizedLocation(languageCode)!,
                      theme: theme,
                    ),
                  ],
                  if (item.localizedCategory(languageCode) != null) ...[
                    const SizedBox(height: 8),
                    _DetailRow(
                      icon: Icons.category_outlined,
                      label: item.localizedCategory(languageCode)!,
                      theme: theme,
                    ),
                  ],
                  if (item.localizedExtraInfo(languageCode) != null) ...[
                    const SizedBox(height: 8),
                    _DetailRow(
                      icon: Icons.info_outline,
                      label: item.localizedExtraInfo(languageCode)!,
                      theme: theme,
                    ),
                  ],
                  if (_isClosedRoomService) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.mutedColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          theme.tokens.cardRadius,
                        ),
                      ),
                      child: Text(
                        widget.service.operatingHoursLabel != null
                            ? 'Fechado agora — funciona das ${widget.service.operatingHoursLabel}.'
                            : 'Fechado agora.',
                        style: theme.body(
                          fontSize: 13.5,
                          color: theme.mutedColor,
                        ),
                      ),
                    ),
                  ],
                  if (widget.serviceType == ServiceType.roomService && widget.isMinibarReportFlow) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(theme.tokens.cardRadius),
                      ),
                      child: Text(
                        l10n.minibarDisclaimer,
                        style: theme.body(fontSize: 13.5, color: theme.mutedColor),
                      ),
                    ),
                  ],
                  if (widget.serviceType != ServiceType.restaurant) ...[
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_isSubmitting || _isClosedRoomService)
                            ? null
                            : () => _confirm(context),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                widget.serviceType == ServiceType.roomService
                                    ? (widget.isMinibarReportFlow
                                          ? Icons.kitchen_outlined
                                          : (isPurchasable ? Icons.shopping_cart : Icons.event_available_outlined))
                                    : Icons.calendar_month_outlined,
                                size: 22,
                              ),
                        label: Text(
                          widget.serviceType == ServiceType.roomService
                              ? (widget.isMinibarReportFlow
                                    ? l10n.reportConsumptionButton
                                    : (isPurchasable ? l10n.addToOrder : l10n.requestButton))
                              : l10n.reserveButton,
                          style: theme.body(fontSize: 16, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              theme.tokens.cardRadius,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final GuestAppTheme theme;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.body(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: theme.textColor,
            ),
          ),
        ),
      ],
    );
  }
}
