import { NextRequest, NextResponse } from 'next/server'
import { verifyStaffToken, type StaffTokenPayload } from '@/lib/jwt'

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
