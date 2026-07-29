import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, describe, expect, it, vi } from 'vitest'
import ModulesPage from './page'

vi.mock('@/hooks/useHotelConfig', () => ({ useHotelConfig: vi.fn() }))
vi.mock('@/hooks/useModulesCatalog', () => ({ useModulesCatalog: vi.fn() }))

import { useHotelConfig } from '@/hooks/useHotelConfig'
import { useModulesCatalog } from '@/hooks/useModulesCatalog'

const CATALOG = [
  {
    id: 'services',
    name: 'Serviços',
    description: 'Agregador dos módulos de Hospitalidade habilitados.',
    category: 'core' as const,
    icon: 'grid_view',
    placement: ['bottomNav'] as const,
    defaultOrder: 2,
    dependencies: [],
    implemented: true,
  },
  {
    id: 'restaurant',
    name: 'Restaurantes',
    description: 'Cardápio e reservas de mesa dos restaurantes do hotel.',
    category: 'hospitalidade' as const,
    icon: 'restaurant',
    placement: ['servicesMenu'] as const,
    defaultOrder: 1,
    dependencies: ['services'],
    implemented: true,
    configSchemaId: 'restaurant',
  },
  {
    id: 'digital_wallet',
    name: 'Carteira Digital',
    description: 'Saldo e extrato de consumo do hóspede.',
    category: 'financeiro' as const,
    icon: 'account_balance_wallet',
    placement: ['home'] as const,
    defaultOrder: 0,
    dependencies: [],
    implemented: true,
    configSchemaId: 'digital_wallet',
  },
  {
    id: 'interactive_map',
    name: 'Mapa Interativo',
    description: 'Mapa do hotel e instalações.',
    category: 'experiencia' as const,
    icon: 'map',
    placement: ['home'] as const,
    defaultOrder: 2,
    dependencies: [],
    implemented: false,
  },
]

function mockHooks({
  enabledModules,
  updateModuleEnabled = vi.fn(),
}: {
  enabledModules: { id: string; enabled: boolean; configuration: Record<string, unknown> }[]
  updateModuleEnabled?: ReturnType<typeof vi.fn>
}) {
  vi.mocked(useHotelConfig).mockReturnValue({
    config: { enabledModules },
    isLoading: false,
    error: null,
    updateBranding: vi.fn(),
    updatePromoImages: vi.fn(),
    updateTemplate: vi.fn(),
    updateModuleEnabled,
  } as unknown as ReturnType<typeof useHotelConfig>)

  vi.mocked(useModulesCatalog).mockReturnValue({
    modules: CATALOG,
    serviceGroups: [],
    planPresets: [],
    isLoading: false,
    error: null,
  } as unknown as ReturnType<typeof useModulesCatalog>)
}

describe('ModulesPage', () => {
  afterEach(() => vi.clearAllMocks())

  it('renders every catalog module grouped under its category', () => {
    mockHooks({
      enabledModules: [
        { id: 'services', enabled: true, configuration: {} },
        { id: 'restaurant', enabled: true, configuration: {} },
      ],
    })
    render(<ModulesPage />)

    expect(screen.getByText('Núcleo da plataforma')).toBeInTheDocument()
    expect(screen.getByText('Hospitalidade')).toBeInTheDocument()
    expect(screen.getByText('Restaurantes')).toBeInTheDocument()
  })

  it('shows a checked toggle for an enabled, plan-allowed module', () => {
    mockHooks({ enabledModules: [{ id: 'restaurant', enabled: true, configuration: {} }] })
    render(<ModulesPage />)

    expect(screen.getByRole('switch')).toHaveAttribute('aria-checked', 'true')
  })

  it('toggling a module off calls updateModuleEnabled with enabled: false', async () => {
    const updateModuleEnabled = vi.fn().mockResolvedValue(undefined)
    mockHooks({ enabledModules: [{ id: 'restaurant', enabled: true, configuration: {} }], updateModuleEnabled })
    render(<ModulesPage />)

    await userEvent.click(screen.getByRole('switch'))

    await waitFor(() => expect(updateModuleEnabled).toHaveBeenCalledWith({ moduleId: 'restaurant', enabled: false }))
  })

  it('locks a module absent from enabledModules (not allowed by the plan) with no toggle', () => {
    mockHooks({
      enabledModules: [
        { id: 'services', enabled: true, configuration: {} },
        { id: 'restaurant', enabled: true, configuration: {} },
        { id: 'interactive_map', enabled: true, configuration: {} },
      ],
    })
    render(<ModulesPage />)

    expect(screen.getByText('Carteira Digital')).toBeInTheDocument()
    // Só digital_wallet está fora de enabledModules nesta config — único
    // módulo travado (interactive_map está liberado, só não implementado).
    expect(screen.getAllByText('Disponível no Premium')).toHaveLength(1)
    // services e restaurant estão liberados e implementados — 2 switches.
    expect(screen.getAllByRole('switch')).toHaveLength(2)
  })

  it('marks a not-yet-implemented module as "Em breve" with no toggle, even if plan-allowed', () => {
    mockHooks({ enabledModules: [{ id: 'interactive_map', enabled: true, configuration: {} }] })
    render(<ModulesPage />)

    expect(screen.getByText('Mapa Interativo')).toBeInTheDocument()
    expect(screen.getByText('Em breve')).toBeInTheDocument()
    expect(screen.queryByRole('switch')).not.toBeInTheDocument()
  })

  it('shows an inline error for the row when the toggle fails, without affecting other rows', async () => {
    const updateModuleEnabled = vi.fn().mockRejectedValue(new Error('Falha ao salvar módulo.'))
    mockHooks({
      enabledModules: [
        { id: 'restaurant', enabled: true, configuration: {} },
        { id: 'services', enabled: true, configuration: {} },
      ],
      updateModuleEnabled,
    })
    render(<ModulesPage />)

    const [firstSwitch] = screen.getAllByRole('switch')
    await userEvent.click(firstSwitch)

    expect(await screen.findByText('Falha ao salvar módulo.')).toBeInTheDocument()
  })
})
