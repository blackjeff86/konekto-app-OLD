/// Resumo da estadia ATIVA de um quarto (se tiver) — vem embutido na
/// resposta de `GET /api/hotels/:hotelId/rooms`, já com o suficiente pra
/// mostrar "ocupado, N hóspedes, R$ X em aberto" direto no card do mapa,
/// sem uma segunda chamada. Pra abrir o detalhe completo (avisos, fechar
/// conta), a tela busca a `Stay` de verdade por `id` via `StaysRepository`.
class RoomActiveStay {
  final String id;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final double consumptionTotal;

  const RoomActiveStay({
    required this.id,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestCount,
    required this.consumptionTotal,
  });

  factory RoomActiveStay.fromJson(Map<String, dynamic> json) {
    final guests = json['guests'] as List<dynamic>? ?? const [];
    double total = 0;
    for (final rawGuest in guests) {
      final guest = rawGuest as Map<String, dynamic>;
      final orders = guest['orders'] as List<dynamic>? ?? const [];
      for (final rawOrder in orders) {
        final order = rawOrder as Map<String, dynamic>;
        final price = (order['price'] as num?)?.toDouble();
        final quantity = order['quantity'] as int? ?? 1;
        if (price != null) total += price * quantity;
      }
    }
    return RoomActiveStay(
      id: json['id'] as String,
      checkInDate: DateTime.parse(json['checkInDate'] as String),
      checkOutDate: DateTime.parse(json['checkOutDate'] as String),
      guestCount: guests.length,
      consumptionTotal: total,
    );
  }
}

/// Quarto físico do hotel — cadastro em Configurações. `activeStay` vem
/// preenchido quando o quarto está ocupado agora (usado pro mapa de
/// quartos mostrar livre/ocupado sem outra chamada).
class Room {
  final String id;
  final String number;
  final String? description;
  final RoomActiveStay? activeStay;

  const Room({required this.id, required this.number, this.description, this.activeStay});

  bool get isOccupied => activeStay != null;

  factory Room.fromJson(Map<String, dynamic> json) {
    final rawActiveStay = json['activeStay'] as Map<String, dynamic>?;
    return Room(
      id: json['id'] as String,
      number: json['number'] as String,
      description: json['description'] as String?,
      activeStay: rawActiveStay != null ? RoomActiveStay.fromJson(rawActiveStay) : null,
    );
  }
}

/// Dados do formulário de cadastro/edição de um quarto físico.
class RoomInput {
  final String number;
  final String? description;

  const RoomInput({required this.number, this.description});

  Map<String, dynamic> toJson() {
    return {'number': number, if (description != null) 'description': description};
  }
}
