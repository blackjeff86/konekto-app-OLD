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

  String get label => switch (this) {
        OrderStatus.pending => 'Pendente',
        OrderStatus.inProgress => 'Em andamento',
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
  });

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
    );
  }
}
