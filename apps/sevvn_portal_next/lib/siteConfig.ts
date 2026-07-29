/**
 * URL do login oficial do produto. O portal não tem formulário próprio;
 * quando não há sessão válida, redireciona pra cá.
 *
 * Padrão aponta pra produção (falha segura). Para apontar pra um
 * login local durante desenvolvimento, defina
 * NEXT_PUBLIC_SITE_LOGIN_URL=http://localhost:3002/login em .env.local.
 */
export const siteLoginUrl =
  process.env.NEXT_PUBLIC_SITE_LOGIN_URL ?? 'https://sevvn-site.vercel.app/login'
