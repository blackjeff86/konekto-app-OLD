import { describe, expect, it } from 'vitest'
import { resolveAllowedTemplates, resolveHotelModules } from './module-engine'

describe('resolveHotelModules', () => {
  it('essential preset resolves its module ids all enabled by default', () => {
    const resolved = resolveHotelModules('essential')
    const ids = resolved.map((module) => module.id)
    expect(ids).toContain('room_service')
    expect(ids).toContain('restaurant')
    expect(ids).not.toContain('digital_wallet')
    expect(resolved.every((module) => module.enabled)).toBe(true)
  })

  it('hotel can disable a module the plan allows (opt-out)', () => {
    const resolved = resolveHotelModules('essential', { restaurant: { enabled: false } })
    const restaurant = resolved.find((module) => module.id === 'restaurant')
    expect(restaurant?.enabled).toBe(false)
  })

  it('a new module added to the preset appears automatically without per-hotel migration', () => {
    // simula "módulo novo no preset" sem precisar mexer no dado do hotel:
    // basta o preset premium já incluir 'digital_wallet' — hotel sem
    // nenhuma configuração salva pra esse id ainda o recebe habilitado.
    const resolved = resolveHotelModules('premium')
    const wallet = resolved.find((module) => module.id === 'digital_wallet')
    expect(wallet?.enabled).toBe(true)
  })

  it('extraModuleIds (cortesia Konekto) adiciona módulo fora do preset sem mudar o plano', () => {
    const resolved = resolveHotelModules('essential', {}, ['interactive_map'])
    expect(resolved.some((module) => module.id === 'interactive_map')).toBe(true)
  })

  it('extraModuleIds nunca aparece se o hotel também o desligou explicitamente', () => {
    const resolved = resolveHotelModules('essential', { interactive_map: { enabled: false } }, ['interactive_map'])
    const map = resolved.find((module) => module.id === 'interactive_map')
    expect(map?.enabled).toBe(false)
  })

  it('preserves the merged configuration for a module', () => {
    const resolved = resolveHotelModules('essential', { room_service: { configuration: { title: 'Serviço de Quarto', order: 2 } } })
    const roomService = resolved.find((module) => module.id === 'room_service')
    expect(roomService?.configuration).toEqual({ title: 'Serviço de Quarto', order: 2 })
  })
})

describe('resolveAllowedTemplates', () => {
  it('essential only offers aura and bosque', () => {
    expect(resolveAllowedTemplates('essential')).toEqual(['aura', 'bosque'])
  })

  it('premium and enterprise offer all five real templates', () => {
    expect(resolveAllowedTemplates('premium')).toEqual(['aura', 'bosque', 'elite', 'pulse', 'horizon'])
    expect(resolveAllowedTemplates('enterprise')).toEqual(['aura', 'bosque', 'elite', 'pulse', 'horizon'])
  })
})
