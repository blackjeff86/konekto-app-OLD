import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto_portal/api_config.dart';
import 'package:konekto_portal/models/stay.dart';

/// Gestão de estadias (reservas de quarto) — tela "Quartos" do portal.
/// Cada Stay agrupa um ou mais hóspedes (marido, esposa, filhos), cada um
/// com seu próprio código de acesso.
class StaysRepository {
  final http.Client _client;

  StaysRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Stay>> listStays({
    required String hotelId,
    required String token,
  }) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/stays'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError(
        'Falha ao carregar quartos (status ${response.statusCode}).',
      );
    }
    final raw = jsonDecode(response.body) as List<dynamic>;
    return raw
        .map((item) => Stay.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Stay> getStay({
    required String hotelId,
    required String stayId,
    required String token,
  }) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/stays/$stayId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError(
        'Falha ao carregar o quarto (status ${response.statusCode}).',
      );
    }
    return Stay.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Stay> createStay({
    required String hotelId,
    required String token,
    required NewStayInput input,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/stays'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(input.toJson()),
    );
    if (response.statusCode != 201) {
      throw StateError(
        'Falha ao criar o quarto (status ${response.statusCode}).',
      );
    }
    return Stay.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Estende (ou antecipa) a saída — muda só a data de checkout, sem
  /// mexer no resto da estadia.
  Future<void> extendStay({
    required String hotelId,
    required String stayId,
    required String token,
    required DateTime checkOutDate,
  }) async {
    final response = await _client.patch(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/stays/$stayId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'checkOutDate': checkOutDate.toIso8601String()}),
    );
    if (response.statusCode != 200) {
      throw StateError(
        'Falha ao estender a estadia (status ${response.statusCode}).',
      );
    }
  }

  /// Move a estadia pra outro quarto físico — o backend rejeita se o
  /// quarto de destino já tiver outra estadia ativa (409) ou se essa
  /// estadia já estiver fechada (400).
  Future<void> changeRoom({
    required String hotelId,
    required String stayId,
    required String token,
    required String roomId,
  }) async {
    final response = await _client.patch(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/stays/$stayId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'roomId': roomId}),
    );
    if (response.statusCode == 409) {
      throw StateError('Esse quarto já está ocupado por outra estadia.');
    }
    if (response.statusCode == 400) {
      throw StateError('Não é possível trocar o quarto dessa estadia.');
    }
    if (response.statusCode != 200) {
      throw StateError(
        'Falha ao trocar o quarto (status ${response.statusCode}).',
      );
    }
  }

  /// Fecha a conta do quarto inteiro: marca a estadia como encerrada e
  /// revoga o código de acesso de todos os hóspedes vinculados a ela.
  Future<void> closeStay({
    required String hotelId,
    required String stayId,
    required String token,
  }) async {
    final response = await _client.patch(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/stays/$stayId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'close': true}),
    );
    if (response.statusCode != 200) {
      throw StateError(
        'Falha ao fechar a conta (status ${response.statusCode}).',
      );
    }
  }

  /// Manda uma mensagem de chat pra todos os hóspedes da estadia — o
  /// hóspede pode responder (ver `GET /api/guest/messages`).
  Future<void> sendMessage({
    required String hotelId,
    required String stayId,
    required String token,
    required String message,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/stays/$stayId/messages'),
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

  /// Marca como lidas (pelo staff) as mensagens que os hóspedes dessa
  /// estadia mandaram.
  Future<void> markMessagesRead({
    required String hotelId,
    required String stayId,
    required String token,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/stays/$stayId/messages/read'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError(
        'Falha ao marcar mensagens como lidas (status ${response.statusCode}).',
      );
    }
  }

  /// Total de mensagens de hóspede ainda não lidas pelo staff, somando
  /// todas as estadias do hotel — alimenta o badge de "Quartos".
  Future<int> getUnreadMessagesCount({
    required String hotelId,
    required String token,
  }) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/stays/messages/unread-count'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError(
        'Falha ao carregar contagem de mensagens (status ${response.statusCode}).',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['count'] as int? ?? 0;
  }
}
