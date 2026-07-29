/**
 * Wrapper fino de fetch — espelha o padrão repetido nos 14 repositórios Dart
 * de apps/konekto_portal/lib/data/*.dart: header Authorization: Bearer,
 * parse de JSON, e mapeamento manual de status code (409 -> mensagem de
 * conflito específica do chamador, resto -> mensagem genérica com o status).
 *
 * Cada chamador (lib/api/<recurso>.ts) fornece as mensagens PT-BR
 * específicas daquele endpoint, do mesmo jeito que cada método Dart tinha
 * sua própria string de erro.
 */

export class ApiError extends Error {
  readonly status: number

  constructor(message: string, status: number) {
    super(message)
    this.name = 'ApiError'
    this.status = status
  }
}

type HttpMethod = 'GET' | 'POST' | 'PATCH' | 'DELETE'

export interface ApiRequestOptions {
  method?: HttpMethod
  /** Omitir pra endpoints públicos (ex: catálogo de serviços) — nenhum header Authorization é enviado. */
  token?: string
  body?: unknown
  /** Mensagem PT-BR a usar quando o servidor responde 409 (conflito). */
  conflictMessage?: string
  /** Mensagem PT-BR genérica quando a resposta não é 2xx (e não é 409, ou não há conflictMessage). */
  errorMessage?: string
}

export const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? 'https://sevvn-api.vercel.app'

export async function apiRequest<T>(
  path: string,
  options: ApiRequestOptions = {},
): Promise<T> {
  const { method = 'GET', token, body, conflictMessage, errorMessage } = options

  const headers: Record<string, string> = {}
  if (token) headers.Authorization = `Bearer ${token}`
  if (body !== undefined) {
    headers['Content-Type'] = 'application/json'
  }

  let response: Response
  try {
    response = await fetch(`${API_BASE_URL}${path}`, {
      method,
      headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
    })
  } catch {
    throw new ApiError(
      'Não foi possível conectar ao servidor. Tente novamente.',
      0,
    )
  }

  if (response.status === 409 && conflictMessage) {
    throw new ApiError(conflictMessage, 409)
  }

  if (!response.ok) {
    throw new ApiError(
      errorMessage ?? `Falha na requisição (status ${response.status}).`,
      response.status,
    )
  }

  const text = await response.text()
  if (!text) return undefined as T
  return JSON.parse(text) as T
}
