import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto_portal/api_config.dart';
import 'package:konekto_portal/models/customer.dart';

/// Histórico consolidado de clientes do hotel — só leitura, agregado pela
/// API a partir dos `Guest` de cada estadia.
class CustomersRepository {
  final http.Client _client;

  CustomersRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Customer>> listCustomers({required String hotelId, required String token}) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/customers'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar clientes (status ${response.statusCode}).');
    }
    final raw = jsonDecode(response.body) as List<dynamic>;
    return raw.map((item) => Customer.fromJson(item as Map<String, dynamic>)).toList();
  }
}
