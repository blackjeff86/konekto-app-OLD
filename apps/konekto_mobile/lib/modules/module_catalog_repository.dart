import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto/api_config.dart';
import 'package:konekto/modules/module_definition.dart';

/// `GET /api/modules-catalog` — rota pública, sem token. Mesmo endpoint que
/// o portal e o konekto_admin consultam; nenhum app mantém cópia local da
/// lista de módulos. Cacheado em memória por processo (o catálogo muda
/// raramente — TTL "pra sempre dentro da sessão do app" é seguro; matar o
/// app já limpa o cache).
class ModuleCatalogRepository {
  static List<ModuleDefinition>? _cachedModules;

  final http.Client _client;

  ModuleCatalogRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<ModuleDefinition>> getCatalog({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedModules != null) return _cachedModules!;

    final response = await _client.get(Uri.parse('$apiBaseUrl/api/modules-catalog'));
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar catálogo de módulos (status ${response.statusCode}).');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final modules = (body['modules'] as List<dynamic>)
        .map((item) => ModuleDefinition.fromJson(item as Map<String, dynamic>))
        .toList();
    _cachedModules = modules;
    return modules;
  }

  /// Só pra testes — evita que o cache estático vaze entre casos de teste.
  static void resetCacheForTesting() => _cachedModules = null;
}
