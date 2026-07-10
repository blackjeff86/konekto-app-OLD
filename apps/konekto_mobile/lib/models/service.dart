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

/// Serviço criado pelo hotel (Room Service, Spa, um restaurante específico,
/// ou algo totalmente novo) — sem tipos fixos no código do app.
class Service {
  final String id;
  final String name;
  final String slug;
  final String icon;
  final String description;
  final String? bannerImageUrl;
  final List<ServiceItem> items;

  const Service({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
    required this.description,
    this.bannerImageUrl,
    this.items = const [],
  });

  /// Room Service é o único serviço com pedido "direto" (quantidade +
  /// observação) — todo o resto (restaurantes, spa, eventos, passeios) usa o
  /// fluxo de agendamento (dia + horário). Comparado pelo `slug` (estável e
  /// exclusivo do Room Service), não pelo `icon` (reaproveitado por vários
  /// serviços, ex: os 3 restaurantes usam o mesmo ícone).
  bool get isRoomService => slug == 'room-service';

  factory Service.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>?;
    return Service(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      icon: json['icon'] as String,
      description: json['description'] as String? ?? '',
      bannerImageUrl: json['bannerImageUrl'] as String?,
      items: rawItems == null
          ? const []
          : rawItems.map((raw) => ServiceItem.fromJson(raw as Map<String, dynamic>)).toList(),
    );
  }
}
