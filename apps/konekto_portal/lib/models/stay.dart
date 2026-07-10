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

  const GuestOrderSummary({
    required this.id,
    required this.itemName,
    required this.quantity,
    this.price,
    required this.status,
    this.note,
    this.scheduledFor,
    required this.createdAt,
  });

  factory GuestOrderSummary.fromJson(Map<String, dynamic> json) {
    return GuestOrderSummary(
      id: json['id'] as String,
      itemName: json['itemName'] as String,
      quantity: json['quantity'] as int? ?? 1,
      price: (json['price'] as num?)?.toDouble(),
      status: OrderStatus.fromString(json['status'] as String),
      note: json['note'] as String?,
      scheduledFor: json['scheduledFor'] != null ? DateTime.parse(json['scheduledFor'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
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
class Stay {
  final String id;
  final String roomNumber;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final StayStatus status;
  final DateTime createdAt;
  final List<StayGuestSummary> guests;
  final List<StayNotice> notices;

  const Stay({
    required this.id,
    required this.roomNumber,
    required this.checkInDate,
    required this.checkOutDate,
    required this.status,
    required this.createdAt,
    this.guests = const [],
    this.notices = const [],
  });

  factory Stay.fromJson(Map<String, dynamic> json) {
    final rawGuests = json['guests'] as List<dynamic>?;
    final rawNotices = json['notices'] as List<dynamic>?;
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
    );
  }
}

/// Dados do formulário de criação de uma nova estadia (passo 1, antes de
/// adicionar qualquer hóspede dentro dela).
class NewStayInput {
  final String roomNumber;
  final DateTime checkInDate;
  final DateTime checkOutDate;

  const NewStayInput({required this.roomNumber, required this.checkInDate, required this.checkOutDate});

  Map<String, dynamic> toJson() {
    return {
      'roomNumber': roomNumber,
      'checkInDate': checkInDate.toIso8601String(),
      'checkOutDate': checkOutDate.toIso8601String(),
    };
  }
}
