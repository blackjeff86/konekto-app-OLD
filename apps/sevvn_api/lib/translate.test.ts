import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const mockCreate = vi.fn()

vi.mock('@anthropic-ai/sdk', () => ({
  default: vi.fn().mockImplementation(function MockAnthropic() {
    return { messages: { create: mockCreate } }
  }),
}))

import { autoTranslateOrNull, translateFields } from './translate'

function textResponse(text: string) {
  return { content: [{ type: 'text', text }] }
}

describe('translateFields', () => {
  const originalKey = process.env.ANTHROPIC_API_KEY

  beforeEach(() => {
    vi.clearAllMocks()
    process.env.ANTHROPIC_API_KEY = 'test-key'
  })

  afterEach(() => {
    process.env.ANTHROPIC_API_KEY = originalKey
  })

  it('returns null without calling the API when there are no translatable fields', async () => {
    const result = await translateFields({ name: null, description: undefined, category: '   ' })

    expect(result).toBeNull()
    expect(mockCreate).not.toHaveBeenCalled()
  })

  it('parses a plain JSON response into Translations', async () => {
    mockCreate.mockResolvedValue(
      textResponse(
        JSON.stringify({
          en: { name: 'Orange Juice', description: 'Fresh squeezed' },
          es: { name: 'Jugo de Naranja', description: 'Recién exprimido' },
        }),
      ),
    )

    const result = await translateFields({ name: 'Suco de Laranja', description: 'Espremido na hora' })

    expect(result).toEqual({
      en: { name: 'Orange Juice', description: 'Fresh squeezed' },
      es: { name: 'Jugo de Naranja', description: 'Recién exprimido' },
    })
  })

  it('strips a markdown code fence around the JSON response', async () => {
    mockCreate.mockResolvedValue(textResponse('```json\n{"en": {"name": "Pool"}, "es": {"name": "Piscina"}}\n```'))

    const result = await translateFields({ name: 'Piscina' })

    expect(result).toEqual({ en: { name: 'Pool' }, es: { name: 'Piscina' } })
  })

  it('returns null when the response is not valid JSON', async () => {
    mockCreate.mockResolvedValue(textResponse('desculpe, não consigo ajudar com isso'))

    const result = await translateFields({ name: 'Piscina' })

    expect(result).toBeNull()
  })

  it('throws when ANTHROPIC_API_KEY is missing', async () => {
    delete process.env.ANTHROPIC_API_KEY

    await expect(translateFields({ name: 'Piscina' })).rejects.toThrow('ANTHROPIC_API_KEY')
  })
})

describe('autoTranslateOrNull', () => {
  const originalKey = process.env.ANTHROPIC_API_KEY

  beforeEach(() => {
    vi.clearAllMocks()
    process.env.ANTHROPIC_API_KEY = 'test-key'
  })

  afterEach(() => {
    process.env.ANTHROPIC_API_KEY = originalKey
  })

  it('returns null instead of throwing when ANTHROPIC_API_KEY is missing', async () => {
    delete process.env.ANTHROPIC_API_KEY

    const result = await autoTranslateOrNull({ name: 'Piscina' })

    expect(result).toBeNull()
  })

  it('returns null when the underlying API call rejects', async () => {
    mockCreate.mockRejectedValue(new Error('network error'))

    const result = await autoTranslateOrNull({ name: 'Piscina' })

    expect(result).toBeNull()
  })
})
