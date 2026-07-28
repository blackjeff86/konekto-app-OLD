/// URL da home do site institucional (apps/konekto_site_next) — pra onde a
/// marca "Sevvn" no topo da tela de login volta, mesmo padrão de
/// apps/konekto_portal/lib/site_config.dart.
///
/// Padrão aponta pra produção (falha segura). Pra apontar pra um
/// `konekto_site_next` rodando localmente durante desenvolvimento, sobrescreva:
///
///   flutter run --dart-define=SITE_HOME_URL=http://localhost:3002
const String siteHomeUrl = String.fromEnvironment(
  'SITE_HOME_URL',
  defaultValue: 'https://sevvn-site.vercel.app',
);
