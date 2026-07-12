import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto_portal/api_config.dart';
import 'package:konekto_portal/models/dashboard_stats.dart';

/// Busca as estatísticas agregadas do hotel pra tela "Visão Geral".
class DashboardRepository {
  final http.Client _client;

  DashboardRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<DashboardStats> getStats({required String hotelId, required String token}) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/dashboard/stats'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar estatísticas (status ${response.statusCode}).');
    }
    return DashboardStats.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
