// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navServices => 'Services';

  @override
  String get navBookings => 'Bookings';

  @override
  String get navProfile => 'Profile';

  @override
  String get screenNotFound => 'Screen not found';

  @override
  String errorLoadingData(String error) {
    return 'Error loading data: $error';
  }

  @override
  String get notAvailable => 'Not available';

  @override
  String get sessionNotFound => 'We couldn\'t identify your session.';

  @override
  String get priceOnRequest => 'On request';

  @override
  String get dialogBack => 'Back';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get editAction => 'Edit';

  @override
  String get homeWelcomeBack => 'WELCOME BACK';

  @override
  String homeCheckinRoom(String room) {
    return 'Check-in complete · Room $room';
  }

  @override
  String homeWelcomeName(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get homeCheckinMessage =>
      'Check-in complete! Tap below to see your room details.';

  @override
  String get homeOurServices => 'Our services';

  @override
  String get quickTileServices => 'Services';

  @override
  String get quickTileHistory => 'History';

  @override
  String get quickTileMap => 'Property info';

  @override
  String get quickTileNotices => 'Notices';

  @override
  String get roomWifiDetails => 'Room & Wi-Fi details';

  @override
  String get roomWifiDetailsShort => 'Wi-Fi & room details';

  @override
  String roomNumberLabel(String room) {
    return 'Room: $room';
  }

  @override
  String wifiNetworkLabel(String network) {
    return 'Wi-Fi network: $network';
  }

  @override
  String wifiPasswordLabel(String password) {
    return 'Password: $password';
  }

  @override
  String get profileRoom => 'Room';

  @override
  String get profileEndSession => 'End Session';

  @override
  String get profileLanguage => 'Language';

  @override
  String get servicesTitle => 'Services';

  @override
  String get servicesEmpty => 'No services available right now.';

  @override
  String get servicesLoadError => 'Couldn\'t load services.';

  @override
  String get serviceItemsEmpty => 'No items available yet.';

  @override
  String get serviceLoadError => 'Couldn\'t load this service.';

  @override
  String get reserveTable => 'Reserve a table';

  @override
  String get minibarTitle => 'Minibar';

  @override
  String get minibarPageSubtitle =>
      'Tap what you consumed — it\'s added to your room bill automatically.';

  @override
  String get minibarEmpty => 'No minibar items set up yet.';

  @override
  String get minibarCardTitle => 'Minibar';

  @override
  String get minibarCardSubtitle => 'Report what you consumed from the room';

  @override
  String tableReservationName(String serviceName) {
    return 'Table at $serviceName';
  }

  @override
  String get reservationConfirmed =>
      'Reservation confirmed! The front desk has been notified.';

  @override
  String get addToOrder => 'Add to order';

  @override
  String get requestButton => 'Request';

  @override
  String get reserveButton => 'Reserve';

  @override
  String get orderSent => 'Order sent! The front desk has been notified.';

  @override
  String get requestSent => 'Request sent! The front desk will get in touch.';

  @override
  String get reportConsumptionButton => 'Report consumption';

  @override
  String get consumptionRecorded =>
      'Consumption recorded — added to your bill.';

  @override
  String get minibarDisclaimer =>
      'Room minibar item. Tap below to report what you consumed — it\'s added to your room bill automatically.';

  @override
  String get recordedByStaffTag => 'Added by reception';

  @override
  String paidToPartnerTag(String partnerName) {
    return 'Paid directly to the partner$partnerName';
  }

  @override
  String get noticesTitle => 'Notices';

  @override
  String get chatEmpty => 'No messages here yet.';

  @override
  String get chatHintText => 'Message the front desk...';

  @override
  String get chatReception => 'Front desk';

  @override
  String get chatYou => 'You';

  @override
  String get myOrdersTitle => 'My Orders';

  @override
  String get orderMore => 'Order more';

  @override
  String get noOrdersYet => 'You haven\'t placed any orders yet.';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get cancelOrderTitle => 'Cancel order?';

  @override
  String cancelOrderConfirm(String item) {
    return 'Are you sure you want to cancel \"$item\"?';
  }

  @override
  String get cancelOrderAction => 'Cancel order';

  @override
  String get cancelBookingTitle => 'Cancel booking?';

  @override
  String get cancelBookingAction => 'Cancel booking';

  @override
  String get noBookingsYet => 'No bookings yet';

  @override
  String get noBookingsDescription =>
      'Your spa, restaurant, and activity bookings will show up here once confirmed.';

  @override
  String get exploreServices => 'Explore Services';

  @override
  String get hotelInfoTitle => 'Property info';

  @override
  String get addressNotProvided => 'Address not provided';

  @override
  String get wifiNetworkInfoLabel => 'Wi-Fi network';

  @override
  String get wifiPasswordInfoLabel => 'Wi-Fi password';

  @override
  String get statusPendingItem => 'Pending';

  @override
  String get statusPendingBooking => 'Awaiting confirmation';

  @override
  String get statusInProgressItem => 'Preparing';

  @override
  String get statusInProgressBooking => 'Confirmed';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String noteLabel(String note) {
    return 'Note: $note';
  }

  @override
  String couponApplied(String coupon, String amount) {
    return '$coupon applied (-R\$ $amount)';
  }

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get couponLabel => 'Coupon';

  @override
  String get noCoupon => 'No coupon';

  @override
  String get couponAlreadyUsed => 'already used';

  @override
  String couponMinOrder(String value) {
    return 'min. R\$ $value';
  }

  @override
  String get noteOptionalLabel => 'Note (optional)';

  @override
  String get noteHint => 'E.g.: no onions, swap for orange juice...';

  @override
  String get confirmDefault => 'Confirm';

  @override
  String get dayLabel => 'Day';

  @override
  String get timeLabel => 'Time';

  @override
  String get amaraResortTag => 'RESORT';

  @override
  String get casaMarechalTag => 'HERITAGE';

  @override
  String get konektoClassicoTag => 'CLASSIC';

  @override
  String get konektoNoturnoTag => 'NOCTURNAL';

  @override
  String get eliteTag => 'ELITE';

  @override
  String get pulseTag => 'PULSE';

  @override
  String get casaFeaturedTitle => 'House Highlights';

  @override
  String get casaFeaturedSubtitle =>
      'Curated photos and moments from the hotel';

  @override
  String get casaConciergeTitle => 'Talk to the front desk';

  @override
  String get casaConciergeSubtitle =>
      'Request services, ask questions, or ask for anything special — our team is at your disposal.';

  @override
  String get casaConciergeCta => 'View services';

  @override
  String get bosqueQuote =>
      'In every walk with nature, one receives far more than he seeks.';

  @override
  String get myAccountTile => 'My account';

  @override
  String get profileLoyaltyTile => 'Loyalty program';

  @override
  String get profileWalletTile => 'Digital wallet';

  @override
  String get stayBillTitle => 'My account';

  @override
  String get stayBillBalanceDue => 'Balance due';

  @override
  String get stayBillOrders => 'Orders on this bill';

  @override
  String get stayBillPaymentUnavailable =>
      'Online payment isn\'t available at this hotel yet.';

  @override
  String get payNow => 'Pay now';

  @override
  String get payStayBillTitle => 'Pay your stay bill';

  @override
  String payStayBillAmount(String amount) {
    return 'Amount: $amount';
  }

  @override
  String get confirmPayment => 'Confirm payment';

  @override
  String get paymentSuccess => 'Payment confirmed!';
}
