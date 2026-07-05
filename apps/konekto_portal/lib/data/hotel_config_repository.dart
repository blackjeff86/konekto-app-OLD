import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto_portal/api_config.dart';

/// Lê e atualiza a configuração/marca do hotel (`hotels.config` na API).
/// Separado de [AuthRepository] — recebe o token de quem chama em vez de
/// conhecer o mecanismo de storage do token.
class HotelConfigRepository {
  final http.Client _client;

  HotelConfigRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> getConfig(String hotelId) async {
    final response = await _client.get(Uri.parse('$apiBaseUrl/api/hotels/$hotelId'));
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar configuração do hotel (status ${response.statusCode}).');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> updateBranding({
    required String hotelId,
    required String token,
    String? name,
    String? logoUrl,
    String? primary,
    String? secondary,
  }) async {
    final body = <String, dynamic>{};
    if (name != null || logoUrl != null) {
      body['hotelInfo'] = {
        if (name != null) 'name': name,
        if (logoUrl != null) 'logoUrl': logoUrl,
      };
    }
    if (primary != null || secondary != null) {
      body['colorPalette'] = {
        if (primary != null) 'primary': primary,
        if (secondary != null) 'secondary': secondary,
      };
    }

    final response = await _client.patch(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao salvar configuração (status ${response.statusCode}).');
    }
  }
}
