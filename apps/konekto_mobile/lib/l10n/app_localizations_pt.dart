// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get navHome => 'Início';

  @override
  String get navServices => 'Serviços';

  @override
  String get navBookings => 'Reservas';

  @override
  String get navProfile => 'Perfil';

  @override
  String get screenNotFound => 'Tela não encontrada';

  @override
  String errorLoadingData(String error) {
    return 'Erro ao carregar dados: $error';
  }

  @override
  String get notAvailable => 'Não disponível';

  @override
  String get sessionNotFound => 'Não foi possível identificar sua sessão.';

  @override
  String get priceOnRequest => 'Sob consulta';

  @override
  String get dialogBack => 'Voltar';

  @override
  String get cancelAction => 'Cancelar';

  @override
  String get editAction => 'Editar';

  @override
  String get homeWelcomeBack => 'BEM-VINDO(A) DE VOLTA';

  @override
  String homeCheckinRoom(String room) {
    return 'Check-in realizado · Quarto $room';
  }

  @override
  String homeWelcomeName(String name) {
    return 'Bem-vindo, $name!';
  }

  @override
  String get homeCheckinMessage =>
      'Check-in realizado com sucesso! Toque abaixo para ver os detalhes do seu quarto.';

  @override
  String get homeOurServices => 'Nossos serviços';

  @override
  String get quickTileServices => 'Serviços';

  @override
  String get quickTileHistory => 'Histórico';

  @override
  String get quickTileMap => 'Mapa do local';

  @override
  String get quickTileNotices => 'Avisos';

  @override
  String get roomWifiDetails => 'Detalhes do Quarto e Wi-Fi';

  @override
  String get roomWifiDetailsShort => 'Wi-Fi & detalhes do quarto';

  @override
  String roomNumberLabel(String room) {
    return 'Quarto: $room';
  }

  @override
  String wifiNetworkLabel(String network) {
    return 'Rede Wi-Fi: $network';
  }

  @override
  String wifiPasswordLabel(String password) {
    return 'Senha: $password';
  }

  @override
  String get profileRoom => 'Quarto';

  @override
  String get profileEndSession => 'Encerrar Sessão';

  @override
  String get profileLanguage => 'Idioma';

  @override
  String get servicesTitle => 'Serviços';

  @override
  String get servicesEmpty => 'Nenhum serviço disponível no momento.';

  @override
  String get servicesLoadError => 'Erro ao carregar os serviços.';

  @override
  String get serviceItemsEmpty => 'Nenhum item disponível ainda.';

  @override
  String get serviceLoadError => 'Erro ao carregar o serviço.';

  @override
  String get reserveTable => 'Reservar mesa';

  @override
  String get minibarTitle => 'Frigobar';

  @override
  String get minibarPageSubtitle =>
      'Toque no que você consumiu — o valor entra automaticamente na conta do quarto.';

  @override
  String get minibarEmpty => 'Nenhum item de frigobar cadastrado ainda.';

  @override
  String get minibarCardTitle => 'Frigobar';

  @override
  String get minibarCardSubtitle => 'Informe o que você consumiu do quarto';

  @override
  String tableReservationName(String serviceName) {
    return 'Mesa em $serviceName';
  }

  @override
  String get reservationConfirmed =>
      'Reserva confirmada! A recepção foi notificada.';

  @override
  String get addToOrder => 'Adicionar ao pedido';

  @override
  String get requestButton => 'Solicitar';

  @override
  String get reserveButton => 'Reservar';

  @override
  String get orderSent => 'Pedido enviado! A recepção foi notificada.';

  @override
  String get requestSent =>
      'Solicitação enviada! A recepção entrará em contato.';

  @override
  String get reportConsumptionButton => 'Informar consumo';

  @override
  String get consumptionRecorded =>
      'Consumo registrado — foi adicionado à sua conta.';

  @override
  String get minibarDisclaimer =>
      'Item do frigobar do quarto. Toque abaixo pra informar o que você consumiu — o valor entra automaticamente na conta do quarto.';

  @override
  String get recordedByStaffTag => 'Lançado pela recepção';

  @override
  String paidToPartnerTag(String partnerName) {
    return 'Pago diretamente ao parceiro$partnerName';
  }

  @override
  String get noticesTitle => 'Avisos';

  @override
  String get chatEmpty => 'Nenhuma mensagem por aqui ainda.';

  @override
  String get chatHintText => 'Fale com a recepção...';

  @override
  String get chatReception => 'Recepção';

  @override
  String get chatYou => 'Você';

  @override
  String get myOrdersTitle => 'Meus Pedidos';

  @override
  String get orderMore => 'Pedir mais';

  @override
  String get noOrdersYet => 'Você ainda não fez nenhum pedido.';

  @override
  String get saveChanges => 'Salvar alterações';

  @override
  String get cancelOrderTitle => 'Cancelar pedido?';

  @override
  String cancelOrderConfirm(String item) {
    return 'Tem certeza que deseja cancelar \"$item\"?';
  }

  @override
  String get cancelOrderAction => 'Cancelar pedido';

  @override
  String get cancelBookingTitle => 'Cancelar reserva?';

  @override
  String get cancelBookingAction => 'Cancelar reserva';

  @override
  String get noBookingsYet => 'Nenhuma reserva por enquanto';

  @override
  String get noBookingsDescription =>
      'Suas reservas de spa, restaurantes e passeios vão aparecer aqui assim que forem confirmadas.';

  @override
  String get exploreServices => 'Explorar Serviços';

  @override
  String get hotelInfoTitle => 'Mapa do local';

  @override
  String get addressNotProvided => 'Endereço não informado';

  @override
  String get wifiNetworkInfoLabel => 'Rede Wi-Fi';

  @override
  String get wifiPasswordInfoLabel => 'Senha Wi-Fi';

  @override
  String get statusPendingItem => 'Pendente';

  @override
  String get statusPendingBooking => 'Aguardando confirmação';

  @override
  String get statusInProgressItem => 'Preparando';

  @override
  String get statusInProgressBooking => 'Confirmado';

  @override
  String get statusCompleted => 'Concluído';

  @override
  String get statusCancelled => 'Cancelado';

  @override
  String noteLabel(String note) {
    return 'Obs: $note';
  }

  @override
  String couponApplied(String coupon, String amount) {
    return '$coupon aplicado (-R\$ $amount)';
  }

  @override
  String get quantityLabel => 'Quantidade';

  @override
  String get couponLabel => 'Cupom';

  @override
  String get noCoupon => 'Sem cupom';

  @override
  String get couponAlreadyUsed => 'já usado';

  @override
  String couponMinOrder(String value) {
    return 'mín. R\$ $value';
  }

  @override
  String get noteOptionalLabel => 'Observação (opcional)';

  @override
  String get noteHint => 'Ex: sem cebola, trocar por suco de laranja...';

  @override
  String get confirmDefault => 'Confirmar';

  @override
  String get dayLabel => 'Dia';

  @override
  String get timeLabel => 'Horário';

  @override
  String get amaraResortTag => 'RESORT';

  @override
  String get casaMarechalTag => 'HERANÇA';

  @override
  String get casaFeaturedTitle => 'Destaques da Casa';

  @override
  String get casaFeaturedSubtitle => 'Fotos e momentos selecionados do hotel';

  @override
  String get casaConciergeTitle => 'Fale com a recepção';

  @override
  String get casaConciergeSubtitle =>
      'Peça serviços, tire dúvidas ou solicite algo especial — nossa equipe está à disposição.';

  @override
  String get casaConciergeCta => 'Ver serviços';

  @override
  String get myAccountTile => 'Minha conta';

  @override
  String get stayBillTitle => 'Minha conta';

  @override
  String get stayBillBalanceDue => 'Saldo em aberto';

  @override
  String get stayBillOrders => 'Pedidos desta conta';

  @override
  String get stayBillPaymentUnavailable =>
      'Pagamento online ainda não disponível neste hotel.';

  @override
  String get payNow => 'Pagar agora';

  @override
  String get payStayBillTitle => 'Pagar conta da estadia';

  @override
  String payStayBillAmount(String amount) {
    return 'Valor: $amount';
  }

  @override
  String get confirmPayment => 'Confirmar pagamento';

  @override
  String get paymentSuccess => 'Pagamento confirmado!';
}
