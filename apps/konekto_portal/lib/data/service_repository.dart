import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto_portal/api_config.dart';
import 'package:konekto_portal/models/service.dart';

/// Lê e gerencia os serviços dinâmicos de um hotel (`Service`/`ServiceItem`
/// na API) — substitui o `CatalogRepository` específico de Room Service da
/// Fase 3 por um repositório genérico que serve qualquer serviço que o
/// hotel crie.
class ServiceRepository {
  final http.Client _client;

  ServiceRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Service>> listServices(String hotelId) async {
    final response = await _client.get(Uri.parse('$apiBaseUrl/api/hotels/$hotelId/services'));
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar serviços (status ${response.statusCode}).');
    }
    final raw = jsonDecode(response.body) as List<dynamic>;
    return raw.map((item) => Service.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Service> getService(String hotelId, String serviceId) async {
    final response = await _client.get(Uri.parse('$apiBaseUrl/api/hotels/$hotelId/services/$serviceId'));
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar serviço (status ${response.statusCode}).');
    }
    return Service.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Service> createService({
    required String hotelId,
    required String token,
    required String name,
    required String slug,
    required String icon,
    required String description,
    required ServiceType type,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/services'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'name': name, 'slug': slug, 'icon': icon, 'description': description, 'type': type.apiValue}),
    );
    if (response.statusCode != 201) {
      throw StateError('Falha ao criar serviço (status ${response.statusCode}).');
    }
    return Service.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> updateService({
    required String hotelId,
    required String serviceId,
    required String token,
    String? name,
    String? icon,
    String? description,
    bool? enabled,
  }) async {
    final response = await _client.patch(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/services/$serviceId'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({
        if (name != null) 'name': name,
        if (icon != null) 'icon': icon,
        if (description != null) 'description': description,
        if (enabled != null) 'enabled': enabled,
      }),
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao atualizar serviço (status ${response.statusCode}).');
    }
  }

  Future<void> deleteService({required String hotelId, required String serviceId, required String token}) async {
    final response = await _client.delete(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/services/$serviceId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao remover serviço (status ${response.statusCode}).');
    }
  }

  Future<ServiceItem> createItem({
    required String hotelId,
    required String serviceId,
    required String token,
    required ServiceItem item,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/services/$serviceId/items'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(item.toJson()),
    );
    if (response.statusCode != 201) {
      throw StateError('Falha ao criar item (status ${response.statusCode}).');
    }
    return ServiceItem.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<ServiceItem> updateItem({
    required String hotelId,
    required String serviceId,
    required String itemId,
    required String token,
    required ServiceItem item,
  }) async {
    final response = await _client.patch(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/services/$serviceId/items/$itemId'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(item.toJson()),
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao atualizar item (status ${response.statusCode}).');
    }
    return ServiceItem.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteItem({
    required String hotelId,
    required String serviceId,
    required String itemId,
    required String token,
  }) async {
    final response = await _client.delete(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/services/$serviceId/items/$itemId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao remover item (status ${response.statusCode}).');
    }
  }
}
