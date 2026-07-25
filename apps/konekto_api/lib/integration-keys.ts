import { randomBytes, createHash } from 'crypto'

const KEY_PREFIX = 'kk_live_'

export interface GeneratedApiKey {
  /** Chave em texto puro — só existe nesse retorno; nunca é persistida. */
  plainKey: string
  /** SHA-256 da chave, é isso que fica gravado em `HotelIntegration.apiKeyHash`. */
  hash: string
  /** Primeiros caracteres da chave, sem valor de segredo — só pra exibição. */
  prefix: string
}

export function generateApiKey(): GeneratedApiKey {
  const random = randomBytes(24).toString('base64url')
  const plainKey = `${KEY_PREFIX}${random}`
  return {
    plainKey,
    hash: hashApiKey(plainKey),
    prefix: plainKey.slice(0, KEY_PREFIX.length + 8),
  }
}

export function hashApiKey(plainKey: string): string {
  return createHash('sha256').update(plainKey).digest('hex')
}

export function generateWebhookSecret(): string {
  return randomBytes(32).toString('hex')
}
