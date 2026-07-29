/**
 * Chave atual do portal web, com migração automática da chave legada do
 * rebrand anterior pra não derrubar sessões já abertas.
 */
const TOKEN_KEY = 'sevvn_portal_auth_token'
const LEGACY_TOKEN_KEY = 'konekto_portal_auth_token'

export function getStoredToken(): string | null {
  if (typeof window === 'undefined') return null
  const current = window.localStorage.getItem(TOKEN_KEY)
  if (current) return current

  const legacy = window.localStorage.getItem(LEGACY_TOKEN_KEY)
  if (!legacy) return null

  window.localStorage.setItem(TOKEN_KEY, legacy)
  window.localStorage.removeItem(LEGACY_TOKEN_KEY)
  return legacy
}

export function setStoredToken(token: string): void {
  window.localStorage.setItem(TOKEN_KEY, token)
  window.localStorage.removeItem(LEGACY_TOKEN_KEY)
}

export function clearStoredToken(): void {
  window.localStorage.removeItem(TOKEN_KEY)
  window.localStorage.removeItem(LEGACY_TOKEN_KEY)
}

/**
 * Se a URL atual tiver `?token=...` (redirecionamento vindo do login.html do
 * site), persiste esse token e limpa a URL — evita deixar o token visível na
 * barra de endereço ou no histórico do navegador. Espelha
 * `AuthRepository._consumeTokenFromUrl()`.
 */
export function consumeTokenFromUrl(): string | null {
  if (typeof window === 'undefined') return null

  const url = new URL(window.location.href)
  const token = url.searchParams.get('token')
  if (!token) return null

  setStoredToken(token)
  url.searchParams.delete('token')
  window.history.replaceState(null, '', url.toString())
  return token
}
