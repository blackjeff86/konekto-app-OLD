import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto_portal/api_config.dart';
import 'package:konekto_portal/models/order.dart';

class OrdersRepository {
  final http.Client _client;

  OrdersRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Order>> listOrders({required String hotelId, required String token}) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/orders'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar pedidos (status ${response.statusCode}).');
    }
    final raw = jsonDecode(response.body) as List<dynamic>;
    return raw.map((item) => Order.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> updateStatus({
    required String hotelId,
    required String orderId,
    required String token,
    required OrderStatus status,
  }) async {
    final response = await _client.patch(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/orders/$orderId'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'status': status.apiValue}),
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao atualizar status (status ${response.statusCode}).');
    }
  }

  /// Recepção lança um consumo de frigobar em nome de um hóspede da
  /// estadia (ex: item notado faltando na conferência do quarto) — só
  /// funciona pra itens marcados como frigobar no catálogo.
  Future<void> recordConsumption({
    required String hotelId,
    required String stayId,
    required String token,
    required String guestId,
    required String serviceItemId,
    required int quantity,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/stays/$stayId/consumption'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'guestId': guestId, 'serviceItemId': serviceItemId, 'quantity': quantity}),
    );
    if (response.statusCode != 201) {
      throw StateError('Falha ao lançar consumo (status ${response.statusCode}).');
    }
  }
}
