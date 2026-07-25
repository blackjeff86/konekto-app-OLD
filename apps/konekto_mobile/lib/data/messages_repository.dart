import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto/api_config.dart';
import 'package:konekto/models/stay_message.dart';

/// Chat entre o hóspede autenticado e a recepção — mensagens da estadia
/// inteira (compartilhada por todo mundo hospedado no mesmo quarto).
class MessagesRepository {
  final http.Client _client;

  MessagesRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<StayMessage>> getMessages({required String token}) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/guest/messages'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar mensagens (status ${response.statusCode}).');
    }
    final raw = jsonDecode(response.body) as List<dynamic>;
    return raw.map((item) => StayMessage.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> sendMessage({required String token, required String message}) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/guest/messages'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'message': message}),
    );
    if (response.statusCode != 201) {
      throw StateError('Falha ao enviar mensagem (status ${response.statusCode}).');
    }
  }

  Future<void> markRead({required String token}) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/guest/messages/read'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao marcar mensagens como lidas (status ${response.statusCode}).');
    }
  }

  Future<int> getUnreadCount({required String token}) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/guest/messages/unread-count'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar contagem de mensagens (status ${response.statusCode}).');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['count'] as int? ?? 0;
  }
}
