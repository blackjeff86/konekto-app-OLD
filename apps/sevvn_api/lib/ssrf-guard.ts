import { promises as dns } from 'node:dns'
import net from 'node:net'

// Compartilhado entre `image-proxy` (busca imagem colada pelo hotel) e o
// dispatch de webhook de integração (`integration-webhook.ts`) — os dois
// fazem uma requisição de saída pra uma URL configurada por um usuário do
// portal, então os dois precisam da mesma defesa contra SSRF (URL apontando
// pra IP interno/metadata de nuvem, com ou sem DNS rebinding).

function ipv4ToInt(ip: string): number | null {
  const parts = ip.split('.').map(Number)
  if (parts.length !== 4 || parts.some((part) => Number.isNaN(part) || part < 0 || part > 255)) return null
  return ((parts[0] << 24) | (parts[1] << 16) | (parts[2] << 8) | parts[3]) >>> 0
}

const PRIVATE_IPV4_RANGES: Array<[string, number]> = [
  ['0.0.0.0', 8],
  ['10.0.0.0', 8],
  ['100.64.0.0', 10],
  ['127.0.0.0', 8],
  ['169.254.0.0', 16], // inclui o endpoint de metadata de nuvem (169.254.169.254)
  ['172.16.0.0', 12],
  ['192.0.0.0', 24],
  ['192.168.0.0', 16],
  ['198.18.0.0', 15],
  ['224.0.0.0', 4],
]

function isPrivateIpv4(ip: string): boolean {
  const value = ipv4ToInt(ip)
  if (value === null) return true
  return PRIVATE_IPV4_RANGES.some(([base, prefix]) => {
    const baseInt = ipv4ToInt(base)!
    const mask = prefix === 0 ? 0 : (~0 << (32 - prefix)) >>> 0
    return (value & mask) === (baseInt & mask)
  })
}

function isPrivateIpv6(ip: string): boolean {
  const normalized = ip.toLowerCase()
  return (
    normalized === '::1' ||
    normalized.startsWith('fe80:') ||
    normalized.startsWith('fc') ||
    normalized.startsWith('fd') ||
    normalized.startsWith('::ffff:127.') ||
    normalized.startsWith('::ffff:10.') ||
    normalized.startsWith('::ffff:192.168.') ||
    normalized.startsWith('::ffff:169.254.')
  )
}

// Resolve o hostname de verdade (em vez de só olhar a string) — bloqueia
// tanto IPs privados literais quanto um domínio público que aponte (DNS
// rebinding) pra um IP interno.
export async function isSafeHost(hostname: string): Promise<boolean> {
  if (hostname === 'localhost') return false
  const literalFamily = net.isIP(hostname)
  if (literalFamily === 4) return !isPrivateIpv4(hostname)
  if (literalFamily === 6) return !isPrivateIpv6(hostname)

  try {
    const results = await dns.lookup(hostname, { all: true })
    if (results.length === 0) return false
    return results.every((result) => (result.family === 4 ? !isPrivateIpv4(result.address) : !isPrivateIpv6(result.address)))
  } catch {
    return false
  }
}

export function safeParseUrl(value: string): URL | null {
  try {
    const parsed = new URL(value)
    if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') return null
    return parsed
  } catch {
    return null
  }
}
