/// Item de um serviço (prato, tratamento de spa, evento, passeio, ou
/// qualquer coisa que o hotel decida oferecer). `price: null` = não é
/// "comprável" — a tela decide o que mostrar (ex: "Reservar" em vez de
/// preço) com base nisso.
class ServiceItem {
  final String id;
  final String name;
  final String description;
  final double? price;
  final String? imageUrl;
  final String? location;
  final String? category;
  final String? extraInfo;
  final int position;

  const ServiceItem({
    required this.id,
    required this.name,
    required this.description,
    this.price,
    this.imageUrl,
    this.location,
    this.category,
    this.extraInfo,
    required this.position,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String?,
      location: json['location'] as String?,
      category: json['category'] as String?,
      extraInfo: json['extraInfo'] as String?,
      position: json['position'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'location': location,
      'category': category,
      'extraInfo': extraInfo,
    };
  }

  ServiceItem copyWith({
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? location,
    String? category,
    String? extraInfo,
  }) {
    return ServiceItem(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      category: category ?? this.category,
      extraInfo: extraInfo ?? this.extraInfo,
      position: position,
    );
  }
}

/// Decide o comportamento do serviço no app do hóspede:
/// - `roomService`: cardápio pedido item a item (quantidade + observação).
/// - `restaurant`: cardápio só informativo; reserva é da MESA como um todo
///   (um botão único abaixo da lista), não por prato.
/// - `activity`: qualquer experiência agendável item a item (spa, eventos,
///   passeios, ou algo novo) — cada item abre o modal de dia/hora.
enum ServiceType {
  roomService,
  restaurant,
  activity;

  static ServiceType fromString(String value) {
    return switch (value) {
      'room_service' => ServiceType.roomService,
      'restaurant' => ServiceType.restaurant,
      'activity' => ServiceType.activity,
      _ => throw ArgumentError('Tipo de serviço desconhecido: "$value"'),
    };
  }

  String get apiValue => switch (this) {
        ServiceType.roomService => 'room_service',
        ServiceType.restaurant => 'restaurant',
        ServiceType.activity => 'activity',
      };

  String get label => switch (this) {
        ServiceType.roomService => 'Serviço de Quarto',
        ServiceType.restaurant => 'Restaurante',
        ServiceType.activity => 'Passeio / Atividade',
      };
}

/// Serviço criado pelo hotel (Room Service, Spa, um restaurante específico,
/// ou algo totalmente novo) — o hotel define nome/ícone/descrição, sem
/// tipos fixos no código. `type` decide o comportamento no app do hóspede
/// e é definido na criação, sem edição depois (mesmo padrão do `slug`).
class Service {
  final String id;
  final String hotelId;
  final String name;
  final String slug;
  final String icon;
  final String description;
  final ServiceType type;
  final String? bannerImageUrl;
  final int position;
  final bool enabled;
  final List<ServiceItem> items;

  const Service({
    required this.id,
    required this.hotelId,
    required this.name,
    required this.slug,
    required this.icon,
    required this.description,
    required this.type,
    this.bannerImageUrl,
    required this.position,
    required this.enabled,
    this.items = const [],
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>?;
    return Service(
      id: json['id'] as String,
      hotelId: json['hotelId'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      icon: json['icon'] as String,
      description: json['description'] as String,
      type: ServiceType.fromString(json['type'] as String),
      bannerImageUrl: json['bannerImageUrl'] as String?,
      position: json['position'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? true,
      items: rawItems == null
          ? const []
          : rawItems.map((raw) => ServiceItem.fromJson(raw as Map<String, dynamic>)).toList(),
    );
  }
}
