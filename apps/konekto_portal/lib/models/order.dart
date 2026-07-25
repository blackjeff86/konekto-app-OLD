enum OrderStatus {
  pending,
  inProgress,
  completed,
  cancelled;

  static OrderStatus fromString(String value) {
    return switch (value) {
      'pending' => OrderStatus.pending,
      'in_progress' => OrderStatus.inProgress,
      'completed' => OrderStatus.completed,
      'cancelled' => OrderStatus.cancelled,
      _ => throw ArgumentError('Status de pedido desconhecido: "$value"'),
    };
  }

  String get apiValue => switch (this) {
        OrderStatus.pending => 'pending',
        OrderStatus.inProgress => 'in_progress',
        OrderStatus.completed => 'completed',
        OrderStatus.cancelled => 'cancelled',
      };

  /// O rótulo muda conforme o tipo de pedido: item físico (Serviço de
  /// Quarto) segue um fluxo de preparo/entrega, enquanto reserva agendada
  /// (atividade, spa, mesa de restaurante) não "anda" fisicamente — só é
  /// confirmada e depois concluída após o horário marcado.
  String label(bool isBooking) => switch (this) {
        OrderStatus.pending => isBooking ? 'Aguardando confirmação' : 'Pendente',
        OrderStatus.inProgress => isBooking ? 'Confirmado' : 'Preparando',
        OrderStatus.completed => 'Concluído',
        OrderStatus.cancelled => 'Cancelado',
      };
}

/// Pedido de um hóspede referenciando um item de serviço qualquer —
/// `itemName`/`price` são um snapshot do momento do pedido.
class Order {
  final String id;
  final String itemName;
  final int quantity;
  final double? price;
  final OrderStatus status;
  final String? note;
  final DateTime? scheduledFor;
  final String guestName;
  final String guestRoomNumber;
  final DateTime createdAt;
  final double? discountAmount;
  final String? couponTitle;
  final String? recordedByStaffId;
  final String? partnerName;
  final bool isPartnerPaid;

  const Order({
    required this.id,
    required this.itemName,
    required this.quantity,
    this.price,
    required this.status,
    this.note,
    this.scheduledFor,
    required this.guestName,
    required this.guestRoomNumber,
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

  /// `true` quando a RECEPÇÃO lançou esse consumo em nome do hóspede (ex:
  /// item de frigobar notado faltando na conferência do quarto) — `false`
  /// quando o próprio hóspede criou o pedido.
  bool get isStaffRecorded => recordedByStaffId != null;

  factory Order.fromJson(Map<String, dynamic> json) {
    final guest = json['guest'] as Map<String, dynamic>;
    final coupon = json['coupon'] as Map<String, dynamic>?;
    return Order(
      id: json['id'] as String,
      itemName: json['itemName'] as String,
      quantity: json['quantity'] as int? ?? 1,
      price: (json['price'] as num?)?.toDouble(),
      status: OrderStatus.fromString(json['status'] as String),
      note: json['note'] as String?,
      scheduledFor: json['scheduledFor'] != null ? DateTime.parse(json['scheduledFor'] as String) : null,
      guestName: '${guest['firstName']} ${guest['lastName']}',
      guestRoomNumber: guest['roomNumber'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      couponTitle: coupon?['title'] as String?,
      recordedByStaffId: json['recordedByStaffId'] as String?,
      partnerName: json['partnerName'] as String?,
      isPartnerPaid: json['paymentMode'] == 'partner',
    );
  }
}
