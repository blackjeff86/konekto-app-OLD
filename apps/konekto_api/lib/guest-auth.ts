import { SignJWT, jwtVerify } from 'jose'

export interface GuestTokenPayload {
  sub: string
  hotelId: string
  name: string
  roomNumber: string
}

// Estadia típica cabe numa janela bem maior que a sessão de staff (12h) —
// o hóspede não vai "logar de novo" no meio da viagem.
const GUEST_JWT_EXPIRES_IN = '7d'

function getSecretKey(): Uint8Array {
  const secret = process.env.JWT_SECRET
  if (!secret) {
    throw new Error('Missing required env var: JWT_SECRET')
  }
  return new TextEncoder().encode(secret)
}

export async function signGuestToken(payload: GuestTokenPayload): Promise<string> {
  return new SignJWT({ ...payload })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime(GUEST_JWT_EXPIRES_IN)
    .sign(getSecretKey())
}

export async function verifyGuestToken(token: string): Promise<GuestTokenPayload> {
  const { payload } = await jwtVerify(token, getSecretKey())
  return payload as unknown as GuestTokenPayload
}
