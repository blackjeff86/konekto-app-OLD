import { describe, expect, it } from 'vitest'
import { generateApiKey, hashApiKey, generateWebhookSecret } from './integration-keys'

describe('generateApiKey', () => {
  it('returns a plain key prefixed with kk_live_ and its matching hash', () => {
    const { plainKey, hash, prefix } = generateApiKey()

    expect(plainKey.startsWith('kk_live_')).toBe(true)
    expect(hash).toBe(hashApiKey(plainKey))
    expect(prefix).toBe(plainKey.slice(0, prefix.length))
    expect(plainKey.startsWith(prefix)).toBe(true)
  })

  it('generates a different key on every call', () => {
    const a = generateApiKey()
    const b = generateApiKey()

    expect(a.plainKey).not.toBe(b.plainKey)
    expect(a.hash).not.toBe(b.hash)
  })
})

describe('hashApiKey', () => {
  it('is deterministic for the same input', () => {
    expect(hashApiKey('kk_live_abc')).toBe(hashApiKey('kk_live_abc'))
  })

  it('differs for different inputs', () => {
    expect(hashApiKey('kk_live_abc')).not.toBe(hashApiKey('kk_live_abd'))
  })
})

describe('generateWebhookSecret', () => {
  it('generates a non-empty hex string, different on every call', () => {
    const a = generateWebhookSecret()
    const b = generateWebhookSecret()

    expect(a).toMatch(/^[0-9a-f]+$/)
    expect(a).not.toBe(b)
  })
})
