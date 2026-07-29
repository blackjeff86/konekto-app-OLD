import { NextRequest, NextResponse } from 'next/server'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'
import { uploadImage } from '@/lib/uploads'

export const runtime = 'nodejs'

// Upload de imagem (logo, carrossel, banner de Serviços, item do
// cardápio, cupom) — mesmo nível de acesso das telas que usam isso, todas
// dentro de Configurações/Serviços (gerente-only).
export async function POST(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params

  let staff
  try {
    staff = await requireStaffRole(request, ['gerente'])
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }
  if (staff.hotelId !== hotelId) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 })
  }

  const formData = await request.formData().catch(() => null)
  const file = formData?.get('file')
  if (!file || typeof file === 'string') {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const bytes = new Uint8Array(await file.arrayBuffer())
  const result = await uploadImage({ hotelId, contentType: file.type, bytes })
  if (!result.ok) {
    const status = result.error === 'file_too_large' ? 413 : 415
    return NextResponse.json({ error: result.error }, { status })
  }

  return NextResponse.json({ url: result.url }, { status: 201 })
}
