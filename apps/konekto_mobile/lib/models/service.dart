/// Item de um serviço (prato, tratamento de spa, evento, passeio, ou
/// qualquer coisa que o hotel decida oferecer). `price == null` = não é
/// "comprável" — a UI mostra "Solicitar"/"Reservar" em vez de um preço.
class ServiceItem {
  final String id;
  final String name;
  final String description;
  final double? price;
  final String? imageUrl;
  final String? location;
  final String? category;
  final String? extraInfo;

  const ServiceItem({
    required this.id,
    required this.name,
    required this.description,
    this.price,
    this.imageUrl,
    this.location,
    this.category,
    this.extraInfo,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String?,
      location: json['location'] as String?,
      category: json['category'] as String?,
      extraInfo: json['extraInfo'] as String?,
    );
  }
}

/// Decide o comportamento do serviço nesta tela:
/// - `roomService`: pedido item a item (quantidade + observação).
/// - `restaurant`: cardápio só informativo; reserva é da MESA como um todo
///   (um botão único abaixo da lista), não por prato.
/// - `activity`: cada item abre o modal de dia/hora (spa, eventos, passeios).
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
}

/// Serviço criado pelo hotel (Room Service, Spa, um restaurante específico,
/// ou algo totalmente novo) — sem tipos fixos no código do app.
class Service {
  final String id;
  final String name;
  final String slug;
  final String icon;
  final String description;
  final ServiceType type;
  final String? bannerImageUrl;
  final List<ServiceItem> items;

  const Service({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
    required this.description,
    required this.type,
    this.bannerImageUrl,
    this.items = const [],
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>?;
    return Service(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      icon: json['icon'] as String,
      description: json['description'] as String? ?? '',
      type: ServiceType.fromString(json['type'] as String),
      bannerImageUrl: json['bannerImageUrl'] as String?,
      items: rawItems == null
          ? const []
          : rawItems.map((raw) => ServiceItem.fromJson(raw as Map<String, dynamic>)).toList(),
    );
  }
}
