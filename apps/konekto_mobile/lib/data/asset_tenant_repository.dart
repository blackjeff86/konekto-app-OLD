import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:konekto/data/tenant_repository.dart';

/// Implementação original: lê os JSONs empacotados como assets locais do
/// app. Mantida como está hoje (extração pura, sem mudança de comportamento)
/// para servir de fallback enquanto a migração pra Firestore é validada.
class AssetTenantRepository implements TenantRepository {
  Future<Map<String, dynamic>> _loadJson(String path) async {
    final String jsonString = await rootBundle.loadString(path);
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  /// `null` se o asset não existir pra esse hotel (nem todo hotel de teste
  /// tem os 5 catálogos — ex: hotel_2 só tem room service).
  Future<Map<String, dynamic>?> _tryLoadJson(String path) async {
    try {
      return await _loadJson(path);
    } catch (_) {
      return null;
    }
  }

  String _hotelPath(String hotelId, String fileName) => 'assets/tenant_assets/hotels/$hotelId/$fileName';

  @override
  Future<Map<String, dynamic>> getTenantConfig(String hotelId) => _loadJson(_hotelPath(hotelId, 'tenant_config.json'));

  @override
  Future<Map<String, dynamic>> getGuestInfo(String hotelId) => _loadJson(_hotelPath(hotelId, 'guest_info.json'));

  @override
  Future<Map<String, dynamic>> getServicesPageConfig(String hotelId) =>
      _loadJson(_hotelPath(hotelId, 'services_page.json'));

  @override
  Future<Map<String, dynamic>> getMapaData(String hotelId) => _loadJson(_hotelPath(hotelId, 'mapa_data.json'));

  // --- Serviços dinâmicos sintetizados a partir dos JSONs dos 5 catálogos
  // antigos (mesma conversão usada em apps/konekto_api/prisma/seed.ts, mas
  // do lado do app pra manter o modo "sem API" funcionando). Não há
  // persistência real aqui — é só uma leitura, sem gerência pelo portal.

  double? _toPrice(dynamic value) => value is num ? value.toDouble() : null;

  Map<String, dynamic>? _buildRoomService(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final pageConfig = raw['pageConfig'] as Map<String, dynamic>?;
    final menu = (raw['menu'] as List<dynamic>?) ?? const [];
    final items = <Map<String, dynamic>>[];
    for (final categoryEntry in menu) {
      final category = categoryEntry as Map<String, dynamic>;
      final categoryItems = (category['items'] as List<dynamic>?) ?? const [];
      for (final item in categoryItems) {
        final itemMap = item as Map<String, dynamic>;
        items.add({
          'id': 'room-service-item-${items.length}',
          'name': itemMap['name'] ?? '',
          'description': itemMap['description'] ?? '',
          'price': _toPrice(itemMap['price']),
          'imageUrl': itemMap['imageUrl'],
          'category': category['category'],
          'extraInfo': itemMap['preparationTime'],
        });
      }
    }
    return {
      'id': 'room-service',
      'name': pageConfig?['title'] ?? 'Serviço de Quarto',
      'icon': 'room_service',
      'description': 'Cardápio de room service.',
      'bannerImageUrl': pageConfig?['headerImage'],
      'enabled': true,
      'items': items,
    };
  }

  Map<String, dynamic>? _buildSpa(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final pageConfig = raw['pageConfig'] as Map<String, dynamic>?;
    final spaServices = (raw['spaServices'] as List<dynamic>?) ?? const [];
    final items = <Map<String, dynamic>>[
      for (var i = 0; i < spaServices.length; i++)
        {
          'id': 'spa-item-$i',
          'name': (spaServices[i] as Map<String, dynamic>)['name'] ?? '',
          'description': (spaServices[i] as Map<String, dynamic>)['description'] ?? '',
          'price': _toPrice((spaServices[i] as Map<String, dynamic>)['price']),
          'imageUrl': (spaServices[i] as Map<String, dynamic>)['imageUrl'],
        },
    ];
    return {
      'id': 'spa',
      'name': pageConfig?['title'] ?? 'SPA',
      'icon': 'spa',
      'description': 'Serviços de spa.',
      'bannerImageUrl': pageConfig?['bannerImageUrl'],
      'enabled': true,
      'items': items,
    };
  }

  List<Map<String, dynamic>> _buildRestaurants(Map<String, dynamic>? raw) {
    if (raw == null) return const [];
    final restaurants = (raw['restaurants'] as List<dynamic>?) ?? const [];
    return [
      for (final entry in restaurants)
        () {
          final restaurant = entry as Map<String, dynamic>;
          final menuItems = (restaurant['menuItems'] as List<dynamic>?) ?? const [];
          return {
            'id': restaurant['slug'] ?? restaurant['name'],
            'name': restaurant['name'] ?? 'Restaurante',
            'icon': 'restaurant',
            'description': restaurant['description'] ?? '',
            'bannerImageUrl': restaurant['imageUrl'],
            'enabled': true,
            'items': [
              for (var i = 0; i < menuItems.length; i++)
                {
                  'id': '${restaurant['slug']}-item-$i',
                  'name': (menuItems[i] as Map<String, dynamic>)['name'] ?? '',
                  'description': (menuItems[i] as Map<String, dynamic>)['description'] ?? '',
                  'price': _toPrice((menuItems[i] as Map<String, dynamic>)['price']),
                  'imageUrl': (menuItems[i] as Map<String, dynamic>)['imageUrl'],
                },
            ],
          };
        }(),
    ];
  }

  Map<String, dynamic>? _buildEventos(String hotelId, Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final pageConfig = raw['pageConfig'] as Map<String, dynamic>?;
    final eventos = (raw['eventos'] as List<dynamic>?) ?? const [];
    final items = <Map<String, dynamic>>[
      for (var i = 0; i < eventos.length; i++)
        () {
          final item = eventos[i] as Map<String, dynamic>;
          final fileName = item['imageFileName'] as String?;
          return {
            'id': 'eventos-item-$i',
            'name': item['title'] ?? '',
            'description': item['description'] ?? '',
            'price': null,
            'imageUrl': fileName == null ? null : 'assets/tenant_assets/hotels/$hotelId/images/eventos/$fileName',
            'location': item['location'],
          };
        }(),
    ];
    return {
      'id': 'eventos',
      'name': pageConfig?['title'] ?? 'Eventos',
      'icon': 'event',
      'description': 'Eventos do hotel.',
      'bannerImageUrl': pageConfig?['bannerImageUrl'],
      'enabled': true,
      'items': items,
    };
  }

  Map<String, dynamic>? _buildPasseios(String hotelId, Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final pageConfig = raw['pageConfig'] as Map<String, dynamic>?;
    final passeios = (raw['passeios'] as List<dynamic>?) ?? const [];
    final items = <Map<String, dynamic>>[
      for (var i = 0; i < passeios.length; i++)
        () {
          final item = passeios[i] as Map<String, dynamic>;
          final fileName = item['imageFileName'] as String?;
          return {
            'id': 'passeios-item-$i',
            'name': item['passeioTitle'] ?? '',
            'description': item['description'] ?? '',
            'price': null,
            'imageUrl': fileName == null ? null : 'assets/tenant_assets/hotels/$hotelId/images/passeios/$fileName',
            'location': item['location'],
          };
        }(),
    ];
    return {
      'id': 'passeios',
      'name': pageConfig?['title'] ?? 'Passeios',
      'icon': 'sports_soccer',
      'description': 'Passeios e atividades locais.',
      'bannerImageUrl': pageConfig?['bannerImageUrl'],
      'enabled': true,
      'items': items,
    };
  }

  Future<List<Map<String, dynamic>>> _buildServices(String hotelId) async {
    final roomService = _buildRoomService(await _tryLoadJson(_hotelPath(hotelId, 'room_service_menu.json')));
    final spa = _buildSpa(await _tryLoadJson(_hotelPath(hotelId, 'spa_services.json')));
    final restaurants = _buildRestaurants(await _tryLoadJson(_hotelPath(hotelId, 'restaurants.json')));
    final eventos = _buildEventos(hotelId, await _tryLoadJson(_hotelPath(hotelId, 'eventos_data.json')));
    final passeios = _buildPasseios(hotelId, await _tryLoadJson(_hotelPath(hotelId, 'passeios_data.json')));

    return [
      if (roomService != null) roomService,
      if (spa != null) spa,
      ...restaurants,
      if (eventos != null) eventos,
      if (passeios != null) passeios,
    ];
  }

  @override
  Future<List<dynamic>> getServices(String hotelId) => _buildServices(hotelId);

  @override
  Future<Map<String, dynamic>> getService(String hotelId, String serviceId) async {
    final services = await _buildServices(hotelId);
    final service = services.firstWhere(
      (service) => service['id'] == serviceId,
      orElse: () => throw StateError('Serviço "$serviceId" não encontrado.'),
    );
    return service;
  }
}

class AssetTenantsDirectoryRepository implements TenantsDirectoryRepository {
  @override
  Future<List<dynamic>> getTenantsList() async {
    final String jsonString = await rootBundle.loadString('assets/data/tenants.json');
    return json.decode(jsonString) as List<dynamic>;
  }
}

class AssetPromotionsRepository implements PromotionsRepository {
  @override
  Future<Map<String, dynamic>> getPromotions() async {
    final String jsonString = await rootBundle.loadString('assets/data/promotions.json');
    return json.decode(jsonString) as Map<String, dynamic>;
  }
}
