import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/uploads', () => ({
  uploadImage: vi.fn(),
}))

// auth-guard.ts importa lib/stay-expiration.ts -> lib/prisma.ts a nível de
// módulo (mesmo sem essa rota usar Prisma diretamente) — sem mockar,
// DATABASE_URL ausente no ambiente de teste derruba o import.
vi.mock('@/lib/prisma', () => ({ prisma: {} }))

import { uploadImage } from '@/lib/uploads'
import { signStaffToken } from '@/lib/jwt'
import { POST } from './route'

function uploadRequest(hotelId: string, token: string | null, file: File | null): NextRequest {
  const formData = new FormData()
  if (file) formData.set('file', file)
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/uploads`, {
    method: 'POST',
    headers: token ? { authorization: `Bearer ${token}` } : {},
    body: formData,
  })
}

async function gerenteToken(hotelId = 'hotel_1') {
  return signStaffToken({ sub: 's1', hotelId, role: 'gerente', email: 'a@b.com', name: 'A' })
}

describe('POST /api/hotels/[hotelId]/uploads', () => {
  beforeEach(() => vi.clearAllMocks())

  it('rejects a recepcao token (only gerente can upload)', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'recepcao', email: 'a@b.com', name: 'A' })
    const file = new File(['abc'], 'photo.jpg', { type: 'image/jpeg' })

    const response = await POST(uploadRequest('hotel_1', token, file), { params: Promise.resolve({ hotelId: 'hotel_1' }) })

    expect(response.status).toBe(403)
  })

  it('rejects staff from a different hotel', async () => {
    const token = await gerenteToken('hotel_2')
    const file = new File(['abc'], 'photo.jpg', { type: 'image/jpeg' })

    const response = await POST(uploadRequest('hotel_1', token, file), { params: Promise.resolve({ hotelId: 'hotel_1' }) })

    expect(response.status).toBe(403)
  })

  it('rejects a request with no file', async () => {
    const token = await gerenteToken()

    const response = await POST(uploadRequest('hotel_1', token, null), { params: Promise.resolve({ hotelId: 'hotel_1' }) })

    expect(response.status).toBe(400)
    expect(uploadImage).not.toHaveBeenCalled()
  })

  it('returns 415 when uploadImage rejects the content type', async () => {
    const token = await gerenteToken()
    vi.mocked(uploadImage).mockResolvedValue({ ok: false, error: 'invalid_content_type' })
    const file = new File(['abc'], 'file.svg', { type: 'image/svg+xml' })

    const response = await POST(uploadRequest('hotel_1', token, file), { params: Promise.resolve({ hotelId: 'hotel_1' }) })

    expect(response.status).toBe(415)
  })

  it('returns 413 when uploadImage rejects the file for being too large', async () => {
    const token = await gerenteToken()
    vi.mocked(uploadImage).mockResolvedValue({ ok: false, error: 'file_too_large' })
    const file = new File(['abc'], 'photo.jpg', { type: 'image/jpeg' })

    const response = await POST(uploadRequest('hotel_1', token, file), { params: Promise.resolve({ hotelId: 'hotel_1' }) })

    expect(response.status).toBe(413)
  })

  it('returns the uploaded URL on success', async () => {
    const token = await gerenteToken()
    vi.mocked(uploadImage).mockResolvedValue({ ok: true, url: 'https://blob.vercel-storage.com/hotels/hotel_1/abc.jpg' })
    const file = new File(['abc'], 'photo.jpg', { type: 'image/jpeg' })

    const response = await POST(uploadRequest('hotel_1', token, file), { params: Promise.resolve({ hotelId: 'hotel_1' }) })

    expect(response.status).toBe(201)
    const body = await response.json()
    expect(body.url).toBe('https://blob.vercel-storage.com/hotels/hotel_1/abc.jpg')
    expect(uploadImage).toHaveBeenCalledWith(
      expect.objectContaining({ hotelId: 'hotel_1', contentType: 'image/jpeg' }),
    )
  })
})
