import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@vercel/blob', () => ({
  put: vi.fn(),
}))

import { put } from '@vercel/blob'
import { uploadImage } from './uploads'

const JPEG_BYTES = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46])
const PNG_BYTES = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00])
const WEBP_BYTES = new Uint8Array([
  ...[...'RIFF'].map((c) => c.charCodeAt(0)),
  0,
  0,
  0,
  0,
  ...[...'WEBP'].map((c) => c.charCodeAt(0)),
])

describe('uploadImage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('rejects a content type outside the allowlist', async () => {
    const result = await uploadImage({
      hotelId: 'hotel_1',
      contentType: 'image/svg+xml',
      bytes: new Uint8Array([1, 2, 3]),
    })

    expect(result).toEqual({ ok: false, error: 'invalid_content_type' })
    expect(put).not.toHaveBeenCalled()
  })

  it('rejects a non-image content type (e.g. an executable disguised as a file)', async () => {
    const result = await uploadImage({
      hotelId: 'hotel_1',
      contentType: 'application/octet-stream',
      bytes: new Uint8Array([1, 2, 3]),
    })

    expect(result).toEqual({ ok: false, error: 'invalid_content_type' })
    expect(put).not.toHaveBeenCalled()
  })

  it('rejects a file larger than 4MB', async () => {
    const result = await uploadImage({
      hotelId: 'hotel_1',
      contentType: 'image/png',
      bytes: new Uint8Array(4 * 1024 * 1024 + 1),
    })

    expect(result).toEqual({ ok: false, error: 'file_too_large' })
    expect(put).not.toHaveBeenCalled()
  })

  it('rejects bytes that do not match the declared content type (spoofed label)', async () => {
    // Rótulo diz JPEG, mas o conteúdo é texto puro — exatamente o cenário
    // de alguém batendo direto na API driblando o app.
    const fakeBytes = new TextEncoder().encode('<html><script>alert(1)</script></html>')

    const result = await uploadImage({ hotelId: 'hotel_1', contentType: 'image/jpeg', bytes: fakeBytes })

    expect(result).toEqual({ ok: false, error: 'invalid_content_type' })
    expect(put).not.toHaveBeenCalled()
  })

  it('rejects bytes matching a DIFFERENT image format than the one declared', async () => {
    const result = await uploadImage({ hotelId: 'hotel_1', contentType: 'image/jpeg', bytes: PNG_BYTES })

    expect(result).toEqual({ ok: false, error: 'invalid_content_type' })
    expect(put).not.toHaveBeenCalled()
  })

  it.each([
    ['image/jpeg', JPEG_BYTES],
    ['image/png', PNG_BYTES],
    ['image/webp', WEBP_BYTES],
  ])('accepts bytes whose signature genuinely matches %s', async (contentType, bytes) => {
    vi.mocked(put).mockResolvedValue({ url: 'https://blob.vercel-storage.com/hotels/hotel_1/abc' } as never)

    const result = await uploadImage({ hotelId: 'hotel_1', contentType, bytes })

    expect(result.ok).toBe(true)
  })

  it('uploads a valid image and returns its public URL', async () => {
    vi.mocked(put).mockResolvedValue({ url: 'https://blob.vercel-storage.com/hotels/hotel_1/abc.jpg' } as never)

    const result = await uploadImage({
      hotelId: 'hotel_1',
      contentType: 'image/jpeg',
      bytes: JPEG_BYTES,
    })

    expect(result).toEqual({ ok: true, url: 'https://blob.vercel-storage.com/hotels/hotel_1/abc.jpg' })
  })

  it('never uses the original filename — the path is always a server-generated UUID scoped to the hotel', async () => {
    vi.mocked(put).mockResolvedValue({ url: 'https://blob.vercel-storage.com/x.jpg' } as never)

    await uploadImage({ hotelId: 'hotel_1', contentType: 'image/jpeg', bytes: JPEG_BYTES })

    const [pathname, , options] = vi.mocked(put).mock.calls[0]
    expect(pathname).toMatch(/^hotels\/hotel_1\/[0-9a-f-]{36}\.jpg$/)
    expect(options).toMatchObject({ access: 'public', contentType: 'image/jpeg' })
  })
})
