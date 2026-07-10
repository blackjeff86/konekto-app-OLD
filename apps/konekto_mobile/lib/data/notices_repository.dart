import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto/api_config.dart';
import 'package:konekto/models/stay_notice.dart';

/// Avisos da recepção pro quarto do hóspede autenticado — só leitura.
class NoticesRepository {
  final http.Client _client;

  NoticesRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<StayNotice>> getNotices({required String token}) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/guest/notices'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar avisos (status ${response.statusCode}).');
    }
    final raw = jsonDecode(response.body) as List<dynamic>;
    return raw.map((item) => StayNotice.fromJson(item as Map<String, dynamic>)).toList();
  }
}
