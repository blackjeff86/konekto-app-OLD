import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto_portal/api_config.dart';

/// Status da integração do hotel com o PMS/sistema externo — espelhado do
/// backend (`HotelIntegration`). Nunca traz a chave nem o segredo do
/// webhook, só o que é seguro exibir no portal.
class IntegrationStatus {
  final bool configured;
  final String? apiKeyPrefix;
  final String? webhookUrl;
  final bool enabled;
  final DateTime? lastInboundSyncAt;
  final DateTime? lastOutboundAt;
  final bool? lastOutboundOk;

  const IntegrationStatus({
    required this.configured,
    this.apiKeyPrefix,
    this.webhookUrl,
    this.enabled = true,
    this.lastInboundSyncAt,
    this.lastOutboundAt,
    this.lastOutboundOk,
  });

  factory IntegrationStatus.fromJson(Map<String, dynamic> json) {
    return IntegrationStatus(
      configured: json['configured'] == true,
      apiKeyPrefix: json['apiKeyPrefix'] as String?,
      webhookUrl: json['webhookUrl'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      lastInboundSyncAt: json['lastInboundSyncAt'] != null
          ? DateTime.tryParse(json['lastInboundSyncAt'] as String)
          : null,
      lastOutboundAt: json['lastOutboundAt'] != null
          ? DateTime.tryParse(json['lastOutboundAt'] as String)
          : null,
      lastOutboundOk: json['lastOutboundOk'] as bool?,
    );
  }
}

/// Integração do hotel com o PMS/sistema de hotelaria já usado por ele —
/// o hotel (ou o middleware/TI que administra o PMS) usa a chave de API
/// gerada aqui pra empurrar reservas/hóspedes/cardápio pro Konekto, e o
/// webhook configurado aqui recebe de volta os pedidos feitos pelo hóspede
/// no app.
class IntegrationRepository {
  final http.Client _client;

  IntegrationRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<IntegrationStatus> getStatus({
    required String hotelId,
    required String token,
  }) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/integration'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError(
        'Falha ao carregar a integração (status ${response.statusCode}).',
      );
    }
    return IntegrationStatus.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Devolve a chave em texto puro — só existe nessa resposta, o backend
  /// nunca mais consegue mostrá-la de novo (só o hash fica salvo).
  Future<String> rotateApiKey({
    required String hotelId,
    required String token,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/integration'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'action': 'rotate_key'}),
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao gerar a chave (status ${response.statusCode}).');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['apiKey'] as String;
  }

  Future<void> setWebhookUrl({
    required String hotelId,
    required String token,
    required String? webhookUrl,
  }) async {
    final response = await _client.patch(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/integration'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'webhookUrl': webhookUrl}),
    );
    if (response.statusCode == 404) {
      throw StateError(
        'Gere uma chave de integração antes de configurar o webhook.',
      );
    }
    if (response.statusCode == 400) {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      if (body?['error'] == 'unsafe_webhook_url') {
        throw StateError(
          'Essa URL não pode ser usada como webhook — aponta pra um endereço interno/privado.',
        );
      }
      throw StateError('Essa URL de webhook não parece válida.');
    }
    if (response.statusCode != 200) {
      throw StateError(
        'Falha ao salvar a URL do webhook (status ${response.statusCode}).',
      );
    }
  }
}
