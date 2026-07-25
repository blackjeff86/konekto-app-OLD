import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @navHome.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get navHome;

  /// No description provided for @navServices.
  ///
  /// In pt, this message translates to:
  /// **'Serviços'**
  String get navServices;

  /// No description provided for @navBookings.
  ///
  /// In pt, this message translates to:
  /// **'Reservas'**
  String get navBookings;

  /// No description provided for @navProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @screenNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Tela não encontrada'**
  String get screenNotFound;

  /// No description provided for @errorLoadingData.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar dados: {error}'**
  String errorLoadingData(String error);

  /// No description provided for @notAvailable.
  ///
  /// In pt, this message translates to:
  /// **'Não disponível'**
  String get notAvailable;

  /// No description provided for @sessionNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível identificar sua sessão.'**
  String get sessionNotFound;

  /// No description provided for @priceOnRequest.
  ///
  /// In pt, this message translates to:
  /// **'Sob consulta'**
  String get priceOnRequest;

  /// No description provided for @dialogBack.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get dialogBack;

  /// No description provided for @cancelAction.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancelAction;

  /// No description provided for @editAction.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get editAction;

  /// No description provided for @homeWelcomeBack.
  ///
  /// In pt, this message translates to:
  /// **'BEM-VINDO(A) DE VOLTA'**
  String get homeWelcomeBack;

  /// No description provided for @homeCheckinRoom.
  ///
  /// In pt, this message translates to:
  /// **'Check-in realizado · Quarto {room}'**
  String homeCheckinRoom(String room);

  /// No description provided for @homeWelcomeName.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo, {name}!'**
  String homeWelcomeName(String name);

  /// No description provided for @homeCheckinMessage.
  ///
  /// In pt, this message translates to:
  /// **'Check-in realizado com sucesso! Toque abaixo para ver os detalhes do seu quarto.'**
  String get homeCheckinMessage;

  /// No description provided for @homeOurServices.
  ///
  /// In pt, this message translates to:
  /// **'Nossos serviços'**
  String get homeOurServices;

  /// No description provided for @quickTileServices.
  ///
  /// In pt, this message translates to:
  /// **'Serviços'**
  String get quickTileServices;

  /// No description provided for @quickTileHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico'**
  String get quickTileHistory;

  /// No description provided for @quickTileMap.
  ///
  /// In pt, this message translates to:
  /// **'Mapa do local'**
  String get quickTileMap;

  /// No description provided for @quickTileNotices.
  ///
  /// In pt, this message translates to:
  /// **'Avisos'**
  String get quickTileNotices;

  /// No description provided for @roomWifiDetails.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes do Quarto e Wi-Fi'**
  String get roomWifiDetails;

  /// No description provided for @roomWifiDetailsShort.
  ///
  /// In pt, this message translates to:
  /// **'Wi-Fi & detalhes do quarto'**
  String get roomWifiDetailsShort;

  /// No description provided for @roomNumberLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quarto: {room}'**
  String roomNumberLabel(String room);

  /// No description provided for @wifiNetworkLabel.
  ///
  /// In pt, this message translates to:
  /// **'Rede Wi-Fi: {network}'**
  String wifiNetworkLabel(String network);

  /// No description provided for @wifiPasswordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Senha: {password}'**
  String wifiPasswordLabel(String password);

  /// No description provided for @profileRoom.
  ///
  /// In pt, this message translates to:
  /// **'Quarto'**
  String get profileRoom;

  /// No description provided for @profileEndSession.
  ///
  /// In pt, this message translates to:
  /// **'Encerrar Sessão'**
  String get profileEndSession;

  /// No description provided for @profileLanguage.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get profileLanguage;

  /// No description provided for @servicesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Serviços'**
  String get servicesTitle;

  /// No description provided for @servicesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum serviço disponível no momento.'**
  String get servicesEmpty;

  /// No description provided for @servicesLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar os serviços.'**
  String get servicesLoadError;

  /// No description provided for @serviceItemsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum item disponível ainda.'**
  String get serviceItemsEmpty;

  /// No description provided for @serviceLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar o serviço.'**
  String get serviceLoadError;

  /// No description provided for @reserveTable.
  ///
  /// In pt, this message translates to:
  /// **'Reservar mesa'**
  String get reserveTable;

  /// No description provided for @minibarTitle.
  ///
  /// In pt, this message translates to:
  /// **'Frigobar'**
  String get minibarTitle;

  /// No description provided for @minibarPageSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Toque no que você consumiu — o valor entra automaticamente na conta do quarto.'**
  String get minibarPageSubtitle;

  /// No description provided for @minibarEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum item de frigobar cadastrado ainda.'**
  String get minibarEmpty;

  /// No description provided for @minibarCardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Frigobar'**
  String get minibarCardTitle;

  /// No description provided for @minibarCardSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Informe o que você consumiu do quarto'**
  String get minibarCardSubtitle;

  /// No description provided for @tableReservationName.
  ///
  /// In pt, this message translates to:
  /// **'Mesa em {serviceName}'**
  String tableReservationName(String serviceName);

  /// No description provided for @reservationConfirmed.
  ///
  /// In pt, this message translates to:
  /// **'Reserva confirmada! A recepção foi notificada.'**
  String get reservationConfirmed;

  /// No description provided for @addToOrder.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar ao pedido'**
  String get addToOrder;

  /// No description provided for @requestButton.
  ///
  /// In pt, this message translates to:
  /// **'Solicitar'**
  String get requestButton;

  /// No description provided for @reserveButton.
  ///
  /// In pt, this message translates to:
  /// **'Reservar'**
  String get reserveButton;

  /// No description provided for @orderSent.
  ///
  /// In pt, this message translates to:
  /// **'Pedido enviado! A recepção foi notificada.'**
  String get orderSent;

  /// No description provided for @requestSent.
  ///
  /// In pt, this message translates to:
  /// **'Solicitação enviada! A recepção entrará em contato.'**
  String get requestSent;

  /// No description provided for @reportConsumptionButton.
  ///
  /// In pt, this message translates to:
  /// **'Informar consumo'**
  String get reportConsumptionButton;

  /// No description provided for @consumptionRecorded.
  ///
  /// In pt, this message translates to:
  /// **'Consumo registrado — foi adicionado à sua conta.'**
  String get consumptionRecorded;

  /// No description provided for @minibarDisclaimer.
  ///
  /// In pt, this message translates to:
  /// **'Item do frigobar do quarto. Toque abaixo pra informar o que você consumiu — o valor entra automaticamente na conta do quarto.'**
  String get minibarDisclaimer;

  /// No description provided for @recordedByStaffTag.
  ///
  /// In pt, this message translates to:
  /// **'Lançado pela recepção'**
  String get recordedByStaffTag;

  /// No description provided for @paidToPartnerTag.
  ///
  /// In pt, this message translates to:
  /// **'Pago diretamente ao parceiro{partnerName}'**
  String paidToPartnerTag(String partnerName);

  /// No description provided for @noticesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Avisos'**
  String get noticesTitle;

  /// No description provided for @chatEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma mensagem por aqui ainda.'**
  String get chatEmpty;

  /// No description provided for @chatHintText.
  ///
  /// In pt, this message translates to:
  /// **'Fale com a recepção...'**
  String get chatHintText;

  /// No description provided for @chatReception.
  ///
  /// In pt, this message translates to:
  /// **'Recepção'**
  String get chatReception;

  /// No description provided for @chatYou.
  ///
  /// In pt, this message translates to:
  /// **'Você'**
  String get chatYou;

  /// No description provided for @myOrdersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Meus Pedidos'**
  String get myOrdersTitle;

  /// No description provided for @orderMore.
  ///
  /// In pt, this message translates to:
  /// **'Pedir mais'**
  String get orderMore;

  /// No description provided for @noOrdersYet.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não fez nenhum pedido.'**
  String get noOrdersYet;

  /// No description provided for @saveChanges.
  ///
  /// In pt, this message translates to:
  /// **'Salvar alterações'**
  String get saveChanges;

  /// No description provided for @cancelOrderTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar pedido?'**
  String get cancelOrderTitle;

  /// No description provided for @cancelOrderConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja cancelar \"{item}\"?'**
  String cancelOrderConfirm(String item);

  /// No description provided for @cancelOrderAction.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar pedido'**
  String get cancelOrderAction;

  /// No description provided for @cancelBookingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar reserva?'**
  String get cancelBookingTitle;

  /// No description provided for @cancelBookingAction.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar reserva'**
  String get cancelBookingAction;

  /// No description provided for @noBookingsYet.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma reserva por enquanto'**
  String get noBookingsYet;

  /// No description provided for @noBookingsDescription.
  ///
  /// In pt, this message translates to:
  /// **'Suas reservas de spa, restaurantes e passeios vão aparecer aqui assim que forem confirmadas.'**
  String get noBookingsDescription;

  /// No description provided for @exploreServices.
  ///
  /// In pt, this message translates to:
  /// **'Explorar Serviços'**
  String get exploreServices;

  /// No description provided for @hotelInfoTitle.
  ///
  /// In pt, this message translates to:
  /// **'Mapa do local'**
  String get hotelInfoTitle;

  /// No description provided for @addressNotProvided.
  ///
  /// In pt, this message translates to:
  /// **'Endereço não informado'**
  String get addressNotProvided;

  /// No description provided for @wifiNetworkInfoLabel.
  ///
  /// In pt, this message translates to:
  /// **'Rede Wi-Fi'**
  String get wifiNetworkInfoLabel;

  /// No description provided for @wifiPasswordInfoLabel.
  ///
  /// In pt, this message translates to:
  /// **'Senha Wi-Fi'**
  String get wifiPasswordInfoLabel;

  /// No description provided for @statusPendingItem.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get statusPendingItem;

  /// No description provided for @statusPendingBooking.
  ///
  /// In pt, this message translates to:
  /// **'Aguardando confirmação'**
  String get statusPendingBooking;

  /// No description provided for @statusInProgressItem.
  ///
  /// In pt, this message translates to:
  /// **'Preparando'**
  String get statusInProgressItem;

  /// No description provided for @statusInProgressBooking.
  ///
  /// In pt, this message translates to:
  /// **'Confirmado'**
  String get statusInProgressBooking;

  /// No description provided for @statusCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Cancelado'**
  String get statusCancelled;

  /// No description provided for @noteLabel.
  ///
  /// In pt, this message translates to:
  /// **'Obs: {note}'**
  String noteLabel(String note);

  /// No description provided for @couponApplied.
  ///
  /// In pt, this message translates to:
  /// **'{coupon} aplicado (-R\$ {amount})'**
  String couponApplied(String coupon, String amount);

  /// No description provided for @quantityLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade'**
  String get quantityLabel;

  /// No description provided for @couponLabel.
  ///
  /// In pt, this message translates to:
  /// **'Cupom'**
  String get couponLabel;

  /// No description provided for @noCoupon.
  ///
  /// In pt, this message translates to:
  /// **'Sem cupom'**
  String get noCoupon;

  /// No description provided for @couponAlreadyUsed.
  ///
  /// In pt, this message translates to:
  /// **'já usado'**
  String get couponAlreadyUsed;

  /// No description provided for @couponMinOrder.
  ///
  /// In pt, this message translates to:
  /// **'mín. R\$ {value}'**
  String couponMinOrder(String value);

  /// No description provided for @noteOptionalLabel.
  ///
  /// In pt, this message translates to:
  /// **'Observação (opcional)'**
  String get noteOptionalLabel;

  /// No description provided for @noteHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: sem cebola, trocar por suco de laranja...'**
  String get noteHint;

  /// No description provided for @confirmDefault.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get confirmDefault;

  /// No description provided for @dayLabel.
  ///
  /// In pt, this message translates to:
  /// **'Dia'**
  String get dayLabel;

  /// No description provided for @timeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Horário'**
  String get timeLabel;

  /// No description provided for @amaraResortTag.
  ///
  /// In pt, this message translates to:
  /// **'RESORT'**
  String get amaraResortTag;

  /// No description provided for @casaMarechalTag.
  ///
  /// In pt, this message translates to:
  /// **'HERANÇA'**
  String get casaMarechalTag;

  /// No description provided for @casaFeaturedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Destaques da Casa'**
  String get casaFeaturedTitle;

  /// No description provided for @casaFeaturedSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Fotos e momentos selecionados do hotel'**
  String get casaFeaturedSubtitle;

  /// No description provided for @casaConciergeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Fale com a recepção'**
  String get casaConciergeTitle;

  /// No description provided for @casaConciergeSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Peça serviços, tire dúvidas ou solicite algo especial — nossa equipe está à disposição.'**
  String get casaConciergeSubtitle;

  /// No description provided for @casaConciergeCta.
  ///
  /// In pt, this message translates to:
  /// **'Ver serviços'**
  String get casaConciergeCta;

  /// No description provided for @myAccountTile.
  ///
  /// In pt, this message translates to:
  /// **'Minha conta'**
  String get myAccountTile;

  /// No description provided for @stayBillTitle.
  ///
  /// In pt, this message translates to:
  /// **'Minha conta'**
  String get stayBillTitle;

  /// No description provided for @stayBillBalanceDue.
  ///
  /// In pt, this message translates to:
  /// **'Saldo em aberto'**
  String get stayBillBalanceDue;

  /// No description provided for @stayBillOrders.
  ///
  /// In pt, this message translates to:
  /// **'Pedidos desta conta'**
  String get stayBillOrders;

  /// No description provided for @stayBillPaymentUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento online ainda não disponível neste hotel.'**
  String get stayBillPaymentUnavailable;

  /// No description provided for @payNow.
  ///
  /// In pt, this message translates to:
  /// **'Pagar agora'**
  String get payNow;

  /// No description provided for @payStayBillTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pagar conta da estadia'**
  String get payStayBillTitle;

  /// No description provided for @payStayBillAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor: {amount}'**
  String payStayBillAmount(String amount);

  /// No description provided for @confirmPayment.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar pagamento'**
  String get confirmPayment;

  /// No description provided for @paymentSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento confirmado!'**
  String get paymentSuccess;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
