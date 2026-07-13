import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto_portal/api_config.dart';
import 'package:konekto_portal/models/guest.dart';

/// Gestão de hóspedes de um hotel — acessível pra `gerente` e `recepcao`
/// (diferente de `HotelConfigRepository`/`ServiceRepository`, que são só
/// gerente).
class GuestsRepository {
  final http.Client _client;

  GuestsRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Guest>> listGuests({required String hotelId, required String token}) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/guests'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar hóspedes (status ${response.statusCode}).');
    }
    final raw = jsonDecode(response.body) as List<dynamic>;
    return raw.map((item) => Guest.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Busca o cadastro mais recente pelo documento — `null` quando é
  /// realmente um hóspede novo (404 da API).
  Future<GuestLookupResult?> lookupByDocument({
    required String hotelId,
    required String token,
    required String documentNumber,
  }) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/guests/lookup?documentNumber=${Uri.encodeQueryComponent(documentNumber)}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode != 200) {
      throw StateError('Falha ao buscar hóspede (status ${response.statusCode}).');
    }
    return GuestLookupResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Guest> getGuest({required String hotelId, required String guestId, required String token}) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/guests/$guestId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar o hóspede (status ${response.statusCode}).');
    }
    return Guest.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Guest> createGuest({
    required String hotelId,
    required String token,
    required NewGuestInput input,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/guests'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(input.toJson()),
    );
    if (response.statusCode != 201) {
      throw StateError('Falha ao criar hóspede (status ${response.statusCode}).');
    }
    return Guest.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Guest> updateGuest({
    required String hotelId,
    required String guestId,
    required String token,
    required GuestEditInput input,
  }) async {
    final response = await _client.patch(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/guests/$guestId'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(input.toJson()),
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao atualizar o cadastro (status ${response.statusCode}).');
    }
    return Guest.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> revokeGuest({required String hotelId, required String guestId, required String token}) async {
    final response = await _client.delete(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/guests/$guestId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao revogar hóspede (status ${response.statusCode}).');
    }
  }
}
