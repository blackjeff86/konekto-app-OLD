import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto_portal/api_config.dart';
import 'package:konekto_portal/models/partner.dart';

class PartnersRepository {
  final http.Client _client;

  PartnersRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Partner>> listPartners({required String hotelId, required String token}) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/partners'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar parceiros (status ${response.statusCode}).');
    }
    final raw = jsonDecode(response.body) as List<dynamic>;
    return raw.map((item) => Partner.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Partner> createPartner({required String hotelId, required String token, required PartnerInput input}) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/partners'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(input.toJson()),
    );
    if (response.statusCode != 201) {
      throw StateError('Falha ao criar parceiro (status ${response.statusCode}).');
    }
    return Partner.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> updatePartner({
    required String hotelId,
    required String partnerId,
    required String token,
    required PartnerInput input,
  }) async {
    final response = await _client.patch(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/partners/$partnerId'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(input.toJson()),
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao atualizar parceiro (status ${response.statusCode}).');
    }
  }

  Future<void> deletePartner({required String hotelId, required String partnerId, required String token}) async {
    final response = await _client.delete(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/partners/$partnerId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 409) {
      throw StateError('Esse parceiro está vinculado a itens do catálogo — desvincule antes de remover.');
    }
    if (response.statusCode != 200) {
      throw StateError('Falha ao remover parceiro (status ${response.statusCode}).');
    }
  }
}
