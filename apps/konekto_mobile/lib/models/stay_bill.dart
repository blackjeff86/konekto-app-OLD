/// Um pedido que compõe a conta da estadia — mesmo pedido que aparece em
/// "Meus Pedidos", só que aqui listado pra fins de cobrança consolidada.
class StayBillOrder {
  final String id;
  final String itemName;
  final int quantity;
  final double price;
  final DateTime createdAt;

  const StayBillOrder({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.price,
    required this.createdAt,
  });

  factory StayBillOrder.fromJson(Map<String, dynamic> json) {
    return StayBillOrder(
      id: json['id'] as String,
      itemName: json['itemName'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Conta consolidada da estadia — `balanceDue` é sempre a fonte de
/// verdade calculada pelo backend (nunca recalcular no cliente pra
/// decidir quanto cobrar do cartão).
class StayBill {
  final List<StayBillOrder> orders;
  final double totalOrders;
  final double totalPaid;
  final double balanceDue;
  final bool onlinePaymentAvailable;

  const StayBill({
    required this.orders,
    required this.totalOrders,
    required this.totalPaid,
    required this.balanceDue,
    required this.onlinePaymentAvailable,
  });

  factory StayBill.fromJson(Map<String, dynamic> json) {
    final rawOrders = json['orders'] as List<dynamic>? ?? const [];
    return StayBill(
      orders: rawOrders.map((raw) => StayBillOrder.fromJson(raw as Map<String, dynamic>)).toList(),
      totalOrders: (json['totalOrders'] as num).toDouble(),
      totalPaid: (json['totalPaid'] as num).toDouble(),
      balanceDue: (json['balanceDue'] as num).toDouble(),
      onlinePaymentAvailable: json['onlinePaymentAvailable'] as bool? ?? false,
    );
  }
}
