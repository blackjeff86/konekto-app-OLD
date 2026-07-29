import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { PortalSidebar } from './PortalSidebar'

vi.mock('@/lib/auth/AuthProvider', () => ({ useAuth: vi.fn() }))
vi.mock('next/navigation', () => ({ usePathname: vi.fn() }))

import { useAuth } from '@/lib/auth/AuthProvider'
import { usePathname } from 'next/navigation'

const zeroBadges = { pendingOrderCount: 0, unreadMessagesCount: 0, unreadSupportCount: 0 }

function mockAuth(role: 'gerente' | 'recepcao', signOut = vi.fn()) {
  vi.mocked(useAuth).mockReturnValue({
    session: { uid: 'u1', hotelId: 'h1', role, name: 'Ana Souza', email: 'a@a.com' },
    signOut,
  } as unknown as ReturnType<typeof useAuth>)
}

describe('PortalSidebar', () => {
  afterEach(() => vi.clearAllMocks())

  it('shows Configurações for a gerente', () => {
    mockAuth('gerente')
    vi.mocked(usePathname).mockReturnValue('/dashboard')
    render(<PortalSidebar badgeCounts={zeroBadges} />)
    expect(screen.getByText('Configurações')).toBeInTheDocument()
  })

  it('hides Configurações for recepcao', () => {
    mockAuth('recepcao')
    vi.mocked(usePathname).mockReturnValue('/dashboard')
    render(<PortalSidebar badgeCounts={zeroBadges} />)
    expect(screen.queryByText('Configurações')).not.toBeInTheDocument()
  })

  it('shows a badge with the pending order count on Pedidos', () => {
    mockAuth('gerente')
    vi.mocked(usePathname).mockReturnValue('/dashboard')
    render(<PortalSidebar badgeCounts={{ ...zeroBadges, pendingOrderCount: 3 }} />)
    expect(screen.getByText('3')).toBeInTheDocument()
  })

  it('caps the badge display at 99+', () => {
    mockAuth('gerente')
    vi.mocked(usePathname).mockReturnValue('/dashboard')
    render(<PortalSidebar badgeCounts={{ ...zeroBadges, unreadSupportCount: 150 }} />)
    expect(screen.getByText('99+')).toBeInTheDocument()
  })

  it('renders the account name/role and signs out on click', async () => {
    const signOut = vi.fn()
    mockAuth('gerente', signOut)
    vi.mocked(usePathname).mockReturnValue('/dashboard')
    render(<PortalSidebar badgeCounts={zeroBadges} />)

    expect(screen.getByText('Ana Souza')).toBeInTheDocument()
    expect(screen.getByText('Gerente')).toBeInTheDocument()

    await userEvent.click(screen.getByLabelText('Sair'))
    expect(signOut).toHaveBeenCalledTimes(1)
  })

  it('links Configurações to the branding tab', () => {
    mockAuth('gerente')
    vi.mocked(usePathname).mockReturnValue('/settings/services')
    render(<PortalSidebar badgeCounts={zeroBadges} />)
    expect(screen.getByText('Configurações').closest('a')).toHaveAttribute('href', '/settings/branding')
  })
})
