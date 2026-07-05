import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:konekto_portal/data/hotel_config_repository.dart';

void main() {
  group('HotelConfigRepository.updateBranding', () {
    test('sends only the fields provided, with the bearer token', () async {
      http.Request? capturedRequest;
      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response(jsonEncode({'ok': true}), 200);
      });

      final repository = HotelConfigRepository(client: mockClient);
      await repository.updateBranding(
        hotelId: 'hotel_1',
        token: 'fake-token',
        name: 'Grand Konekto Palace',
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.method, 'PATCH');
      expect(capturedRequest!.url.toString(), endsWith('/api/hotels/hotel_1'));
      expect(capturedRequest!.headers['Authorization'], 'Bearer fake-token');

      final sentBody = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      expect(sentBody, {
        'hotelInfo': {'name': 'Grand Konekto Palace'},
      });
    });

    test('throws when the API responds with a non-200 status', () async {
      final mockClient = MockClient((request) async => http.Response('', 403));
      final repository = HotelConfigRepository(client: mockClient);

      expect(
        () => repository.updateBranding(hotelId: 'hotel_1', token: 'fake-token', name: 'X'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
