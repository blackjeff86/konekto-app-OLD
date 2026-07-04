import 'package:konekto/data/asset_tenant_repository.dart';
import 'package:konekto/data/firestore_tenant_repository.dart';
import 'package:konekto/data/tenant_repository.dart';

/// Liga a fonte de dados usada pelo app: assets locais (padrão, comportamento
/// de hoje) ou Firestore. Troque em tempo de build com:
///
///   flutter run --dart-define=USE_FIRESTORE=true
///
/// Mantém o app funcionando exatamente como antes por padrão até a migração
/// pra Firestore ser validada tela por tela.
const bool useFirestore = bool.fromEnvironment('USE_FIRESTORE', defaultValue: false);

TenantRepository createTenantRepository() => useFirestore ? FirestoreTenantRepository() : AssetTenantRepository();

TenantsDirectoryRepository createTenantsDirectoryRepository() =>
    useFirestore ? FirestoreTenantsDirectoryRepository() : AssetTenantsDirectoryRepository();

PromotionsRepository createPromotionsRepository() =>
    useFirestore ? FirestorePromotionsRepository() : AssetPromotionsRepository();
