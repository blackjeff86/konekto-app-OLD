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

  String get label => switch (this) {
        GuestOrderStatus.pending => 'Aguardando confirmação',
        GuestOrderStatus.inProgress => 'Em preparo',
        GuestOrderStatus.completed => 'Concluído',
        GuestOrderStatus.cancelled => 'Cancelado',
      };

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
  final String itemName;
  final int quantity;
  final double? price;
  final GuestOrderStatus status;
  final String? note;
  final DateTime? scheduledFor;
  final DateTime createdAt;
  final double? discountAmount;
  final String? couponTitle;

  const GuestOrder({
    required this.id,
    required this.serviceId,
    required this.itemName,
    required this.quantity,
    this.price,
    required this.status,
    this.note,
    this.scheduledFor,
    required this.createdAt,
    this.discountAmount,
    this.couponTitle,
  });

  /// `true` pra itens que passaram pelo fluxo de agendamento (restaurantes,
  /// spa, eventos, passeios) — `false` pra pedidos simples de Serviço de
  /// Quarto, que nunca têm horário marcado.
  bool get isBooking => scheduledFor != null;

  factory GuestOrder.fromJson(Map<String, dynamic> json) {
    final coupon = json['coupon'] as Map<String, dynamic>?;
    return GuestOrder(
      id: json['id'] as String,
      serviceId: json['serviceId'] as String,
      itemName: json['itemName'] as String,
      quantity: json['quantity'] as int? ?? 1,
      price: (json['price'] as num?)?.toDouble(),
      status: GuestOrderStatus.fromString(json['status'] as String),
      note: json['note'] as String?,
      scheduledFor: json['scheduledFor'] != null ? DateTime.parse(json['scheduledFor'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      couponTitle: coupon?['title'] as String?,
    );
  }
}
