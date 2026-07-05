import { SignJWT, jwtVerify } from 'jose'

export interface StaffTokenPayload {
  sub: string
  hotelId: string
  role: 'gerente' | 'recepcao'
  email: string
  name: string
}

const JWT_EXPIRES_IN = '12h'

function getSecretKey(): Uint8Array {
  const secret = process.env.JWT_SECRET
  if (!secret) {
    throw new Error('Missing required env var: JWT_SECRET')
  }
  return new TextEncoder().encode(secret)
}

export async function signStaffToken(payload: StaffTokenPayload): Promise<string> {
  return new SignJWT({ ...payload })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime(JWT_EXPIRES_IN)
    .sign(getSecretKey())
}

export async function verifyStaffToken(token: string): Promise<StaffTokenPayload> {
  const { payload } = await jwtVerify(token, getSecretKey())
  return payload as unknown as StaffTokenPayload
}
