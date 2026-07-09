import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto/api_config.dart';

/// Cria um pedido real (hóspede autenticado) referenciando um `ServiceItem`
/// qualquer — sem distinção por tipo, já que o catálogo é genérico desde a
/// Fase 4.
class OrdersRepository {
  final http.Client _client;

  OrdersRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<void> createOrder({
    required String serviceId,
    required String serviceItemId,
    required String token,
    int quantity = 1,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/orders'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'serviceId': serviceId, 'serviceItemId': serviceItemId, 'quantity': quantity}),
    );
    if (response.statusCode != 201) {
      throw StateError('Falha ao enviar o pedido (status ${response.statusCode}).');
    }
  }
}
