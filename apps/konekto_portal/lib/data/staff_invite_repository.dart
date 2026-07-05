import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto_portal/api_config.dart';

/// Convites de staff — gerente gera um código, uma nova conta se cadastra
/// com esse código e vira `recepcao` automaticamente do mesmo hotel.
class StaffInviteRepository {
  final http.Client _client;

  StaffInviteRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<String> createInvite(String token) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/staff-invites'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 201) {
      throw StateError('Falha ao gerar convite (status ${response.statusCode}).');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['code'] as String;
  }

  /// Retorna o token de sessão + dados do staff recém-criado (o backend já
  /// loga automaticamente, mesmo formato de `/api/auth/login`).
  Future<Map<String, dynamic>> acceptInvite({
    required String code,
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/staff-invites/$code/consume'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw StateError(_errorMessage(body['error'] as String?));
    }
    return body;
  }

  String _errorMessage(String? errorCode) {
    return switch (errorCode) {
      'invite_already_used' => 'Este convite já foi usado.',
      'invite_not_found' => 'Convite não encontrado — verifique o link.',
      'email_already_registered' => 'Já existe uma conta com esse e-mail.',
      'invalid_request' => 'Preencha nome, e-mail e uma senha com pelo menos 8 caracteres.',
      _ => 'Não foi possível concluir o cadastro.',
    };
  }
}
