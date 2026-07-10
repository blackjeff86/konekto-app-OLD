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

  Future<List<Stay>> listStays({required String hotelId, required String token}) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/stays'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar quartos (status ${response.statusCode}).');
    }
    final raw = jsonDecode(response.body) as List<dynamic>;
    return raw.map((item) => Stay.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Stay> getStay({required String hotelId, required String stayId, required String token}) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/stays/$stayId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar o quarto (status ${response.statusCode}).');
    }
    return Stay.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Stay> createStay({required String hotelId, required String token, required NewStayInput input}) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/stays'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(input.toJson()),
    );
    if (response.statusCode != 201) {
      throw StateError('Falha ao criar o quarto (status ${response.statusCode}).');
    }
    return Stay.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Fecha a conta do quarto inteiro: marca a estadia como encerrada e
  /// revoga o código de acesso de todos os hóspedes vinculados a ela.
  Future<void> closeStay({required String hotelId, required String stayId, required String token}) async {
    final response = await _client.patch(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/stays/$stayId'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'close': true}),
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao fechar a conta (status ${response.statusCode}).');
    }
  }

  Future<void> sendNotice({
    required String hotelId,
    required String stayId,
    required String token,
    required String message,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/stays/$stayId/notices'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'message': message}),
    );
    if (response.statusCode != 201) {
      throw StateError('Falha ao enviar o aviso (status ${response.statusCode}).');
    }
  }
}
