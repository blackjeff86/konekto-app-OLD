/// URL do login "oficial" (apps/konekto_site/login.html) — única tela de
/// login real do produto. O portal não tem formulário próprio; quando não
/// há sessão válida, redireciona pra cá. Troque em tempo de build com:
///
///   flutter run --dart-define=SITE_LOGIN_URL=https://konekto.app/login.html
const String siteLoginUrl = String.fromEnvironment(
  'SITE_LOGIN_URL',
  defaultValue: 'http://localhost:8080/login.html',
);
