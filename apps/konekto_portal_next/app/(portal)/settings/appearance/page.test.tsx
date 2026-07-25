import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, describe, expect, it, vi } from 'vitest'
import AppearancePage from './page'

vi.mock('@/hooks/useHotelConfig', () => ({ useHotelConfig: vi.fn() }))

import { useHotelConfig } from '@/hooks/useHotelConfig'

function mockHooks(overrides: Partial<ReturnType<typeof useHotelConfig>> = {}) {
  vi.mocked(useHotelConfig).mockReturnValue({
    config: { infra: 'verde_pousada' },
    isLoading: false,
    error: null,
    updateBranding: vi.fn(),
    updatePromoImages: vi.fn(),
    updateInfra: vi.fn(),
    ...overrides,
  } as unknown as ReturnType<typeof useHotelConfig>)
}

describe('AppearancePage', () => {
  afterEach(() => vi.clearAllMocks())

  it('preselects the infra saved in the config', () => {
    mockHooks({ config: { infra: 'amara_bay' } } as never)
    render(<AppearancePage />)
    expect(screen.getByText('Prévia — Amara Bay')).toBeInTheDocument()
  })

  it('switches the preview when a different option is selected', async () => {
    mockHooks()
    render(<AppearancePage />)

    expect(screen.getByText('Prévia — Verde Pousada')).toBeInTheDocument()
    await userEvent.click(screen.getByText('Amara Bay'))
    expect(screen.getByText('Prévia — Amara Bay')).toBeInTheDocument()
  })

  it('saves the selected infra', async () => {
    const updateInfra = vi.fn().mockResolvedValue(undefined)
    mockHooks({ updateInfra })
    render(<AppearancePage />)

    await userEvent.click(screen.getByText('Amara Bay'))
    await userEvent.click(screen.getByRole('button', { name: 'Salvar' }))

    await waitFor(() => expect(updateInfra).toHaveBeenCalledWith('amara_bay'))
  })

  it('offers Casa Marechal as a third template and saves it', async () => {
    const updateInfra = vi.fn().mockResolvedValue(undefined)
    mockHooks({ updateInfra })
    render(<AppearancePage />)

    await userEvent.click(screen.getByText('Casa Marechal'))
    expect(screen.getByText('Prévia — Casa Marechal')).toBeInTheDocument()

    await userEvent.click(screen.getByRole('button', { name: 'Salvar' }))
    await waitFor(() => expect(updateInfra).toHaveBeenCalledWith('casa_marechal'))
  })
})
