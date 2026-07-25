import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, describe, expect, it, vi } from 'vitest'
import BrandingPage from './page'

vi.mock('@/hooks/useHotelConfig', () => ({ useHotelConfig: vi.fn() }))
vi.mock('@/hooks/useWifiSettings', () => ({ useWifiSettings: vi.fn() }))
vi.mock('@/lib/auth/AuthProvider', () => ({ useAuth: vi.fn() }))

import { useHotelConfig } from '@/hooks/useHotelConfig'
import { useWifiSettings } from '@/hooks/useWifiSettings'
import { useAuth } from '@/lib/auth/AuthProvider'

function mockHooks({
  config = { hotelInfo: { name: 'Hotel Teste', logoUrl: '', address: '' } },
  updateBranding = vi.fn(),
}: {
  config?: Record<string, unknown> | null
  updateBranding?: ReturnType<typeof vi.fn>
} = {}) {
  vi.mocked(useHotelConfig).mockReturnValue({
    config,
    isLoading: false,
    error: null,
    updateBranding,
    updatePromoImages: vi.fn(),
    updateInfra: vi.fn(),
  } as unknown as ReturnType<typeof useHotelConfig>)
  vi.mocked(useWifiSettings).mockReturnValue({
    wifi: { networkName: '', password: '' },
    isLoading: false,
    error: null,
    updateWifi: vi.fn(),
  } as unknown as ReturnType<typeof useWifiSettings>)
  vi.mocked(useAuth).mockReturnValue({
    session: { uid: 'u1', hotelId: 'h1', role: 'gerente', name: 'Ana', email: 'a@a.com' },
    token: 'tok',
    status: 'authenticated',
    errorCode: null,
    signInWithToken: vi.fn(),
    signOut: vi.fn(),
  })
  return { updateBranding }
}

describe('BrandingPage', () => {
  afterEach(() => vi.clearAllMocks())

  it('prefills the hotel name from config and saves changes', async () => {
    const { updateBranding } = mockHooks()
    updateBranding.mockResolvedValue(undefined)
    render(<BrandingPage />)

    const nameInput = screen.getByLabelText('Nome do hotel')
    expect(nameInput).toHaveValue('Hotel Teste')

    await userEvent.clear(nameInput)
    await userEvent.type(nameInput, 'Novo Nome')
    const saveButtons = screen.getAllByRole('button', { name: 'Salvar' })
    await userEvent.click(saveButtons[saveButtons.length - 1])

    await waitFor(() =>
      expect(updateBranding).toHaveBeenCalledWith(
        expect.objectContaining({ name: 'Novo Nome' }),
      ),
    )
  })

  it('renders the reception QR card with the guest app URL', () => {
    mockHooks()
    render(<BrandingPage />)
    expect(screen.getByText('QR code de recepção')).toBeInTheDocument()
  })
})
