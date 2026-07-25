import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:konekto/modules/module_catalog_repository.dart';

class _FakeHttpClient extends http.BaseClient {
  int requestCount = 0;
  final String responseBody;
  final int statusCode;

  _FakeHttpClient({this.responseBody = '{"modules":[]}', this.statusCode = 200});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestCount++;
    return http.StreamedResponse(Stream.value(utf8.encode(responseBody)), statusCode);
  }
}

void main() {
  setUp(() => ModuleCatalogRepository.resetCacheForTesting());

  test('fetches and parses the catalog from GET /api/modules-catalog', () async {
    final client = _FakeHttpClient(
      responseBody: jsonEncode({
        'modules': [
          {
            'id': 'room_service',
            'name': 'Room Service',
            'description': 'Pedidos de quarto.',
            'category': 'hospitalidade',
            'icon': 'room_service',
            'placement': ['servicesMenu'],
            'defaultOrder': 0,
            'dependencies': ['services'],
            'implemented': true,
          },
        ],
      }),
    );
    final repository = ModuleCatalogRepository(client: client);

    final catalog = await repository.getCatalog();

    expect(catalog, hasLength(1));
    expect(catalog.single.id, 'room_service');
    expect(catalog.single.implemented, isTrue);
  });

  test('caches the catalog across calls — only one HTTP request', () async {
    final client = _FakeHttpClient();
    final repository = ModuleCatalogRepository(client: client);

    await repository.getCatalog();
    await repository.getCatalog();
    await ModuleCatalogRepository(client: client).getCatalog();

    expect(client.requestCount, 1);
  });

  test('forceRefresh bypasses the cache', () async {
    final client = _FakeHttpClient();
    final repository = ModuleCatalogRepository(client: client);

    await repository.getCatalog();
    await repository.getCatalog(forceRefresh: true);

    expect(client.requestCount, 2);
  });

  test('throws a StateError when the response is not 200', () async {
    final client = _FakeHttpClient(statusCode: 500, responseBody: '');
    final repository = ModuleCatalogRepository(client: client);

    expect(() => repository.getCatalog(), throwsA(isA<StateError>()));
  });

  test('getServiceGroups parses serviceGroups from the same cached response', () async {
    final client = _FakeHttpClient(
      responseBody: jsonEncode({
        'modules': [],
        'serviceGroups': [
          {'id': 'gastronomia', 'name': 'Gastronomia', 'defaultOrder': 0},
          {'id': 'bem_estar', 'name': 'Bem-estar', 'defaultOrder': 1},
        ],
      }),
    );
    final repository = ModuleCatalogRepository(client: client);

    final groups = await repository.getServiceGroups();

    expect(groups, hasLength(2));
    expect(groups.first.id, 'gastronomia');
    expect(client.requestCount, 1);
  });

  test('getServiceGroups returns an empty list when the response omits serviceGroups', () async {
    final client = _FakeHttpClient(responseBody: '{"modules":[]}');
    final repository = ModuleCatalogRepository(client: client);

    expect(await repository.getServiceGroups(), isEmpty);
  });

  test('getCatalog and getServiceGroups share the same cache — only one HTTP request total', () async {
    final client = _FakeHttpClient();
    final repository = ModuleCatalogRepository(client: client);

    await repository.getCatalog();
    await repository.getServiceGroups();

    expect(client.requestCount, 1);
  });
}
