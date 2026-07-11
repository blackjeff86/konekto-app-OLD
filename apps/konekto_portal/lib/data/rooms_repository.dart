import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto_portal/api_config.dart';
import 'package:konekto_portal/models/room.dart';

/// Cadastro de quartos físicos do hotel — usado tanto pela seção "Quartos"
/// de Configurações (CRUD) quanto pelo mapa de quartos na aba principal
/// (só leitura + ocupação).
class RoomsRepository {
  final http.Client _client;

  RoomsRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Room>> listRooms({required String hotelId, required String token}) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/rooms'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar quartos (status ${response.statusCode}).');
    }
    final raw = jsonDecode(response.body) as List<dynamic>;
    return raw.map((item) => Room.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Room> createRoom({required String hotelId, required String token, required RoomInput input}) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/rooms'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(input.toJson()),
    );
    if (response.statusCode == 409) {
      throw StateError('Já existe um quarto com esse número.');
    }
    if (response.statusCode != 201) {
      throw StateError('Falha ao criar quarto (status ${response.statusCode}).');
    }
    return Room.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> updateRoom({
    required String hotelId,
    required String roomId,
    required String token,
    required RoomInput input,
  }) async {
    final response = await _client.patch(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/rooms/$roomId'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(input.toJson()),
    );
    if (response.statusCode == 409) {
      throw StateError('Já existe um quarto com esse número.');
    }
    if (response.statusCode != 200) {
      throw StateError('Falha ao atualizar quarto (status ${response.statusCode}).');
    }
  }

  Future<void> deleteRoom({required String hotelId, required String roomId, required String token}) async {
    final response = await _client.delete(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/rooms/$roomId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 409) {
      throw StateError('Esse quarto já teve estadias — não pode ser removido.');
    }
    if (response.statusCode != 200) {
      throw StateError('Falha ao remover quarto (status ${response.statusCode}).');
    }
  }
}
