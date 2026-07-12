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

  /// Substitui a lista inteira de imagens do carrossel de destaque da home
  /// do hóspede (`hotelInfo.promoImages`) — sempre manda o array completo
  /// já editado, não dá pra adicionar/remover uma imagem isolada.
  Future<void> updatePromoImages({
    required String hotelId,
    required String token,
    required List<String> images,
    double carouselHeight = 250,
  }) async {
    final response = await _client.patch(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({
        'hotelInfo': {
          'promoImages': {'images': images, 'carouselHeight': carouselHeight, 'carouselEnabled': true},
        },
      }),
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao salvar carrossel (status ${response.statusCode}).');
    }
  }

  /// Wi-Fi padrão do hotel (rede + senha) — usado por todo hóspede que não
  /// tiver uma senha individual sobrescrita no próprio cadastro. Vive num
  /// `HotelContent` separado (`guestInfo`), não no `Hotel.config`.
  Future<({String networkName, String password})> getWifiSettings({required String hotelId}) async {
    final response = await _client.get(Uri.parse('$apiBaseUrl/api/hotels/$hotelId/content/guestInfo'));
    if (response.statusCode == 404) {
      return (networkName: '', password: '');
    }
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar configuração de wifi (status ${response.statusCode}).');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final wifi = data['wifi'] as Map<String, dynamic>? ?? {};
    return (networkName: wifi['network_name'] as String? ?? '', password: wifi['password'] as String? ?? '');
  }

  Future<void> updateWifiSettings({
    required String hotelId,
    required String token,
    required String networkName,
    required String password,
  }) async {
    final response = await _client.patch(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/content/guestInfo'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(
        {'data': {'wifi': {'network_name': networkName, 'password': password}}},
      ),
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao salvar configuração de wifi (status ${response.statusCode}).');
    }
  }
}
