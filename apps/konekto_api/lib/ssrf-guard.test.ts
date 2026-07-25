import { describe, expect, it, vi } from 'vitest'

vi.mock('node:dns', () => ({
  promises: { lookup: vi.fn() },
}))

import { promises as dns } from 'node:dns'
import { isSafeHost, safeParseUrl } from './ssrf-guard'

describe('safeParseUrl', () => {
  it('accepts http/https URLs', () => {
    expect(safeParseUrl('https://example.com/hook')?.hostname).toBe('example.com')
    expect(safeParseUrl('http://example.com/hook')?.hostname).toBe('example.com')
  })

  it('rejects non-http(s) schemes', () => {
    expect(safeParseUrl('file:///etc/passwd')).toBeNull()
    expect(safeParseUrl('ftp://example.com')).toBeNull()
  })

  it('rejects malformed URLs', () => {
    expect(safeParseUrl('not-a-url')).toBeNull()
  })
})

describe('isSafeHost', () => {
  it('rejects "localhost" outright', async () => {
    expect(await isSafeHost('localhost')).toBe(false)
  })

  it('rejects private/loopback/link-local IPv4 literals', async () => {
    expect(await isSafeHost('127.0.0.1')).toBe(false)
    expect(await isSafeHost('10.0.0.5')).toBe(false)
    expect(await isSafeHost('192.168.1.1')).toBe(false)
    expect(await isSafeHost('169.254.169.254')).toBe(false) // cloud metadata endpoint
  })

  it('accepts a public IPv4 literal', async () => {
    expect(await isSafeHost('8.8.8.8')).toBe(true)
  })

  it('rejects private IPv6 literals', async () => {
    expect(await isSafeHost('::1')).toBe(false)
    expect(await isSafeHost('fe80::1')).toBe(false)
  })

  it('resolves a hostname via DNS and rejects it if it points to a private address (DNS rebinding)', async () => {
    vi.mocked(dns.lookup).mockResolvedValue([{ address: '169.254.169.254', family: 4 }] as never)

    expect(await isSafeHost('attacker-controlled.example')).toBe(false)
  })

  it('resolves a hostname via DNS and accepts it when every resolved address is public', async () => {
    vi.mocked(dns.lookup).mockResolvedValue([{ address: '93.184.216.34', family: 4 }] as never)

    expect(await isSafeHost('example.com')).toBe(true)
  })

  it('rejects when DNS resolution fails', async () => {
    vi.mocked(dns.lookup).mockRejectedValue(new Error('ENOTFOUND'))

    expect(await isSafeHost('does-not-resolve.example')).toBe(false)
  })
})
