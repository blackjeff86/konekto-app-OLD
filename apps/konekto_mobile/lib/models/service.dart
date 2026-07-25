/// Traduções de campos de texto pra inglês/espanhol — formato
/// `{en: {campo: texto}, es: {campo: texto}}`. O português nunca aparece
/// aqui (é o próprio campo original) — pedir a tradução de um idioma sem
/// entrada cai no texto em português como fallback.
typedef FieldTranslations = Map<String, Map<String, String>>;

FieldTranslations _parseTranslations(dynamic raw) {
  if (raw is! Map) return const {};
  final result = <String, Map<String, String>>{};
  for (final entry in raw.entries) {
    final localeMap = entry.value;
    if (localeMap is Map) {
      result[entry.key as String] = localeMap.map(
        (key, value) => MapEntry(key as String, value as String),
      );
    }
  }
  return result;
}

String _localizedField(
  FieldTranslations translations,
  String languageCode,
  String field,
  String fallback,
) {
  final value = translations[languageCode]?[field];
  return (value == null || value.isEmpty) ? fallback : value;
}

String? _localizedNullableField(
  FieldTranslations translations,
  String languageCode,
  String field,
  String? fallback,
) {
  if (fallback == null) return null;
  final value = translations[languageCode]?[field];
  return (value == null || value.isEmpty) ? fallback : value;
}

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
  final FieldTranslations translations;
  /// `null` = agendamento livre (dia/hora escolhidos sem restrição). Setado
  /// = o hóspede precisa escolher um horário da grade de disponibilidade
  /// (`GET .../items/[id]/availability`) em vez de um horário livre.
  final int? durationMinutes;
  /// Item de frigobar/minibar — em vez do fluxo normal de pedido, o hóspede
  /// só informa o que já consumiu (nasce direto `completed`, sem preparo).
  final bool isMinibarItem;

  const ServiceItem({
    required this.id,
    required this.name,
    required this.description,
    this.price,
    this.imageUrl,
    this.location,
    this.category,
    this.extraInfo,
    this.translations = const {},
    this.durationMinutes,
    this.isMinibarItem = false,
  });

  String localizedName(String languageCode) =>
      _localizedField(translations, languageCode, 'name', name);
  String localizedDescription(String languageCode) =>
      _localizedField(translations, languageCode, 'description', description);
  String? localizedLocation(String languageCode) =>
      _localizedNullableField(translations, languageCode, 'location', location);
  String? localizedCategory(String languageCode) =>
      _localizedNullableField(translations, languageCode, 'category', category);
  String? localizedExtraInfo(String languageCode) => _localizedNullableField(
    translations,
    languageCode,
    'extraInfo',
    extraInfo,
  );

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
      translations: _parseTranslations(json['translations']),
      durationMinutes: json['durationMinutes'] as int?,
      isMinibarItem: json['isMinibarItem'] as bool? ?? false,
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
  final FieldTranslations translations;

  /// Horário de funcionamento do SERVIÇO inteiro (não confundir com a
  /// janela por item, só usada por `activity`) — vazio/`null` = sem
  /// restrição. Só relevante pra `roomService`/`restaurant`.
  final List<int> operatingDaysOfWeek;
  final int? operatingStartMinute;
  final int? operatingEndMinute;

  const Service({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
    required this.description,
    required this.type,
    this.bannerImageUrl,
    this.items = const [],
    this.translations = const {},
    this.operatingDaysOfWeek = const [],
    this.operatingStartMinute,
    this.operatingEndMinute,
  });

  String localizedName(String languageCode) =>
      _localizedField(translations, languageCode, 'name', name);
  String localizedDescription(String languageCode) =>
      _localizedField(translations, languageCode, 'description', description);

  /// `true` se não houver horário configurado, ou se `instant` cair dentro
  /// da janela — com suporte a janela que atravessa meia-noite (ex:
  /// restaurante que funciona das 19h às 01h) quando
  /// `operatingEndMinute <= operatingStartMinute`. Mesma lógica de
  /// `isWithinOperatingHours` no backend (`lib/scheduling.ts`), usando a
  /// hora de parede local do dispositivo — mesma convenção "sem timezone"
  /// já usada em todo o app pra `scheduledFor`.
  bool isOpenAt(DateTime instant) {
    final start = operatingStartMinute;
    final end = operatingEndMinute;
    if (operatingDaysOfWeek.isEmpty || start == null || end == null) {
      return true;
    }

    final minute = instant.hour * 60 + instant.minute;
    final weekday = instant.weekday; // já é ISO 1-7 (1=segunda...7=domingo)
    final previousWeekday = weekday == 1 ? 7 : weekday - 1;

    if (end > start) {
      return operatingDaysOfWeek.contains(weekday) &&
          minute >= start &&
          minute < end;
    }
    final openingTonight =
        operatingDaysOfWeek.contains(weekday) && minute >= start;
    final stillOpenFromLastNight =
        operatingDaysOfWeek.contains(previousWeekday) && minute < end;
    return openingTonight || stillOpenFromLastNight;
  }

  bool get isOpenNow => isOpenAt(DateTime.now());

  /// "07:00 às 23:00" pra mostrar numa mensagem tipo "Fechado agora —
  /// funciona das 7h às 23h" — `null` quando não há horário configurado.
  String? get operatingHoursLabel {
    final start = operatingStartMinute;
    final end = operatingEndMinute;
    if (start == null || end == null) return null;
    String format(int minute) {
      final hours = (minute ~/ 60).toString().padLeft(2, '0');
      final minutes = (minute % 60).toString().padLeft(2, '0');
      return '$hours:$minutes';
    }

    return '${format(start)} às ${format(end)}';
  }

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
          : rawItems
                .map((raw) => ServiceItem.fromJson(raw as Map<String, dynamic>))
                .toList(),
      translations: _parseTranslations(json['translations']),
      operatingDaysOfWeek:
          (json['operatingDaysOfWeek'] as List<dynamic>?)
              ?.map((value) => value as int)
              .toList() ??
          const [],
      operatingStartMinute: json['operatingStartMinute'] as int?,
      operatingEndMinute: json['operatingEndMinute'] as int?,
    );
  }
}
