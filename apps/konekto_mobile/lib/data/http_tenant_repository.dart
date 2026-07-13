import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto/api_config.dart';
import 'package:konekto/data/tenant_repository.dart';

/// Implementação HTTP: lê os dados de `apps/konekto_api`, o backend Next.js
/// que substituiu o Firestore. Mesmo contrato de [TenantRepository] — a UI
/// não percebe a diferença.
class HttpTenantRepository implements TenantRepository {
  final http.Client _client;

  HttpTenantRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> _get(String path) async {
    final response = await _client.get(Uri.parse('$apiBaseUrl$path'));
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar "$path" (status ${response.statusCode}).');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _getContent(String hotelId, String docName) =>
      _get('/api/hotels/$hotelId/content/$docName');

  Future<List<dynamic>> _getList(String path) async {
    final response = await _client.get(Uri.parse('$apiBaseUrl$path'));
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar "$path" (status ${response.statusCode}).');
    }
    return json.decode(response.body) as List<dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getTenantConfig(String hotelId) => _get('/api/hotels/$hotelId');

  @override
  Future<Map<String, dynamic>> getServicesPageConfig(String hotelId) => _getContent(hotelId, 'servicesPage');

  @override
  Future<List<dynamic>> getServices(String hotelId) => _getList('/api/hotels/$hotelId/services');

  @override
  Future<Map<String, dynamic>> getService(String hotelId, String serviceId) =>
      _get('/api/hotels/$hotelId/services/$serviceId');
}

class HttpPromotionsRepository implements PromotionsRepository {
  final http.Client _client;

  HttpPromotionsRepository({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<Map<String, dynamic>> getPromotions() async {
    final response = await _client.get(Uri.parse('$apiBaseUrl/api/promotions'));
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar promoções (status ${response.statusCode}).');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }
}
