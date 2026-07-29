import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sevvn_admin/api_config.dart';

/// Espelha `ModuleDefinition` em apps/sevvn_api/lib/module-catalog.ts —
/// só os campos que a UI do admin de fato usa.
class ModuleDefinition {
  final String id;
  final String name;
  final String description;
  final String category;
  final String operationMode;
  final bool implemented;

  const ModuleDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.operationMode,
    required this.implemented,
  });

  factory ModuleDefinition.fromJson(Map<String, dynamic> json) {
    return ModuleDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      operationMode: json['operationMode'] as String? ?? 'standalone',
      implemented: json['implemented'] as bool? ?? false,
    );
  }
}

class PlanPreset {
  final String id;
  final String name;

  const PlanPreset({required this.id, required this.name});

  factory PlanPreset.fromJson(Map<String, dynamic> json) {
    return PlanPreset(id: json['id'] as String, name: json['name'] as String);
  }
}

class ModulesCatalog {
  final List<ModuleDefinition> modules;
  final List<PlanPreset> planPresets;

  const ModulesCatalog({required this.modules, required this.planPresets});

  factory ModulesCatalog.fromJson(Map<String, dynamic> json) {
    return ModulesCatalog(
      modules: (json['modules'] as List<dynamic>).map((item) => ModuleDefinition.fromJson(item as Map<String, dynamic>)).toList(),
      planPresets: (json['planPresets'] as List<dynamic>).map((item) => PlanPreset.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}

/// `GET /api/modules-catalog` — rota pública, sem token. Mesmo endpoint que
/// o portal e o app do hóspede consultam; nenhum app mantém cópia local da
/// lista de módulos (substitui o antigo `_kFeatureFlags` hardcoded).
class ModulesCatalogRepository {
  final http.Client _client;

  ModulesCatalogRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<ModulesCatalog> getCatalog() async {
    final response = await _client.get(Uri.parse('$apiBaseUrl/api/modules-catalog'));
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar o catálogo de módulos (status ${response.statusCode}).');
    }
    return ModulesCatalog.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}


