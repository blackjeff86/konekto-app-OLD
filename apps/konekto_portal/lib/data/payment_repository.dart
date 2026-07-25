import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto_portal/api_config.dart';

/// Status da conta de recebedor do hotel no Pagar.me, espelhado do
/// backend — `pending` até o hotel colar um Recipient ID válido e o
/// Pagar.me confirmar como ativo.
enum PaymentAccountStatus {
  notConfigured,
  pending,
  verified,
  rejected;

  static PaymentAccountStatus fromJson(Map<String, dynamic> json) {
    if (json['configured'] != true) return PaymentAccountStatus.notConfigured;
    return switch (json['status'] as String?) {
      'verified' => PaymentAccountStatus.verified,
      'rejected' => PaymentAccountStatus.rejected,
      _ => PaymentAccountStatus.pending,
    };
  }
}

class PaymentAccount {
  final PaymentAccountStatus status;
  final String? recipientId;
  final String? pagarmeStatus;

  const PaymentAccount({
    required this.status,
    this.recipientId,
    this.pagarmeStatus,
  });

  factory PaymentAccount.fromJson(Map<String, dynamic> json) {
    return PaymentAccount(
      status: PaymentAccountStatus.fromJson(json),
      recipientId: json['recipientId'] as String?,
      pagarmeStatus: json['pagarmeStatus'] as String?,
    );
  }
}

/// Cadastro de pagamento online (marketplace/split via Pagar.me) do hotel
/// — o hotel cria a conta de recebedor direto no onboarding do Pagar.me
/// (KYC completo é responsabilidade deles) e só cola o Recipient ID aqui;
/// nós validamos que existe de verdade antes de gravar.
class PaymentRepository {
  final http.Client _client;

  PaymentRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<PaymentAccount> getAccount({
    required String hotelId,
    required String token,
  }) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/payment-recipient'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError(
        'Falha ao carregar dados de pagamento (status ${response.statusCode}).',
      );
    }
    return PaymentAccount.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<PaymentAccount> setRecipientId({
    required String hotelId,
    required String token,
    required String recipientId,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/payment-recipient'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'recipientId': recipientId}),
    );
    if (response.statusCode == 400) {
      throw StateError(
        'Não encontramos esse Recipient ID no Pagar.me — confira se foi colado corretamente.',
      );
    }
    if (response.statusCode != 200) {
      throw StateError(
        'Falha ao salvar dados de pagamento (status ${response.statusCode}).',
      );
    }
    return PaymentAccount.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
