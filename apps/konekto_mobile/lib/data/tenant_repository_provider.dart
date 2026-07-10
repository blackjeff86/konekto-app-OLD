import 'package:konekto/data/asset_tenant_repository.dart';
import 'package:konekto/data/http_tenant_repository.dart';
import 'package:konekto/data/tenant_repository.dart';

/// Liga a fonte de dados usada pelo app: assets locais (padrão, comportamento
/// de hoje) ou a API (apps/konekto_api). Troque em tempo de build com:
///
///   flutter run --dart-define=USE_API=true --dart-define=API_BASE_URL=https://sua-api.vercel.app
///
/// Mantém o app funcionando exatamente como antes por padrão até a API ser
/// validada tela por tela.
const bool useApi = bool.fromEnvironment('USE_API', defaultValue: false);

TenantRepository createTenantRepository() => useApi ? HttpTenantRepository() : AssetTenantRepository();

PromotionsRepository createPromotionsRepository() =>
    useApi ? HttpPromotionsRepository() : AssetPromotionsRepository();
