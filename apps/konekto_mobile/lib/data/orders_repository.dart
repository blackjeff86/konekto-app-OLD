import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto/api_config.dart';
import 'package:konekto/models/guest_order.dart';

/// Cria, lista, edita e cancela pedidos do hóspede autenticado — sem
/// distinção por tipo de serviço, já que o catálogo é genérico desde a
/// Fase 4. Edição/cancelamento só valem enquanto o pedido ainda está
/// `pending` (a API rejeita com 409 assim que a cozinha começa o preparo).
class OrdersRepository {
  final http.Client _client;

  OrdersRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<void> createOrder({
    required String serviceId,
    required String serviceItemId,
    required String token,
    int quantity = 1,
    String? note,
    DateTime? scheduledFor,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/orders'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({
        'serviceId': serviceId,
        'serviceItemId': serviceItemId,
        'quantity': quantity,
        if (note != null) 'note': note,
        if (scheduledFor != null) 'scheduledFor': scheduledFor.toIso8601String(),
      }),
    );
    if (response.statusCode != 201) {
      throw StateError('Falha ao enviar o pedido (status ${response.statusCode}).');
    }
  }

  /// Reserva a MESA de um restaurante (não um prato do cardápio) — sem
  /// `serviceItemId`, a API resolve/cria o item oculto "Reserva de mesa"
  /// por trás. Só vale pra `Service` do tipo `restaurant`.
  Future<void> createTableReservation({
    required String serviceId,
    required String token,
    required DateTime scheduledFor,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/orders'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'serviceId': serviceId, 'scheduledFor': scheduledFor.toIso8601String()}),
    );
    if (response.statusCode != 201) {
      throw StateError('Falha ao reservar a mesa (status ${response.statusCode}).');
    }
  }

  Future<List<GuestOrder>> getMyOrders({required String token}) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/orders'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar os pedidos (status ${response.statusCode}).');
    }
    final body = jsonDecode(response.body) as List<dynamic>;
    return body.map((raw) => GuestOrder.fromJson(raw as Map<String, dynamic>)).toList();
  }

  Future<void> updateOrder({
    required String orderId,
    required String token,
    int? quantity,
    String? note,
    DateTime? scheduledFor,
  }) async {
    final response = await _client.patch(
      Uri.parse('$apiBaseUrl/api/orders/$orderId'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({
        if (quantity != null) 'quantity': quantity,
        if (note != null) 'note': note,
        if (scheduledFor != null) 'scheduledFor': scheduledFor.toIso8601String(),
      }),
    );
    if (response.statusCode == 409) {
      throw StateError('Esse pedido já está em preparo e não pode mais ser alterado.');
    }
    if (response.statusCode != 200) {
      throw StateError('Falha ao atualizar o pedido (status ${response.statusCode}).');
    }
  }

  Future<void> cancelOrder({required String orderId, required String token}) async {
    final response = await _client.patch(
      Uri.parse('$apiBaseUrl/api/orders/$orderId'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'cancel': true}),
    );
    if (response.statusCode == 409) {
      throw StateError('Esse pedido já está em preparo e não pode mais ser cancelado.');
    }
    if (response.statusCode != 200) {
      throw StateError('Falha ao cancelar o pedido (status ${response.statusCode}).');
    }
  }
}
