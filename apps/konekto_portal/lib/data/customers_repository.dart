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

  /// Manda um e-mail promocional com um cupom existente pro e-mail
  /// cadastrado desse cliente (gerente only).
  Future<void> sendPromo({
    required String hotelId,
    required String documentNumber,
    required String token,
    required String couponId,
    String? message,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/customers/$documentNumber/send-promo'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'couponId': couponId, if (message != null && message.isNotEmpty) 'message': message}),
    );
    if (response.statusCode == 200) return;

    String errorCode = 'unknown';
    try {
      errorCode = (jsonDecode(response.body) as Map<String, dynamic>)['error'] as String? ?? 'unknown';
    } on FormatException {
      // corpo não é JSON — segue com a mensagem genérica abaixo.
    }
    throw StateError(switch (errorCode) {
      'customer_no_email' => 'Esse cliente não tem e-mail cadastrado.',
      'customer_not_found' => 'Cliente não encontrado.',
      'coupon_not_found' => 'Cupom não encontrado.',
      _ => 'Falha ao enviar e-mail (status ${response.statusCode}).',
    });
  }
}
