enum CouponDiscountType {
  percentage,
  fixedAmount;

  static CouponDiscountType fromString(String value) {
    return switch (value) {
      'percentage' => CouponDiscountType.percentage,
      'fixed_amount' => CouponDiscountType.fixedAmount,
      _ => throw ArgumentError('Tipo de desconto desconhecido: "$value"'),
    };
  }
}

/// Cupom elegível pro hóspede autenticado, como devolvido por
/// `GET /api/coupons` — já vem filtrado por validade (ativo e dentro do
/// período); `eligible` indica se ele ainda pode ser usado (limite de uso
/// total ou por hóspede não atingido).
class Coupon {
  final String id;
  final String title;
  final String description;
  final CouponDiscountType discountType;
  final double discountValue;
  final double? minOrderValue;
  final bool eligible;

  const Coupon({
    required this.id,
    required this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderValue,
    required this.eligible,
  });

  String get discountLabel => discountType == CouponDiscountType.percentage
      ? '-${discountValue.toStringAsFixed(0)}%'
      : '-R\$ ${discountValue.toStringAsFixed(2)}';

  /// Quanto esse cupom desconta de um pedido com esse subtotal — usado só
  /// como prévia no app (o valor final e definitivo é sempre recalculado
  /// pelo servidor na hora de confirmar o pedido).
  double previewDiscount(double subtotal) {
    final raw = discountType == CouponDiscountType.percentage ? subtotal * (discountValue / 100) : discountValue;
    return raw > subtotal ? subtotal : raw;
  }

  bool meetsMinOrder(double subtotal) => minOrderValue == null || subtotal >= minOrderValue!;

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      discountType: CouponDiscountType.fromString(json['discountType'] as String),
      discountValue: (json['discountValue'] as num).toDouble(),
      minOrderValue: (json['minOrderValue'] as num?)?.toDouble(),
      eligible: json['eligible'] as bool,
    );
  }
}
