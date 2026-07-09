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
}
