import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto/api_config.dart';
import 'package:konekto/events/event_bus.dart';

/// Analytics Engine — assinante do Event Bus, não uma camada da cadeia
/// Module Engine → Home Layout → Navigation → Theme → Presentation. Só
/// grava (`POST /api/analytics/events`), sem dashboard nesta entrega. Envia
/// em lote (buffer + flush periódico) em vez de uma requisição por evento —
/// não é billing-crítico, então perder um lote se o app fechar antes do
/// flush é uma limitação conhecida e aceita (ver plano de migração), não um
/// bug a corrigir aqui.
class AnalyticsSubscriber {
  final String hotelId;
  final Future<String?> Function() getGuestToken;
  final http.Client _client;
  final Duration flushInterval;

  final List<DomainEvent> _buffer = [];
  StreamSubscription<DomainEvent>? _subscription;
  Timer? _flushTimer;

  AnalyticsSubscriber({
    required this.hotelId,
    required this.getGuestToken,
    http.Client? client,
    this.flushInterval = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  void start() {
    _subscription ??= eventBus.onAll().listen(_buffer.add);
    _flushTimer ??= Timer.periodic(flushInterval, (_) => flush());
  }

  Future<void> flush() async {
    if (_buffer.isEmpty) return;
    final events = List<DomainEvent>.of(_buffer);
    _buffer.clear();

    final token = await getGuestToken();
    try {
      await _client.post(
        Uri.parse('$apiBaseUrl/api/analytics/events'),
        headers: {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'events': events
              .map((event) => {'hotelId': hotelId, 'type': event.type, 'payload': event.payload})
              .toList(),
        }),
      );
    } on Exception {
      // Falha de rede não deve propagar — analytics nunca trava o app.
    }
  }

  void dispose() {
    _flushTimer?.cancel();
    _subscription?.cancel();
  }
}
