import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konekto/data/tenant_repository.dart';

/// Implementação Firestore: cada hotel tem um documento principal
/// (`hotels/{hotelId}`, com o mesmo conteúdo de `tenant_config.json`) e uma
/// subcoleção `content` com um documento por página (mesmo formato de cada
/// JSON de hoje: `{pageConfig: ..., <lista>: [...]}`). Isso preserva
/// exatamente o formato que as telas já sabem interpretar — só troca de onde
/// os dados vêm.
///
/// Nota de escopo: guardamos cada página como um documento único por
/// enquanto (em vez de um documento por item de cardápio/serviço) para
/// entregar essa primeira fase com fidelidade ao formato atual. Passar para
/// documentos por item (permitindo edição granular pelo portal do hotel) é
/// um refinamento natural da Fase 5, quando o CRUD do portal precisar disso
/// de verdade — não vale a complexidade adicional agora.
class FirestoreTenantRepository implements TenantRepository {
  FirestoreTenantRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _hotelDoc(String hotelId) => _firestore.collection('hotels').doc(hotelId);

  Future<Map<String, dynamic>> _getContentDoc(String hotelId, String docName) async {
    final snapshot = await _hotelDoc(hotelId).collection('content').doc(docName).get();
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Documento "$docName" não encontrado para o hotel "$hotelId".');
    }
    return data;
  }

  @override
  Future<Map<String, dynamic>> getTenantConfig(String hotelId) async {
    final snapshot = await _hotelDoc(hotelId).get();
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Hotel "$hotelId" não encontrado.');
    }
    return data;
  }

  @override
  Future<Map<String, dynamic>> getGuestInfo(String hotelId) => _getContentDoc(hotelId, 'guestInfo');

  @override
  Future<Map<String, dynamic>> getServicesPageConfig(String hotelId) => _getContentDoc(hotelId, 'servicesPage');

  @override
  Future<Map<String, dynamic>> getRoomServiceMenu(String hotelId) => _getContentDoc(hotelId, 'roomService');

  @override
  Future<Map<String, dynamic>> getSpaServices(String hotelId) => _getContentDoc(hotelId, 'spa');

  @override
  Future<Map<String, dynamic>> getSpaAvailability(String hotelId) => _getContentDoc(hotelId, 'spaAvailability');

  @override
  Future<Map<String, dynamic>> getRestaurants(String hotelId) => _getContentDoc(hotelId, 'restaurants');

  @override
  Future<Map<String, dynamic>> getRestaurantAvailability(String hotelId) =>
      _getContentDoc(hotelId, 'restaurantAvailability');

  @override
  Future<Map<String, dynamic>> getEventos(String hotelId) => _getContentDoc(hotelId, 'eventos');

  @override
  Future<Map<String, dynamic>> getEventAvailability(String hotelId) => _getContentDoc(hotelId, 'eventAvailability');

  @override
  Future<Map<String, dynamic>> getPasseios(String hotelId) => _getContentDoc(hotelId, 'passeios');

  @override
  Future<Map<String, dynamic>> getPasseiosAvailability(String hotelId) =>
      _getContentDoc(hotelId, 'passeiosAvailability');

  @override
  Future<Map<String, dynamic>> getMapaData(String hotelId) => _getContentDoc(hotelId, 'mapa');
}

class FirestoreTenantsDirectoryRepository implements TenantsDirectoryRepository {
  FirestoreTenantsDirectoryRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<dynamic>> getTenantsList() async {
    final snapshot = await _firestore.collection('hotels').get();
    return snapshot.docs.map((doc) {
      final hotelInfo = doc.data()['hotelInfo'] as Map<String, dynamic>? ?? {};
      return {'id': doc.id, 'name': hotelInfo['name'] ?? doc.id};
    }).toList();
  }
}

class FirestorePromotionsRepository implements PromotionsRepository {
  FirestorePromotionsRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<Map<String, dynamic>> getPromotions() async {
    final snapshot = await _firestore.collection('konektoBrand').doc('promotions').get();
    return snapshot.data() ?? {'promotions': []};
  }
}
