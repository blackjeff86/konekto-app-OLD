import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, describe, expect, it, vi } from 'vitest'
import SupportPage from './page'

vi.mock('@/hooks/useSupport', () => ({ useSupport: vi.fn() }))

import { useSupport } from '@/hooks/useSupport'

function mockUseSupport(overrides: Partial<ReturnType<typeof useSupport>> = {}) {
  vi.mocked(useSupport).mockReturnValue({
    messages: [],
    isLoading: false,
    error: null,
    sendMessage: vi.fn(),
    ...overrides,
  } as unknown as ReturnType<typeof useSupport>)
}

describe('SupportPage', () => {
  afterEach(() => vi.clearAllMocks())

  it('shows the empty state when there are no messages', () => {
    mockUseSupport()
    render(<SupportPage />)
    expect(screen.getByText(/Nenhuma mensagem ainda/)).toBeInTheDocument()
  })

  it('renders messages from both the hotel and the platform', () => {
    mockUseSupport({
      messages: [
        { id: 'm1', senderType: 'hotel', body: 'Oi, preciso de ajuda', readByHotel: true, createdAt: '2026-07-01T00:00:00.000Z' },
        { id: 'm2', senderType: 'platform', body: 'Claro, em que posso ajudar?', readByHotel: false, createdAt: '2026-07-01T00:01:00.000Z' },
      ],
    })
    render(<SupportPage />)

    expect(screen.getByText('Oi, preciso de ajuda')).toBeInTheDocument()
    expect(screen.getByText('Claro, em que posso ajudar?')).toBeInTheDocument()
    expect(screen.getByText('Você')).toBeInTheDocument()
    expect(screen.getByText('Sevvn')).toBeInTheDocument()
  })

  it('sends a message and clears the input', async () => {
    const sendMessage = vi.fn().mockResolvedValue(undefined)
    mockUseSupport({ sendMessage })
    render(<SupportPage />)

    const textarea = screen.getByPlaceholderText('Escreva sua mensagem...')
    await userEvent.type(textarea, 'Preciso de ajuda')
    await userEvent.click(screen.getByLabelText('Enviar mensagem'))

    await waitFor(() => expect(sendMessage).toHaveBeenCalledWith('Preciso de ajuda'))
    await waitFor(() => expect(textarea).toHaveValue(''))
  })
})
