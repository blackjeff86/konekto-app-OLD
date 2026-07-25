import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto/api_config.dart';
import 'package:konekto/models/guest_order.dart';

/// Cria, lista, edita e cancela pedidos do hóspede autenticado — sem
/// distinção por tipo de serviço, já que o catálogo é genérico desde a
/// Fase 4. Edição/cancelamento só valem enquanto o pedido ainda está
/// `pending` (a API rejeita com 409 assim que a cozinha começa o preparo).
class OrdersRepository {
  final http.Client _client;

  OrdersRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<void> createOrder({
    required String serviceId,
    required String serviceItemId,
    required String token,
    int quantity = 1,
    String? note,
    DateTime? scheduledFor,
    String? couponId,
    // `true` só quando o pedido vem do fluxo "Informar consumo" do
    // Frigobar — o mesmo item também pode ser pedido normalmente pelo
    // Serviço de Quarto (`false`), que segue o preparo/entrega de sempre.
    // Só tem efeito no backend se o item também for `isMinibarItem`.
    bool isConsumptionReport = false,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/orders'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({
        'serviceId': serviceId,
        'serviceItemId': serviceItemId,
        'quantity': quantity,
        if (note != null) 'note': note,
        if (scheduledFor != null) 'scheduledFor': scheduledFor.toIso8601String(),
        if (couponId != null) 'couponId': couponId,
        if (isConsumptionReport) 'consumptionReport': true,
      }),
    );
    if (response.statusCode == 409) {
      final error = _errorCode(response.body);
      throw StateError(
        switch (error) {
          'slot_full' => 'Esse horário acabou de ficar cheio, escolha outro.',
          'table_full' => 'Esse tipo de mesa acabou de ficar cheio, escolha outro.',
          _ => 'Esse cupom não está mais disponível pra você — tente sem ele.',
        },
      );
    }
    if (response.statusCode == 400) {
      final error = _errorCode(response.body);
      throw StateError(
        switch (error) {
          'invalid_schedule' => 'Esse horário não está mais disponível, escolha outro.',
          'service_closed' => 'Fechado nesse horário.',
          _ => 'Esse cupom não é válido pra esse pedido.',
        },
      );
    }
    if (response.statusCode != 201) {
      throw StateError('Falha ao enviar o pedido (status ${response.statusCode}).');
    }
  }

  String? _errorCode(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      return decoded is Map<String, dynamic> ? decoded['error'] as String? : null;
    } on FormatException {
      return null;
    }
  }

  /// Reserva a MESA de um restaurante (não um prato do cardápio) — sem
  /// `serviceItemId`, a API resolve/cria o item oculto "Reserva de mesa"
  /// por trás. Só vale pra `Service` do tipo `restaurant`.
  Future<void> createTableReservation({
    required String serviceId,
    required String token,
    required DateTime scheduledFor,
    String? tableTypeId,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/orders'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({
        'serviceId': serviceId,
        'scheduledFor': scheduledFor.toIso8601String(),
        if (tableTypeId != null) 'tableTypeId': tableTypeId,
      }),
    );
    if (response.statusCode == 409) {
      final error = _errorCode(response.body);
      throw StateError(
        error == 'table_full'
            ? 'Esse tipo de mesa acabou de ficar cheio, escolha outro.'
            : 'Não foi possível reservar a mesa.',
      );
    }
    if (response.statusCode == 400) {
      final error = _errorCode(response.body);
      throw StateError(
        error == 'service_closed'
            ? 'Fechado nesse horário.'
            : 'Não foi possível reservar a mesa.',
      );
    }
    if (response.statusCode != 201) {
      throw StateError('Falha ao reservar a mesa (status ${response.statusCode}).');
    }
  }

  Future<List<GuestOrder>> getMyOrders({required String token}) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/orders'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar os pedidos (status ${response.statusCode}).');
    }
    final body = jsonDecode(response.body) as List<dynamic>;
    return body.map((raw) => GuestOrder.fromJson(raw as Map<String, dynamic>)).toList();
  }

  Future<void> updateOrder({
    required String orderId,
    required String token,
    int? quantity,
    String? note,
    DateTime? scheduledFor,
  }) async {
    final response = await _client.patch(
      Uri.parse('$apiBaseUrl/api/orders/$orderId'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({
        if (quantity != null) 'quantity': quantity,
        if (note != null) 'note': note,
        if (scheduledFor != null) 'scheduledFor': scheduledFor.toIso8601String(),
      }),
    );
    if (response.statusCode == 409) {
      final error = _errorCode(response.body);
      throw StateError(
        switch (error) {
          'slot_full' => 'Esse horário acabou de ficar cheio, escolha outro.',
          'table_full' => 'Esse tipo de mesa acabou de ficar cheio, escolha outro.',
          _ => 'Esse pedido já está em preparo e não pode mais ser alterado.',
        },
      );
    }
    if (response.statusCode == 400) {
      final error = _errorCode(response.body);
      throw StateError(
        switch (error) {
          'invalid_schedule' => 'Esse horário não está mais disponível, escolha outro.',
          'service_closed' => 'Fechado nesse horário.',
          _ => 'Não foi possível atualizar o pedido.',
        },
      );
    }
    if (response.statusCode != 200) {
      throw StateError('Falha ao atualizar o pedido (status ${response.statusCode}).');
    }
  }

  Future<void> cancelOrder({required String orderId, required String token}) async {
    final response = await _client.patch(
      Uri.parse('$apiBaseUrl/api/orders/$orderId'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'cancel': true}),
    );
    if (response.statusCode == 409) {
      throw StateError('Esse pedido já está em preparo e não pode mais ser cancelado.');
    }
    if (response.statusCode != 200) {
      throw StateError('Falha ao cancelar o pedido (status ${response.statusCode}).');
    }
  }

  /// Total de pedidos com mudança de status ainda não vista — alimenta o
  /// sino de notificações, somado ao de mensagens não lidas
  /// (`MessagesRepository.getUnreadCount`).
  Future<int> getUnseenStatusCount({required String token}) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/guest/orders/unseen-count'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar contagem de pedidos (status ${response.statusCode}).');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['count'] as int? ?? 0;
  }

  /// Marca todos os pedidos como vistos — chamado ao abrir "Meus Pedidos".
  Future<void> markStatusSeen({required String token}) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/guest/orders/seen'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao marcar pedidos como vistos (status ${response.statusCode}).');
    }
  }
}
