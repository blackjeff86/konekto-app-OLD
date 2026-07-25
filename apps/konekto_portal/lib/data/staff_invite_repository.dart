import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto_portal/api_config.dart';

class StaffMember {
  final String id;
  final String name;
  final String email;
  final String role;

  const StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
    );
  }
}

/// Convites de staff — gerente gera um código, uma nova conta se cadastra
/// com esse código e vira `recepcao` automaticamente do mesmo hotel.
class StaffInviteRepository {
  final http.Client _client;

  StaffInviteRepository({http.Client? client})
    : _client = client ?? http.Client();

  Future<List<StaffMember>> listStaff({
    required String hotelId,
    required String token,
  }) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/staff'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError(
        'Falha ao carregar a equipe (status ${response.statusCode}).',
      );
    }
    final raw = jsonDecode(response.body) as List<dynamic>;
    return raw
        .map((item) => StaffMember.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> revokeStaff({
    required String hotelId,
    required String staffId,
    required String token,
  }) async {
    final response = await _client.delete(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/staff/$staffId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 400) {
      throw StateError('Não é possível remover o único gerente do hotel.');
    }
    if (response.statusCode != 200) {
      throw StateError(
        'Falha ao revogar acesso (status ${response.statusCode}).',
      );
    }
  }

  Future<String> createInvite(String token) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/staff-invites'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 201) {
      throw StateError(
        'Falha ao gerar convite (status ${response.statusCode}).',
      );
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
      'invalid_request' =>
        'Preencha nome, e-mail e uma senha com pelo menos 8 caracteres.',
      _ => 'Não foi possível concluir o cadastro.',
    };
  }
}
