// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navHome => 'Inicio';

  @override
  String get navServices => 'Servicios';

  @override
  String get navBookings => 'Reservas';

  @override
  String get navProfile => 'Perfil';

  @override
  String get screenNotFound => 'Pantalla no encontrada';

  @override
  String errorLoadingData(String error) {
    return 'Error al cargar los datos: $error';
  }

  @override
  String get notAvailable => 'No disponible';

  @override
  String get sessionNotFound => 'No pudimos identificar tu sesión.';

  @override
  String get priceOnRequest => 'Consultar precio';

  @override
  String get dialogBack => 'Volver';

  @override
  String get cancelAction => 'Cancelar';

  @override
  String get editAction => 'Editar';

  @override
  String get homeWelcomeBack => 'BIENVENIDO(A) DE NUEVO';

  @override
  String homeCheckinRoom(String room) {
    return 'Check-in realizado · Habitación $room';
  }

  @override
  String homeWelcomeName(String name) {
    return '¡Bienvenido, $name!';
  }

  @override
  String get homeCheckinMessage =>
      '¡Check-in realizado con éxito! Toca abajo para ver los detalles de tu habitación.';

  @override
  String get homeOurServices => 'Nuestros servicios';

  @override
  String get quickTileServices => 'Servicios';

  @override
  String get quickTileHistory => 'Historial';

  @override
  String get quickTileMap => 'Información del lugar';

  @override
  String get quickTileNotices => 'Avisos';

  @override
  String get roomWifiDetails => 'Detalles de la habitación y Wi-Fi';

  @override
  String get roomWifiDetailsShort => 'Wi-Fi y detalles de la habitación';

  @override
  String roomNumberLabel(String room) {
    return 'Habitación: $room';
  }

  @override
  String wifiNetworkLabel(String network) {
    return 'Red Wi-Fi: $network';
  }

  @override
  String wifiPasswordLabel(String password) {
    return 'Contraseña: $password';
  }

  @override
  String get profileRoom => 'Habitación';

  @override
  String get profileEndSession => 'Cerrar Sesión';

  @override
  String get profileLanguage => 'Idioma';

  @override
  String get servicesTitle => 'Servicios';

  @override
  String get servicesEmpty => 'No hay servicios disponibles en este momento.';

  @override
  String get servicesLoadError => 'No se pudieron cargar los servicios.';

  @override
  String get serviceItemsEmpty => 'Todavía no hay artículos disponibles.';

  @override
  String get serviceLoadError => 'No se pudo cargar el servicio.';

  @override
  String get reserveTable => 'Reservar mesa';

  @override
  String get minibarTitle => 'Frigobar';

  @override
  String get minibarPageSubtitle =>
      'Toca lo que consumiste — se añade automáticamente a la cuenta de la habitación.';

  @override
  String get minibarEmpty =>
      'Todavía no hay artículos de frigobar configurados.';

  @override
  String get minibarCardTitle => 'Frigobar';

  @override
  String get minibarCardSubtitle =>
      'Informa lo que consumiste de la habitación';

  @override
  String tableReservationName(String serviceName) {
    return 'Mesa en $serviceName';
  }

  @override
  String get reservationConfirmed =>
      '¡Reserva confirmada! Se notificó a la recepción.';

  @override
  String get addToOrder => 'Añadir al pedido';

  @override
  String get requestButton => 'Solicitar';

  @override
  String get reserveButton => 'Reservar';

  @override
  String get orderSent => '¡Pedido enviado! Se notificó a la recepción.';

  @override
  String get requestSent =>
      '¡Solicitud enviada! La recepción se pondrá en contacto.';

  @override
  String get reportConsumptionButton => 'Registrar consumo';

  @override
  String get consumptionRecorded =>
      'Consumo registrado — se añadió a tu cuenta.';

  @override
  String get minibarDisclaimer =>
      'Artículo del frigobar de la habitación. Toca abajo para informar lo que consumiste — se añade automáticamente a la cuenta de la habitación.';

  @override
  String get recordedByStaffTag => 'Agregado por recepción';

  @override
  String paidToPartnerTag(String partnerName) {
    return 'Pagado directamente al socio$partnerName';
  }

  @override
  String get noticesTitle => 'Avisos';

  @override
  String get chatEmpty => 'Todavía no hay mensajes aquí.';

  @override
  String get chatHintText => 'Escribe a la recepción...';

  @override
  String get chatReception => 'Recepción';

  @override
  String get chatYou => 'Tú';

  @override
  String get myOrdersTitle => 'Mis Pedidos';

  @override
  String get orderMore => 'Pedir más';

  @override
  String get noOrdersYet => 'Todavía no has hecho ningún pedido.';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get cancelOrderTitle => '¿Cancelar pedido?';

  @override
  String cancelOrderConfirm(String item) {
    return '¿Seguro que quieres cancelar \"$item\"?';
  }

  @override
  String get cancelOrderAction => 'Cancelar pedido';

  @override
  String get cancelBookingTitle => '¿Cancelar reserva?';

  @override
  String get cancelBookingAction => 'Cancelar reserva';

  @override
  String get noBookingsYet => 'Todavía no tienes reservas';

  @override
  String get noBookingsDescription =>
      'Tus reservas de spa, restaurantes y paseos aparecerán aquí en cuanto se confirmen.';

  @override
  String get exploreServices => 'Explorar Servicios';

  @override
  String get hotelInfoTitle => 'Información del lugar';

  @override
  String get addressNotProvided => 'Dirección no informada';

  @override
  String get wifiNetworkInfoLabel => 'Red Wi-Fi';

  @override
  String get wifiPasswordInfoLabel => 'Contraseña Wi-Fi';

  @override
  String get statusPendingItem => 'Pendiente';

  @override
  String get statusPendingBooking => 'Esperando confirmación';

  @override
  String get statusInProgressItem => 'Preparando';

  @override
  String get statusInProgressBooking => 'Confirmado';

  @override
  String get statusCompleted => 'Completado';

  @override
  String get statusCancelled => 'Cancelado';

  @override
  String noteLabel(String note) {
    return 'Nota: $note';
  }

  @override
  String couponApplied(String coupon, String amount) {
    return '$coupon aplicado (-R\$ $amount)';
  }

  @override
  String get quantityLabel => 'Cantidad';

  @override
  String get couponLabel => 'Cupón';

  @override
  String get noCoupon => 'Sin cupón';

  @override
  String get couponAlreadyUsed => 'ya usado';

  @override
  String couponMinOrder(String value) {
    return 'mín. R\$ $value';
  }

  @override
  String get noteOptionalLabel => 'Nota (opcional)';

  @override
  String get noteHint => 'Ej.: sin cebolla, cambiar por jugo de naranja...';

  @override
  String get confirmDefault => 'Confirmar';

  @override
  String get dayLabel => 'Día';

  @override
  String get timeLabel => 'Hora';

  @override
  String get amaraResortTag => 'RESORT';

  @override
  String get casaMarechalTag => 'HERENCIA';

  @override
  String get konektoClassicoTag => 'CLÁSICO';

  @override
  String get konektoNoturnoTag => 'NOCTURNO';

  @override
  String get eliteTag => 'ELITE';

  @override
  String get pulseTag => 'PULSE';

  @override
  String get casaFeaturedTitle => 'Destacados de la Casa';

  @override
  String get casaFeaturedSubtitle => 'Fotos y momentos seleccionados del hotel';

  @override
  String get casaConciergeTitle => 'Hable con recepción';

  @override
  String get casaConciergeSubtitle =>
      'Solicite servicios, haga preguntas o pida algo especial — nuestro equipo está a su disposición.';

  @override
  String get casaConciergeCta => 'Ver servicios';

  @override
  String get bosqueQuote =>
      'En cada paseo por la naturaleza, recibimos mucho más de lo que buscamos.';

  @override
  String get myAccountTile => 'Mi cuenta';

  @override
  String get stayBillTitle => 'Mi cuenta';

  @override
  String get stayBillBalanceDue => 'Saldo pendiente';

  @override
  String get stayBillOrders => 'Pedidos de esta cuenta';

  @override
  String get stayBillPaymentUnavailable =>
      'El pago en línea todavía no está disponible en este hotel.';

  @override
  String get payNow => 'Pagar ahora';

  @override
  String get payStayBillTitle => 'Pagar la cuenta de la estadía';

  @override
  String payStayBillAmount(String amount) {
    return 'Monto: $amount';
  }

  @override
  String get confirmPayment => 'Confirmar pago';

  @override
  String get paymentSuccess => '¡Pago confirmado!';
}
