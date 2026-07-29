import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, describe, expect, it, vi } from 'vitest'
import AppearancePage from './page'

vi.mock('@/hooks/useHotelConfig', () => ({ useHotelConfig: vi.fn() }))

import { useHotelConfig } from '@/hooks/useHotelConfig'

function mockHooks(overrides: Partial<ReturnType<typeof useHotelConfig>> = {}) {
  vi.mocked(useHotelConfig).mockReturnValue({
    config: { template: 'aura', plan: 'essential', allowedTemplates: ['aura', 'bosque'] },
    isLoading: false,
    error: null,
    updateBranding: vi.fn(),
    updatePromoImages: vi.fn(),
    updateTemplate: vi.fn(),
    ...overrides,
  } as unknown as ReturnType<typeof useHotelConfig>)
}

describe('AppearancePage', () => {
  afterEach(() => vi.clearAllMocks())

  it('preselects the template saved in the config', () => {
    mockHooks({ config: { template: 'bosque', plan: 'essential', allowedTemplates: ['aura', 'bosque'] } } as never)
    render(<AppearancePage />)
    expect(screen.getByText('Prévia — Bosque')).toBeInTheDocument()
  })

  it('switches the preview when a different allowed option is selected', async () => {
    mockHooks()
    render(<AppearancePage />)

    expect(screen.getByText('Prévia — Aura')).toBeInTheDocument()
    await userEvent.click(screen.getByText('Bosque'))
    expect(screen.getByText('Prévia — Bosque')).toBeInTheDocument()
  })

  it('saves the selected template', async () => {
    const updateTemplate = vi.fn().mockResolvedValue(undefined)
    mockHooks({ updateTemplate })
    render(<AppearancePage />)

    await userEvent.click(screen.getByText('Bosque'))
    await userEvent.click(screen.getByRole('button', { name: 'Salvar' }))

    await waitFor(() => expect(updateTemplate).toHaveBeenCalledWith('bosque'))
  })

  it('locks premium templates for an essential-plan hotel and does not select them on click', async () => {
    mockHooks()
    render(<AppearancePage />)

    expect(screen.getAllByText('Disponível no Premium')).toHaveLength(3)
    await userEvent.click(screen.getByText('Elite'))
    expect(screen.getByText('Prévia — Aura')).toBeInTheDocument()
  })

  it('offers all 5 templates unlocked for a premium-plan hotel and saves Horizon', async () => {
    const updateTemplate = vi.fn().mockResolvedValue(undefined)
    mockHooks({
      config: { template: 'aura', plan: 'premium', allowedTemplates: ['aura', 'bosque', 'elite', 'pulse', 'horizon'] },
      updateTemplate,
    } as never)
    render(<AppearancePage />)

    expect(screen.queryByText('Disponível no Premium')).not.toBeInTheDocument()

    await userEvent.click(screen.getByText('Horizon'))
    expect(screen.getByText('Prévia — Horizon')).toBeInTheDocument()

    await userEvent.click(screen.getByRole('button', { name: 'Salvar' }))
    await waitFor(() => expect(updateTemplate).toHaveBeenCalledWith('horizon'))
  })
})
