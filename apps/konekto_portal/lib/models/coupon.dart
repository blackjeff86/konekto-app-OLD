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

  String get apiValue => switch (this) {
        CouponDiscountType.percentage => 'percentage',
        CouponDiscountType.fixedAmount => 'fixed_amount',
      };

  String get label => switch (this) {
        CouponDiscountType.percentage => 'Percentual',
        CouponDiscountType.fixedAmount => 'Valor fixo',
      };
}

/// Cupom/promoção cadastrado pelo hotel — o hóspede escolhe da lista de
/// cupons elegíveis ao fazer um pedido (não digita código). `code` existe
/// só pra referência/auditoria do staff.
class Coupon {
  final String id;
  final String title;
  final String description;
  final String code;
  final CouponDiscountType discountType;
  final double discountValue;
  final double? minOrderValue;
  final String? imageUrl;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final int? usageLimit;
  final int perGuestLimit;
  final bool enabled;

  const Coupon({
    required this.id,
    required this.title,
    required this.description,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.minOrderValue,
    this.imageUrl,
    this.validFrom,
    this.validUntil,
    this.usageLimit,
    required this.perGuestLimit,
    required this.enabled,
  });

  String get discountLabel => discountType == CouponDiscountType.percentage
      ? '${discountValue.toStringAsFixed(0)}%'
      : 'R\$ ${discountValue.toStringAsFixed(2)}';

  bool get isExpired => validUntil != null && validUntil!.isBefore(DateTime.now());

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      code: json['code'] as String,
      discountType: CouponDiscountType.fromString(json['discountType'] as String),
      discountValue: (json['discountValue'] as num).toDouble(),
      minOrderValue: (json['minOrderValue'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String?,
      validFrom: json['validFrom'] != null ? DateTime.parse(json['validFrom'] as String) : null,
      validUntil: json['validUntil'] != null ? DateTime.parse(json['validUntil'] as String) : null,
      usageLimit: json['usageLimit'] as int?,
      perGuestLimit: json['perGuestLimit'] as int,
      enabled: json['enabled'] as bool,
    );
  }
}

/// Dados do formulário de criação/edição de um cupom.
class CouponInput {
  final String title;
  final String description;
  final String code;
  final CouponDiscountType discountType;
  final double discountValue;
  final double? minOrderValue;
  final String? imageUrl;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final int? usageLimit;
  final int perGuestLimit;
  final bool? enabled;

  const CouponInput({
    required this.title,
    required this.description,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.minOrderValue,
    this.imageUrl,
    this.validFrom,
    this.validUntil,
    this.usageLimit,
    this.perGuestLimit = 1,
    this.enabled,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'code': code,
      'discountType': discountType.apiValue,
      'discountValue': discountValue,
      'minOrderValue': minOrderValue,
      'imageUrl': imageUrl,
      'validFrom': validFrom?.toIso8601String(),
      'validUntil': validUntil?.toIso8601String(),
      'usageLimit': usageLimit,
      'perGuestLimit': perGuestLimit,
      if (enabled != null) 'enabled': enabled,
    };
  }
}
