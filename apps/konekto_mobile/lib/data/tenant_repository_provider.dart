import 'package:konekto/data/asset_tenant_repository.dart';
import 'package:konekto/data/http_tenant_repository.dart';
import 'package:konekto/data/tenant_repository.dart';

/// Liga a fonte de dados usada pelo app: API real (padrão seguro para piloto)
/// ou assets locais (fallback explícito, nunca implícito). Modos suportados:
///
///   flutter run --dart-define=APP_RUNTIME_MODE=api --dart-define=API_BASE_URL=https://sua-api.vercel.app
///   flutter run --dart-define=APP_RUNTIME_MODE=asset
///
/// Compatibilidade temporária:
///
/// - `USE_API=true` continua funcionando como alias legado de `api`
/// - `USE_API=false` continua funcionando como alias legado de `asset`
///
/// Se nada for passado, o app sobe em `api`, porque o caminho oficial de
/// piloto da Sevvn precisa validar contra backend real por padrão.
const String appRuntimeMode = String.fromEnvironment(
  'APP_RUNTIME_MODE',
  defaultValue: '',
);
const bool _legacyUseApi = bool.fromEnvironment('USE_API', defaultValue: true);
const bool useApi = appRuntimeMode == 'asset'
    ? false
    : appRuntimeMode == 'api'
        ? true
        : _legacyUseApi;
const bool useAssetMode = !useApi;

TenantRepository createTenantRepository() => useApi ? HttpTenantRepository() : AssetTenantRepository();

PromotionsRepository createPromotionsRepository() =>
    useApi ? HttpPromotionsRepository() : AssetPromotionsRepository();
