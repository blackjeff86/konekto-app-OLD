enum GuestOrderStatus {
  pending,
  inProgress,
  completed,
  cancelled;

  static GuestOrderStatus fromString(String value) {
    return switch (value) {
      'pending' => GuestOrderStatus.pending,
      'in_progress' => GuestOrderStatus.inProgress,
      'completed' => GuestOrderStatus.completed,
      'cancelled' => GuestOrderStatus.cancelled,
      _ => throw ArgumentError('Status de pedido desconhecido: "$value"'),
    };
  }

  /// Só um pedido `pending` pode ser editado ou cancelado pelo hóspede —
  /// uma vez que a cozinha/equipe começou o preparo (`in_progress`), a
  /// mudança já não é mais segura de fazer sem contato direto com a
  /// recepção.
  bool get isEditableByGuest => this == GuestOrderStatus.pending;
}

/// Pedido do PRÓPRIO hóspede, como devolvido por `GET /api/orders` — usado
/// pela tela "Meus Pedidos" pra acompanhar status, editar (enquanto
/// pendente) ou cancelar.
class GuestOrder {
  final String id;
  final String serviceId;
  final String serviceItemId;
  final String itemName;
  final int quantity;
  final double? price;
  final GuestOrderStatus status;
  final String? note;
  final DateTime? scheduledFor;
  final DateTime createdAt;
  final double? discountAmount;
  final String? couponTitle;
  final String? recordedByStaffId;
  final String? partnerName;
  final bool isPartnerPaid;

  const GuestOrder({
    required this.id,
    required this.serviceId,
    required this.serviceItemId,
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

  /// `true` quando a RECEPÇÃO lançou esse consumo em nome do hóspede (ex:
  /// item de frigobar notado faltando na conferência do quarto) — `false`
  /// quando o próprio hóspede criou o pedido.
  bool get isStaffRecorded => recordedByStaffId != null;

  factory GuestOrder.fromJson(Map<String, dynamic> json) {
    final coupon = json['coupon'] as Map<String, dynamic>?;
    return GuestOrder(
      id: json['id'] as String,
      serviceId: json['serviceId'] as String,
      serviceItemId: json['serviceItemId'] as String,
      itemName: json['itemName'] as String,
      quantity: json['quantity'] as int? ?? 1,
      price: (json['price'] as num?)?.toDouble(),
      status: GuestOrderStatus.fromString(json['status'] as String),
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
