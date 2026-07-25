import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto/api_config.dart';
import 'package:konekto/models/stay_bill.dart';

/// Conta consolidada da estadia — busca o saldo em aberto e paga tudo de
/// uma vez com cartão de crédito (não é pagamento por pedido individual).
class StayBillRepository {
  final http.Client _client;

  StayBillRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<StayBill> getBill(String token) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/guest/stay-bill'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar a conta (status ${response.statusCode}).');
    }
    return StayBill.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// `cardToken` já vem tokenizado client-side pelo script do Pagar.me —
  /// nunca manda dado bruto de cartão pra API.
  Future<void> payBill({required String token, required String cardToken}) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/guest/stay-bill/pay'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'cardToken': cardToken}),
    );
    if (response.statusCode == 200) return;

    final body = jsonDecode(response.body) as Map<String, dynamic>? ?? const {};
    throw StateError(switch (body['error']) {
      'nothing_to_pay' => 'Não há saldo em aberto pra pagar.',
      'hotel_not_configured_for_payments' => 'Pagamento online ainda não disponível neste hotel.',
      'payment_failed' => 'Pagamento recusado — confira os dados do cartão e tente de novo.',
      _ => 'Não foi possível processar o pagamento (status ${response.statusCode}).',
    });
  }
}
