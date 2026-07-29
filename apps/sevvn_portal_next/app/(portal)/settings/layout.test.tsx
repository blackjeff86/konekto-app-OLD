import { render, screen } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import SettingsLayout from './layout'

vi.mock('@/lib/auth/AuthProvider', () => ({ useAuth: vi.fn() }))
vi.mock('next/navigation', () => ({ usePathname: vi.fn() }))

import { useAuth } from '@/lib/auth/AuthProvider'
import { usePathname } from 'next/navigation'

describe('SettingsLayout', () => {
  afterEach(() => vi.clearAllMocks())

  it('blocks recepcao with a message and no tabs', () => {
    vi.mocked(useAuth).mockReturnValue({
      session: { uid: 'u1', hotelId: 'h1', role: 'recepcao', name: 'Bia', email: 'b@b.com' },
    } as unknown as ReturnType<typeof useAuth>)
    vi.mocked(usePathname).mockReturnValue('/settings/branding')

    render(<SettingsLayout>conteúdo</SettingsLayout>)

    expect(screen.getByText('Só gerentes têm acesso a Configurações.')).toBeInTheDocument()
    expect(screen.queryByText('Marca')).not.toBeInTheDocument()
    expect(screen.queryByText('conteúdo')).not.toBeInTheDocument()
  })

  it('renders all tabs and the children for a gerente', () => {
    vi.mocked(useAuth).mockReturnValue({
      session: { uid: 'u1', hotelId: 'h1', role: 'gerente', name: 'Ana', email: 'a@a.com' },
    } as unknown as ReturnType<typeof useAuth>)
    vi.mocked(usePathname).mockReturnValue('/settings/branding')

    render(<SettingsLayout>conteúdo</SettingsLayout>)

    for (const label of ['Marca', 'Aparência', 'Módulos', 'Serviços', 'Quartos', 'Cupons', 'Parceiros', 'Pagamentos', 'Integrações', 'Equipe']) {
      expect(screen.getByText(label)).toBeInTheDocument()
    }
    expect(screen.getByText('conteúdo')).toBeInTheDocument()
  })

  it('keeps the Serviços tab active on a service detail sub-route', () => {
    vi.mocked(useAuth).mockReturnValue({
      session: { uid: 'u1', hotelId: 'h1', role: 'gerente', name: 'Ana', email: 'a@a.com' },
    } as unknown as ReturnType<typeof useAuth>)
    vi.mocked(usePathname).mockReturnValue('/settings/services/svc1')

    render(<SettingsLayout>conteúdo</SettingsLayout>)

    expect(screen.getByText('Serviços').closest('a')).toHaveAttribute('href', '/settings/services')
  })
})
