import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:konekto/events/analytics_subscriber.dart';
import 'package:konekto/events/event_bus.dart';

class _FakeHttpClient extends http.BaseClient {
  final List<Map<String, dynamic>> capturedBodies = [];
  final List<Map<String, String>> capturedHeaders = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request is http.Request) {
      capturedBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
      capturedHeaders.add(request.headers);
    }
    return http.StreamedResponse(Stream.value(utf8.encode('{}')), 202);
  }
}

void main() {
  group('AnalyticsSubscriber', () {
    test('flush sends buffered events with the hotel id and clears the buffer', () async {
      final client = _FakeHttpClient();
      final subscriber = AnalyticsSubscriber(
        hotelId: 'hotel-123',
        getGuestToken: () async => 'guest-token',
        client: client,
      );
      subscriber.start();

      // AnalyticsSubscriber sempre assina o barramento global (eventBus) —
      // é ele que qualquer módulo publica de verdade.
      eventBus.publish(DomainEvent(type: DomainEventTypes.moduleOpened, moduleId: 'room_service'));
      await Future<void>.delayed(Duration.zero);

      await subscriber.flush();

      expect(client.capturedBodies, hasLength(1));
      final events = client.capturedBodies.single['events'] as List<dynamic>;
      expect(events, hasLength(1));
      expect((events.single as Map<String, dynamic>)['hotelId'], 'hotel-123');
      expect(client.capturedHeaders.single['Authorization'], 'Bearer guest-token');

      // Segundo flush sem eventos novos não manda requisição nenhuma.
      await subscriber.flush();
      expect(client.capturedBodies, hasLength(1));

      subscriber.dispose();
    });

    test('flush omits Authorization header when there is no guest token yet', () async {
      final client = _FakeHttpClient();
      final subscriber = AnalyticsSubscriber(
        hotelId: 'hotel-123',
        getGuestToken: () async => null,
        client: client,
      );
      subscriber.start();

      eventBus.publish(DomainEvent(type: DomainEventTypes.moduleOpened, moduleId: 'home'));
      await Future<void>.delayed(Duration.zero);
      await subscriber.flush();

      expect(client.capturedHeaders.single.containsKey('Authorization'), isFalse);

      subscriber.dispose();
    });

    test('flush with an empty buffer never calls the http client', () async {
      final client = _FakeHttpClient();
      final subscriber = AnalyticsSubscriber(hotelId: 'hotel-123', getGuestToken: () async => null, client: client);

      await subscriber.flush();

      expect(client.capturedBodies, isEmpty);
      subscriber.dispose();
    });
  });
}
