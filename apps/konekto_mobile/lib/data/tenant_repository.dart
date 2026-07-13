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
}

/// Promoções da marca Konekto (não específicas de um hotel), mostradas na
/// tela de acesso antes do check-in.
abstract class PromotionsRepository {
  /// Formato bruto `{"promotions": [...]}`.
  Future<Map<String, dynamic>> getPromotions();
}
