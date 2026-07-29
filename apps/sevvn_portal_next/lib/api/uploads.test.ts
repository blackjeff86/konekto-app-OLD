import { afterEach, describe, expect, it, vi } from 'vitest'
import { uploadImage } from './uploads'

function mockFetch(response: { ok: boolean; status: number; body?: unknown }) {
  vi.stubGlobal(
    'fetch',
    vi.fn().mockResolvedValue({
      ok: response.ok,
      status: response.status,
      json: async () => response.body,
    } as Response),
  )
}

const file = new File(['fake-bytes'], 'logo.png', { type: 'image/png' })

describe('uploadImage', () => {
  afterEach(() => vi.unstubAllGlobals())

  it('posts multipart form data with the file and returns the uploaded url', async () => {
    mockFetch({ ok: true, status: 201, body: { url: 'https://blob.example/logo.png' } })

    const url = await uploadImage('h1', 'tok', file)

    expect(url).toBe('https://blob.example/logo.png')
    const [, init] = vi.mocked(fetch).mock.calls[0]
    expect(init?.headers).toEqual({ Authorization: 'Bearer tok' })
    expect(init?.body).toBeInstanceOf(FormData)
  })

  it('maps 415 to the unsupported-format message', async () => {
    mockFetch({ ok: false, status: 415 })
    await expect(uploadImage('h1', 'tok', file)).rejects.toMatchObject({
      message: 'Formato de imagem não suportado — use JPEG, PNG, WebP, GIF ou AVIF.',
      status: 415,
    })
  })

  it('maps 413 to the file-too-large message', async () => {
    mockFetch({ ok: false, status: 413 })
    await expect(uploadImage('h1', 'tok', file)).rejects.toMatchObject({
      message: 'Imagem muito grande — o limite é 4MB.',
      status: 413,
    })
  })
})
