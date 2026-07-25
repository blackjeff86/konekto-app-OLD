import { NextRequest, NextResponse } from 'next/server'
import { verifyStaffToken, type StaffTokenPayload } from '@/lib/jwt'
import { verifyGuestToken, type GuestTokenPayload } from '@/lib/guest-auth'
import { verifyPlatformAdminToken, type PlatformAdminTokenPayload } from '@/lib/platform-auth'
import { hashApiKey } from '@/lib/integration-keys'
import { expireStay } from '@/lib/stay-expiration'
import { prisma } from '@/lib/prisma'

export class AuthGuardError extends Error {
  constructor(public readonly response: NextResponse) {
    super('AuthGuardError')
  }
}

/**
 * Extrai e verifica o Bearer token, e confirma que o `role` do staff está
 * entre os papéis permitidos. Lança AuthGuardError (401/403) em vez de
 * retornar null, pra rota chamadora só precisar de um try/catch.
 */
export async function requireStaffRole(
  request: NextRequest,
  allowedRoles: StaffTokenPayload['role'][],
): Promise<StaffTokenPayload> {
  const authHeader = request.headers.get('authorization')
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : null
  if (!token) {
    throw new AuthGuardError(NextResponse.json({ error: 'missing_token' }, { status: 401 }))
  }

  let payload: StaffTokenPayload
  try {
    payload = await verifyStaffToken(token)
  } catch {
    throw new AuthGuardError(NextResponse.json({ error: 'invalid_token' }, { status: 401 }))
  }

  if (!allowedRoles.includes(payload.role)) {
    throw new AuthGuardError(NextResponse.json({ error: 'forbidden' }, { status: 403 }))
  }

  return payload
}

/**
 * Extrai e verifica o Bearer token de um HÓSPEDE (não staff) — mesma
 * forma de `requireStaffRole`, sem checagem de papel (hóspede não tem
 * `role`).
 *
 * O token em si vive até 7 dias e não carrega status algum — por isso
 * SEMPRE revalida contra o banco (mesmo espírito de `/api/auth/me` pro
 * staff: nunca confiar só no token). Sem isso, um acesso revogado
 * manualmente ("Revogar acesso" no portal) ou uma estadia cujo check-out
 * já passou continuariam funcionando normalmente até o token expirar
 * sozinho. Se o check-out já passou mas a Stay ainda está `active` no
 * banco (staff nunca clicou em "Fechar conta", sem cron neste projeto),
 * fecha ela na hora — a mesma leitura que bloqueia o acesso já corrige o
 * status.
 */
export async function requireGuestAuth(request: NextRequest): Promise<GuestTokenPayload> {
  const authHeader = request.headers.get('authorization')
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : null
  if (!token) {
    throw new AuthGuardError(NextResponse.json({ error: 'missing_token' }, { status: 401 }))
  }

  let payload: GuestTokenPayload
  try {
    payload = await verifyGuestToken(token)
  } catch {
    throw new AuthGuardError(NextResponse.json({ error: 'invalid_token' }, { status: 401 }))
  }

  const guest = await prisma.guest.findUnique({ where: { id: payload.sub }, include: { stay: true } })
  if (!guest) {
    throw new AuthGuardError(NextResponse.json({ error: 'access_revoked' }, { status: 401 }))
  }

  const isOverdue = guest.stay.status === 'active' && guest.stay.checkOutDate.getTime() < Date.now()
  if (isOverdue) {
    await expireStay(guest.stayId)
  }

  if (guest.status !== 'active' || guest.stay.status === 'closed' || isOverdue) {
    throw new AuthGuardError(NextResponse.json({ error: 'access_revoked' }, { status: 401 }))
  }

  return payload
}

/**
 * Extrai e verifica uma chave de API de integração (PMS/sistema externo do
 * hotel) — mesmo formato Bearer dos outros guards, mas a identidade do
 * hotel vem da própria chave (hash único por `HotelIntegration`), não de um
 * parâmetro de URL. Isso torna estruturalmente impossível uma chave de um
 * hotel escrever dado de outro.
 */
export async function requireIntegrationAuth(request: NextRequest): Promise<{ hotelId: string }> {
  const authHeader = request.headers.get('authorization')
  const key = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : null
  if (!key) {
    throw new AuthGuardError(NextResponse.json({ error: 'missing_api_key' }, { status: 401 }))
  }

  const integration = await prisma.hotelIntegration.findUnique({ where: { apiKeyHash: hashApiKey(key) } })
  if (!integration || !integration.enabled) {
    throw new AuthGuardError(NextResponse.json({ error: 'invalid_api_key' }, { status: 401 }))
  }

  return { hotelId: integration.hotelId }
}

/**
 * Extrai e verifica o Bearer token de um admin da PLATAFORMA (equipe do
 * Konekto, não staff de hotel) — assinado com um secret próprio
 * (`PLATFORM_ADMIN_JWT_SECRET`, diferente do `JWT_SECRET` de staff/hóspede)
 * e com um discriminador de tipo checado em `verifyPlatformAdminToken`, já
 * que é a credencial de maior privilégio do sistema (leitura cross-tenant
 * de todos os hotéis). Sem checagem de `hotelId` — o admin vê tudo.
 */
export async function requirePlatformAdmin(request: NextRequest): Promise<PlatformAdminTokenPayload> {
  const authHeader = request.headers.get('authorization')
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : null
  if (!token) {
    throw new AuthGuardError(NextResponse.json({ error: 'missing_token' }, { status: 401 }))
  }

  try {
    return await verifyPlatformAdminToken(token)
  } catch {
    throw new AuthGuardError(NextResponse.json({ error: 'invalid_token' }, { status: 401 }))
  }
}
