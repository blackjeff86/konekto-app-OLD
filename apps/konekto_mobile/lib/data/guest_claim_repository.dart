import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:konekto/api_config.dart';
import 'package:konekto/data/tenant_repository_provider.dart';

/// Resolve um código de acesso INDIVIDUAL de hóspede (criado pela recepção
/// no portal) contra `POST /api/guest/claim` — separado de
/// [TenantRepository] porque isso é autenticação de hóspede, não conteúdo
/// de tenant.
///
/// Em modo asset (`useApi == false`, sem backend real) não existe tabela de
/// hóspedes pra resolver contra, então [claim] sempre devolve `null` — o
/// chamador cai de volta no fluxo antigo de código único por hotel, sem
/// nenhuma mudança de comportamento nesse modo.
class GuestClaimRepository {
  static const _tokenKey = 'konekto_guest_token';

  final http.Client _client;

  GuestClaimRepository({http.Client? client}) : _client = client ?? http.Client();

  /// Retorna `{token, guest: {name, roomNumber, hotelId}}` se o código for
  /// de um hóspede ativo, ou `null` se não for (código desconhecido,
  /// revogado, ou app rodando sem API) — nunca lança exceção, pra permitir
  /// o fallback silencioso pro fluxo de código de hotel.
  Future<Map<String, dynamic>?> claim(String code) async {
    if (!useApi) return null;

    try {
      final response = await _client.post(
        Uri.parse('$apiBaseUrl/api/guest/claim'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code}),
      );
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, body['token'] as String);

      return body;
    } on http.ClientException {
      return null;
    }
  }

  /// Token do hóspede salvo por [claim], se algum já foi feito com sucesso
  /// nesta instalação — usado por [OrdersRepository] pra autenticar a
  /// criação de pedidos. `null` se o hóspede entrou pelo fluxo antigo de
  /// código de hotel (sem identidade individual).
  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
}
