/// Fonte de dados de um hotel (tenant) para o app do hóspede.
///
/// As duas implementações ([AssetTenantRepository] e
/// [FirestoreTenantRepository]) devolvem exatamente o mesmo formato de
/// `Map<String, dynamic>` que as telas já esperam, para que a troca de fonte
/// de dados seja invisível para a camada de UI.
abstract class TenantRepository {
  Future<Map<String, dynamic>> getTenantConfig(String hotelId);
  Future<Map<String, dynamic>> getGuestInfo(String hotelId);
  Future<Map<String, dynamic>> getServicesPageConfig(String hotelId);
  Future<Map<String, dynamic>> getRoomServiceMenu(String hotelId);
  Future<Map<String, dynamic>> getSpaServices(String hotelId);
  Future<Map<String, dynamic>> getSpaAvailability(String hotelId);
  Future<Map<String, dynamic>> getRestaurants(String hotelId);
  Future<Map<String, dynamic>> getRestaurantAvailability(String hotelId);
  Future<Map<String, dynamic>> getEventos(String hotelId);
  Future<Map<String, dynamic>> getEventAvailability(String hotelId);
  Future<Map<String, dynamic>> getPasseios(String hotelId);
  Future<Map<String, dynamic>> getPasseiosAvailability(String hotelId);
  Future<Map<String, dynamic>> getMapaData(String hotelId);
}

/// Diretório global (não específico de um hotel) usado na tela de acesso
/// pra validar o código de hotel digitado/escaneado pelo hóspede.
abstract class TenantsDirectoryRepository {
  /// Lista bruta no formato `[{"id": ..., "name": ...}, ...]`.
  Future<List<dynamic>> getTenantsList();
}

/// Promoções da marca Konekto (não específicas de um hotel), mostradas na
/// tela de acesso antes do check-in.
abstract class PromotionsRepository {
  /// Formato bruto `{"promotions": [...]}`.
  Future<Map<String, dynamic>> getPromotions();
}
