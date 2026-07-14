/// URL do login "oficial" (apps/konekto_site/login.html) — única tela de
/// login real do produto. O portal não tem formulário próprio; quando não
/// há sessão válida, redireciona pra cá.
///
/// Padrão aponta pra produção (falha segura) — builds de produção sem essa
/// flag ainda funcionam corretamente. Pra apontar pra um `konekto_site`
/// rodando localmente durante desenvolvimento, sobrescreva:
///
///   flutter run --dart-define=SITE_LOGIN_URL=http://localhost:8080/login.html
const String siteLoginUrl = String.fromEnvironment(
  'SITE_LOGIN_URL',
  defaultValue: 'https://konekto-app.vercel.app/login.html',
);
