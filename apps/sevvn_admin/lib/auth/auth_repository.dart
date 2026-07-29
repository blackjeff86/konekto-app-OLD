import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sevvn_admin/api_config.dart';
import 'package:sevvn_admin/auth/auth_exceptions.dart';
import 'package:sevvn_admin/auth/admin_session.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

@immutable
class AuthState {
  final AuthStatus status;
  final AdminSession? session;
  final String? errorCode;

  const AuthState._(this.status, this.session, [this.errorCode]);

  const AuthState.unknown() : this._(AuthStatus.unknown, null);
  const AuthState.unauthenticated({String? errorCode}) : this._(AuthStatus.unauthenticated, null, errorCode);
  const AuthState.authenticated(AdminSession session) : this._(AuthStatus.authenticated, session);
}

/// Fonte única do fluxo de autenticação do admin da plataforma — diferente
/// do portal do hotel, aqui o login é um formulário Dart de verdade dentro
/// do próprio app (não existe uma tela de login compartilhável pra esse
/// público; o login oficial compartilhado é o do staff de hotel no site
/// institucional).
///
/// `restoreSession` roda uma vez na inicialização do app (ver [AdminGate])
/// e sempre revalida o token contra a API antes de confiar nele.
class AuthRepository {
  static const _tokenKey = 'sevvn_admin_auth_token';
  static const _legacyTokenKey = 'konekto_admin_auth_token';

  final http.Client _httpClient;
  final ValueNotifier<AuthState> authState = ValueNotifier(const AuthState.unknown());

  AuthRepository({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey) ?? prefs.getString(_legacyTokenKey);
    if (token == null) {
      authState.value = const AuthState.unauthenticated();
      return;
    }
    try {
      final session = await _fetchMe(token);
      if (prefs.getString(_tokenKey) == null) {
        await prefs.setString(_tokenKey, token);
        await prefs.remove(_legacyTokenKey);
      }
      authState.value = AuthState.authenticated(session);
    } on AdminProfileNotFoundException {
      await prefs.remove(_tokenKey);
      await prefs.remove(_legacyTokenKey);
      authState.value = const AuthState.unauthenticated(errorCode: 'admin_not_found');
    }
  }

  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) ?? prefs.getString(_legacyTokenKey);
  }

  Future<void> login({required String email, required String password}) async {
    final response = await _httpClient.post(
      Uri.parse('$apiBaseUrl/api/platform-admin/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 401) {
      throw const InvalidCredentialsException();
    }
    if (response.statusCode != 200) {
      throw StateError('Falha ao entrar (status ${response.statusCode}).');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final token = body['token'] as String;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.remove(_legacyTokenKey);
    authState.value = AuthState.authenticated(AdminSession.fromJson(body['admin'] as Map<String, dynamic>));
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_legacyTokenKey);
    authState.value = const AuthState.unauthenticated();
  }

  Future<AdminSession> _fetchMe(String token) async {
    final response = await _httpClient.get(
      Uri.parse('$apiBaseUrl/api/platform-admin/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw const AdminProfileNotFoundException();
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return AdminSession.fromJson(body['admin'] as Map<String, dynamic>);
  }
}

