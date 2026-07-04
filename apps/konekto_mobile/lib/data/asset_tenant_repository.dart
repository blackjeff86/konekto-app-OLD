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

  String _hotelPath(String hotelId, String fileName) => 'assets/tenant_assets/hotels/$hotelId/$fileName';

  @override
  Future<Map<String, dynamic>> getTenantConfig(String hotelId) => _loadJson(_hotelPath(hotelId, 'tenant_config.json'));

  @override
  Future<Map<String, dynamic>> getGuestInfo(String hotelId) => _loadJson(_hotelPath(hotelId, 'guest_info.json'));

  @override
  Future<Map<String, dynamic>> getServicesPageConfig(String hotelId) =>
      _loadJson(_hotelPath(hotelId, 'services_page.json'));

  @override
  Future<Map<String, dynamic>> getRoomServiceMenu(String hotelId) =>
      _loadJson(_hotelPath(hotelId, 'room_service_menu.json'));

  @override
  Future<Map<String, dynamic>> getSpaServices(String hotelId) => _loadJson(_hotelPath(hotelId, 'spa_services.json'));

  @override
  Future<Map<String, dynamic>> getSpaAvailability(String hotelId) =>
      _loadJson(_hotelPath(hotelId, 'spa_availability.json'));

  @override
  Future<Map<String, dynamic>> getRestaurants(String hotelId) => _loadJson(_hotelPath(hotelId, 'restaurants.json'));

  @override
  Future<Map<String, dynamic>> getRestaurantAvailability(String hotelId) =>
      _loadJson(_hotelPath(hotelId, 'restaurant_availability.json'));

  @override
  Future<Map<String, dynamic>> getEventos(String hotelId) => _loadJson(_hotelPath(hotelId, 'eventos_data.json'));

  @override
  Future<Map<String, dynamic>> getEventAvailability(String hotelId) =>
      _loadJson(_hotelPath(hotelId, 'event_availability.json'));

  @override
  Future<Map<String, dynamic>> getPasseios(String hotelId) => _loadJson(_hotelPath(hotelId, 'passeios_data.json'));

  @override
  Future<Map<String, dynamic>> getPasseiosAvailability(String hotelId) =>
      _loadJson(_hotelPath(hotelId, 'passeios_availability.json'));

  @override
  Future<Map<String, dynamic>> getMapaData(String hotelId) => _loadJson(_hotelPath(hotelId, 'mapa_data.json'));
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
