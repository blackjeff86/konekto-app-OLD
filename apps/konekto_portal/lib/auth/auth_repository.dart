import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;
import 'package:konekto_portal/api_config.dart';
import 'package:konekto_portal/auth/auth_exceptions.dart';
import 'package:konekto_portal/auth/staff_session.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

@immutable
class AuthState {
  final AuthStatus status;
  final StaffSession? session;
  final String? errorCode;

  const AuthState._(this.status, this.session, [this.errorCode]);

  const AuthState.unknown() : this._(AuthStatus.unknown, null);
  const AuthState.unauthenticated({String? errorCode}) : this._(AuthStatus.unauthenticated, null, errorCode);
  const AuthState.authenticated(StaffSession session) : this._(AuthStatus.authenticated, session);
}

/// Fonte única do fluxo de autenticação de staff. O login em si acontece em
/// apps/konekto_site/login.html (única tela de login real do produto) — o
/// portal só consome o token que a página de login manda via `?token=` na
/// URL, ou rehidrata um token já persistido em localStorage de uma sessão
/// anterior.
///
/// `restoreSession` roda uma vez na inicialização do app (ver [StaffGate])
/// e sempre revalida o token contra a API antes de confiar nele — uma conta
/// removida do lado do servidor é barrada mesmo com token localmente ainda
/// presente.
class AuthRepository {
  static const _tokenKey = 'konekto_portal_auth_token';

  final http.Client _httpClient;
  final ValueNotifier<AuthState> authState = ValueNotifier(const AuthState.unknown());

  AuthRepository({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  /// Se a URL atual tiver `?token=...` (redirecionamento vindo do login.html
  /// do site), persiste esse token e limpa a URL — evita deixar o token
  /// visível na barra de endereço ou no histórico do navegador.
  Future<void> _consumeTokenFromUrl() async {
    final uri = Uri.base;
    final token = uri.queryParameters['token'];
    if (token == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);

    final cleanUri = uri.replace(queryParameters: {});
    web.window.history.replaceState(null, '', cleanUri.toString());
  }

  Future<void> restoreSession() async {
    await _consumeTokenFromUrl();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) {
      authState.value = const AuthState.unauthenticated();
      return;
    }
    try {
      final session = await _fetchMe(token);
      authState.value = AuthState.authenticated(session);
    } on StaffProfileNotFoundException {
      await prefs.remove(_tokenKey);
      authState.value = const AuthState.unauthenticated(errorCode: 'staff_not_found');
    }
  }

  /// Token salvo, pra outros repositórios (ex: HotelConfigRepository) usarem
  /// no header `Authorization` de chamadas autenticadas — mantém esses
  /// repositórios sem precisar conhecer o mecanismo de storage do token.
  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Loga direto com um token já emitido pelo backend (ex: resposta de
  /// `POST /api/staff-invites/:code/consume`, que já cria a conta e
  /// devolve um token — não precisa passar pelo `login.html` de novo).
  Future<void> signInWithToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    final session = await _fetchMe(token);
    authState.value = AuthState.authenticated(session);
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    authState.value = const AuthState.unauthenticated();
  }

  Future<StaffSession> _fetchMe(String token) async {
    final response = await _httpClient.get(
      Uri.parse('$apiBaseUrl/api/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw const StaffProfileNotFoundException();
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return StaffSession.fromJson(body['staff'] as Map<String, dynamic>);
  }
}
