/// URL da home do site institucional (apps/konekto_site/index.html) — pra
/// onde a marca "Konekto" no topo da tela de login volta, mesmo padrão de
/// apps/konekto_portal/lib/site_config.dart.
///
/// Padrão aponta pra produção (falha segura). Pra apontar pra um
/// `konekto_site` rodando localmente durante desenvolvimento, sobrescreva:
///
///   flutter run --dart-define=SITE_HOME_URL=http://localhost:8080/index.html
const String siteHomeUrl = String.fromEnvironment(
  'SITE_HOME_URL',
  defaultValue: 'https://konekto-app.vercel.app',
);
