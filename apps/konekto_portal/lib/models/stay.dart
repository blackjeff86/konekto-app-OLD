import 'package:konekto_portal/models/order.dart' show OrderStatus;

enum StayStatus {
  active,
  closed;

  static StayStatus fromString(String value) {
    return StayStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => throw ArgumentError('Status de estadia desconhecido: "$value"'),
    );
  }

  String get label => switch (this) {
        StayStatus.active => 'Ativa',
        StayStatus.closed => 'Fechada',
      };
}

/// Resumo do quarto/estadia embutido dentro de um `Guest` — evita duplicar
/// `roomNumber`/`checkInDate`/`checkOutDate` por hóspede, já que esses
/// dados pertencem ao quarto, não à pessoa.
class StaySummary {
  final String roomNumber;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final StayStatus status;

  const StaySummary({
    required this.roomNumber,
    required this.checkInDate,
    required this.checkOutDate,
    required this.status,
  });

  factory StaySummary.fromJson(Map<String, dynamic> json) {
    return StaySummary(
      roomNumber: json['roomNumber'] as String,
      checkInDate: DateTime.parse(json['checkInDate'] as String),
      checkOutDate: DateTime.parse(json['checkOutDate'] as String),
      status: StayStatus.fromString(json['status'] as String),
    );
  }
}

/// Pedido/reserva de um hóspede, aninhado dentro de `Guest.orders` (página
/// de detalhe do hóspede) ou de `StayGuestSummary.orders` (resumo de
/// consumo antes de "fechar a conta") — não carrega `guest`/`hotelId`
/// porque já estamos no contexto de um hóspede/estadia específicos.
class GuestOrderSummary {
  final String id;
  final String itemName;
  final int quantity;
  final double? price;
  final OrderStatus status;
  final String? note;
  final DateTime? scheduledFor;
  final DateTime createdAt;
  final double? discountAmount;
  final String? couponTitle;
  final String? recordedByStaffId;
  final String? partnerName;
  final bool isPartnerPaid;

  const GuestOrderSummary({
    required this.id,
    required this.itemName,
    required this.quantity,
    this.price,
    required this.status,
    this.note,
    this.scheduledFor,
    required this.createdAt,
    this.discountAmount,
    this.couponTitle,
    this.recordedByStaffId,
    this.partnerName,
    this.isPartnerPaid = false,
  });

  /// `true` pra itens que passaram pelo fluxo de agendamento (restaurantes,
  /// spa, eventos, passeios) — `false` pra pedidos simples de Serviço de
  /// Quarto, que nunca têm horário marcado.
  bool get isBooking => scheduledFor != null;

  /// `true` quando a RECEPÇÃO lançou esse consumo em nome do hóspede —
  /// `false` quando o próprio hóspede criou o pedido.
  bool get isStaffRecorded => recordedByStaffId != null;

  factory GuestOrderSummary.fromJson(Map<String, dynamic> json) {
    final coupon = json['coupon'] as Map<String, dynamic>?;
    return GuestOrderSummary(
      id: json['id'] as String,
      itemName: json['itemName'] as String,
      quantity: json['quantity'] as int? ?? 1,
      price: (json['price'] as num?)?.toDouble(),
      status: OrderStatus.fromString(json['status'] as String),
      note: json['note'] as String?,
      scheduledFor: json['scheduledFor'] != null ? DateTime.parse(json['scheduledFor'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      couponTitle: coupon?['title'] as String?,
      recordedByStaffId: json['recordedByStaffId'] as String?,
      partnerName: json['partnerName'] as String?,
      isPartnerPaid: json['paymentMode'] == 'partner',
    );
  }
}

/// Um hóspede dentro de uma estadia, na visão da tela "Quartos" — inclui
/// os pedidos (pra montar o resumo de consumo antes de "fechar a conta"),
/// mas não o cadastro completo (isso vem de
/// `GET /api/hotels/:hotelId/guests/:guestId`, ao abrir o detalhe).
class StayGuestSummary {
  final String id;
  final String firstName;
  final String lastName;
  final String accessCode;
  final String status;
  final List<GuestOrderSummary> orders;

  const StayGuestSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.accessCode,
    required this.status,
    this.orders = const [],
  });

  String get fullName => '$firstName $lastName';

  factory StayGuestSummary.fromJson(Map<String, dynamic> json) {
    final rawOrders = json['orders'] as List<dynamic>?;
    return StayGuestSummary(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      accessCode: json['accessCode'] as String? ?? '',
      status: json['status'] as String,
      orders: rawOrders == null
          ? const []
          : rawOrders.map((raw) => GuestOrderSummary.fromJson(raw as Map<String, dynamic>)).toList(),
    );
  }
}

/// Aviso da recepção pra todos os hóspedes de uma estadia — só leitura do
/// lado do hóspede.
class StayNotice {
  final String id;
  final String message;
  final DateTime createdAt;

  const StayNotice({required this.id, required this.message, required this.createdAt});

  factory StayNotice.fromJson(Map<String, dynamic> json) {
    return StayNotice(
      id: json['id'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Reserva de um quarto — agrupa um ou mais hóspedes (marido, esposa,
/// filhos), cada um com seu próprio código de acesso, todos centralizados
/// no mesmo quarto/estadia.
enum MessageSender { guest, staff }

/// Mensagem de chat entre hóspede e recepção, por estadia — substitui
/// `StayNotice` pra qualquer envio novo (o hóspede pode responder); os
/// avisos antigos continuam aparecendo, só mesclados por data.
class StayMessage {
  final String id;
  final MessageSender senderType;
  final String? guestFirstName;
  final String body;
  final DateTime createdAt;

  const StayMessage({
    required this.id,
    required this.senderType,
    this.guestFirstName,
    required this.body,
    required this.createdAt,
  });

  factory StayMessage.fromJson(Map<String, dynamic> json) {
    final guest = json['guest'] as Map<String, dynamic>?;
    return StayMessage(
      id: json['id'] as String,
      senderType: json['senderType'] == 'staff' ? MessageSender.staff : MessageSender.guest,
      guestFirstName: guest?['firstName'] as String?,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class Stay {
  final String id;
  final String roomNumber;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final StayStatus status;
  final DateTime createdAt;
  final List<StayGuestSummary> guests;
  final List<StayNotice> notices;
  final List<StayMessage> messages;

  const Stay({
    required this.id,
    required this.roomNumber,
    required this.checkInDate,
    required this.checkOutDate,
    required this.status,
    required this.createdAt,
    this.guests = const [],
    this.notices = const [],
    this.messages = const [],
  });

  factory Stay.fromJson(Map<String, dynamic> json) {
    final rawGuests = json['guests'] as List<dynamic>?;
    final rawNotices = json['notices'] as List<dynamic>?;
    final rawMessages = json['messages'] as List<dynamic>?;
    return Stay(
      id: json['id'] as String,
      roomNumber: json['roomNumber'] as String,
      checkInDate: DateTime.parse(json['checkInDate'] as String),
      checkOutDate: DateTime.parse(json['checkOutDate'] as String),
      status: StayStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      guests: rawGuests == null
          ? const []
          : rawGuests.map((raw) => StayGuestSummary.fromJson(raw as Map<String, dynamic>)).toList(),
      notices: rawNotices == null
          ? const []
          : rawNotices.map((raw) => StayNotice.fromJson(raw as Map<String, dynamic>)).toList(),
      messages: rawMessages == null
          ? const []
          : rawMessages.map((raw) => StayMessage.fromJson(raw as Map<String, dynamic>)).toList(),
    );
  }
}

/// Dados do formulário de criação de uma nova estadia (passo 1, antes de
/// adicionar qualquer hóspede dentro dela). `roomId` referencia um quarto
/// já cadastrado (ver `RoomsRepository`) — não dá mais pra digitar um
/// número de quarto livre.
class NewStayInput {
  final String roomId;
  final DateTime checkInDate;
  final DateTime checkOutDate;

  const NewStayInput({required this.roomId, required this.checkInDate, required this.checkOutDate});

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'checkInDate': checkInDate.toIso8601String(),
      'checkOutDate': checkOutDate.toIso8601String(),
    };
  }
}
