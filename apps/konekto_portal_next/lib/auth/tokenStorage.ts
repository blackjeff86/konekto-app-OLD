/**
 * Portado de AuthRepository (auth_repository.dart): mesma chave de
 * localStorage (`konekto_portal_auth_token`) usada hoje pelo app Flutter —
 * não renomear, mantém o hábito de suporte/depuração manual válido.
 */
const TOKEN_KEY = 'konekto_portal_auth_token'

export function getStoredToken(): string | null {
  if (typeof window === 'undefined') return null
  return window.localStorage.getItem(TOKEN_KEY)
}

export function setStoredToken(token: string): void {
  window.localStorage.setItem(TOKEN_KEY, token)
}

export function clearStoredToken(): void {
  window.localStorage.removeItem(TOKEN_KEY)
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
