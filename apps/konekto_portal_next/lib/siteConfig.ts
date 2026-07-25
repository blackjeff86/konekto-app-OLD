/**
 * Portado de apps/konekto_portal/lib/site_config.dart — URL do login
 * "oficial" (apps/konekto_site/login.html), única tela de login real do
 * produto. O portal não tem formulário próprio; quando não há sessão
 * válida, redireciona pra cá.
 *
 * Padrão aponta pra produção (falha segura). Para apontar pra um
 * konekto_site local durante desenvolvimento, defina
 * NEXT_PUBLIC_SITE_LOGIN_URL=http://localhost:8080/login.html em .env.local.
 */
export const siteLoginUrl =
  process.env.NEXT_PUBLIC_SITE_LOGIN_URL ?? 'https://konekto-app.vercel.app/login.html'
