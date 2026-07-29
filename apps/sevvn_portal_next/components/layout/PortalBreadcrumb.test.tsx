import { render, screen } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { PortalBreadcrumb } from './PortalBreadcrumb'

vi.mock('@/hooks/useHotelConfig', () => ({ useHotelConfig: vi.fn() }))
vi.mock('next/navigation', () => ({ usePathname: vi.fn() }))

import { useHotelConfig } from '@/hooks/useHotelConfig'
import { usePathname } from 'next/navigation'

describe('PortalBreadcrumb', () => {
  afterEach(() => vi.clearAllMocks())

  it('shows the hotel name and the current section title', () => {
    vi.mocked(useHotelConfig).mockReturnValue({
      config: { hotelInfo: { name: 'Amara Bay Resort' } },
    } as unknown as ReturnType<typeof useHotelConfig>)
    vi.mocked(usePathname).mockReturnValue('/orders')

    render(<PortalBreadcrumb />)

    expect(screen.getByText('Amara Bay Resort', { exact: false })).toBeInTheDocument()
    expect(screen.getByText('Pedidos')).toBeInTheDocument()
  })

  it('falls back to "..." while the hotel name has not loaded', () => {
    vi.mocked(useHotelConfig).mockReturnValue({ config: null } as unknown as ReturnType<typeof useHotelConfig>)
    vi.mocked(usePathname).mockReturnValue('/dashboard')

    render(<PortalBreadcrumb />)

    expect(screen.getByText('...', { exact: false })).toBeInTheDocument()
  })

  it('recognizes settings sub-routes as the Configurações section', () => {
    vi.mocked(useHotelConfig).mockReturnValue({
      config: { hotelInfo: { name: 'Amara Bay Resort' } },
    } as unknown as ReturnType<typeof useHotelConfig>)
    vi.mocked(usePathname).mockReturnValue('/settings/services/svc1')

    render(<PortalBreadcrumb />)

    expect(screen.getByText('Configurações')).toBeInTheDocument()
  })
})
