import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto_portal/api_config.dart';

/// Mensagem da conversa de suporte do hotel com a Konekto — diferente do
/// chat hóspede<->recepção (StayMessage), essa é por HOTEL inteiro,
/// staff<->Konekto.
class SupportMessage {
  final String id;
  final String senderType; // 'hotel' ou 'platform'
  final String body;
  final bool readByHotel;
  final DateTime createdAt;

  const SupportMessage({
    required this.id,
    required this.senderType,
    required this.body,
    required this.readByHotel,
    required this.createdAt,
  });

  bool get isFromPlatform => senderType == 'platform';

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'] as String,
      senderType: json['senderType'] as String,
      body: json['body'] as String,
      readByHotel: json['readByHotel'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class SupportRepository {
  final http.Client _client;

  SupportRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<SupportMessage>> listMessages({
    required String hotelId,
    required String token,
  }) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/support-messages'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError(
        'Falha ao carregar as mensagens de suporte (status ${response.statusCode}).',
      );
    }
    final raw = jsonDecode(response.body) as List<dynamic>;
    return raw
        .map((item) => SupportMessage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendMessage({
    required String hotelId,
    required String token,
    required String message,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/support-messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'message': message}),
    );
    if (response.statusCode != 201) {
      throw StateError(
        'Falha ao enviar a mensagem (status ${response.statusCode}).',
      );
    }
  }

  Future<void> markMessagesRead({
    required String hotelId,
    required String token,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/support-messages/read'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError(
        'Falha ao marcar mensagens como lidas (status ${response.statusCode}).',
      );
    }
  }
}
