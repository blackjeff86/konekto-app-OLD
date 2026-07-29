import { NextRequest, NextResponse } from 'next/server'
import { requirePlatformAdmin, AuthGuardError } from '@/lib/auth-guard'
import { prisma } from '@/lib/prisma'

export const runtime = 'nodejs'

// Sempre resolve de novo contra o Postgres em vez de confiar só no claim do
// token — uma conta de admin removida depois do login continua barrada,
// mesmo com um token ainda válido (mesma semântica de `/api/auth/me`).
export async function GET(request: NextRequest) {
  let payload
  try {
    payload = await requirePlatformAdmin(request)
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  const admin = await prisma.platformAdmin.findUnique({ where: { id: payload.sub } })
  if (!admin) {
    return NextResponse.json({ error: 'admin_not_found' }, { status: 401 })
  }

  return NextResponse.json({ admin: { id: admin.id, name: admin.name, email: admin.email } })
}
