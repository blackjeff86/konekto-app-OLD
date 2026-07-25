import { SignJWT, jwtVerify } from 'jose'

export interface PlatformAdminTokenPayload {
  sub: string
  email: string
  name: string
  // Discriminador explícito — staff/hóspede/platform-admin usam secrets
  // diferentes, mas nenhum dos três verificadores valida o formato do
  // payload em tempo de execução (só um cast). Essa credencial é a de
  // maior privilégio do sistema (leitura cross-tenant de todos os
  // hotéis), então `verifyPlatformAdminToken` confere esse campo
  // explicitamente em vez de confiar só no cast.
  type: 'platform_admin'
}

const PLATFORM_ADMIN_JWT_EXPIRES_IN = '12h'

function getSecretKey(): Uint8Array {
  const secret = process.env.PLATFORM_ADMIN_JWT_SECRET
  if (!secret) {
    throw new Error('Missing required env var: PLATFORM_ADMIN_JWT_SECRET')
  }
  return new TextEncoder().encode(secret)
}

export async function signPlatformAdminToken(
  payload: Omit<PlatformAdminTokenPayload, 'type'>,
): Promise<string> {
  return new SignJWT({ ...payload, type: 'platform_admin' })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime(PLATFORM_ADMIN_JWT_EXPIRES_IN)
    .sign(getSecretKey())
}

export async function verifyPlatformAdminToken(token: string): Promise<PlatformAdminTokenPayload> {
  const { payload } = await jwtVerify(token, getSecretKey())
  if (payload.type !== 'platform_admin') {
    throw new Error('invalid_token_type')
  }
  return payload as unknown as PlatformAdminTokenPayload
}
