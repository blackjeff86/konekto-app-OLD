/// Fonte de dados de um hotel (tenant) para o app do hóspede.
///
/// As duas implementações ([AssetTenantRepository] e
/// [FirestoreTenantRepository]) devolvem exatamente o mesmo formato de
/// `Map<String, dynamic>` que as telas já esperam, para que a troca de fonte
/// de dados seja invisível para a camada de UI.
abstract class TenantRepository {
  Future<Map<String, dynamic>> getTenantConfig(String hotelId);
  Future<Map<String, dynamic>> getServicesPageConfig(String hotelId);

  /// Serviços dinâmicos do hotel (Room Service, Spa, cada restaurante, ou
  /// qualquer serviço que o hotel tenha criado) — substitui os métodos
  /// fixos por tipo de catálogo que existiam antes (getRoomServiceMenu,
  /// getSpaServices, getRestaurants, getEventos, getPasseios).
  Future<List<dynamic>> getServices(String hotelId);
  Future<Map<String, dynamic>> getService(String hotelId, String serviceId);

  /// Grade de horários disponíveis pra um item com agendamento configurado
  /// (`ServiceItem.durationMinutes != null`) numa data específica —
  /// `{"schedulingEnabled": false}` quando o item não tem agendamento
  /// configurado (o app cai no seletor de dia/hora livre de sempre).
  Future<Map<String, dynamic>> getItemAvailability({
    required String hotelId,
    required String serviceId,
    required String itemId,
    required DateTime date,
  });

  /// Disponibilidade de mesas de um restaurante num instante exato — sem
  /// grade de horários (diferente do agendamento de item): o hóspede
  /// escolhe livremente dia/hora, e isso devolve quantas mesas de cada
  /// tipo ainda estão livres naquele instante específico.
  Future<Map<String, dynamic>> getTableAvailability({
    required String hotelId,
    required String serviceId,
    required DateTime scheduledFor,
  });
}

/// Promoções da marca Konekto (não específicas de um hotel), mostradas na
/// tela de acesso antes do check-in.
abstract class PromotionsRepository {
  /// Formato bruto `{"promotions": [...]}`.
  Future<Map<String, dynamic>> getPromotions();
}
