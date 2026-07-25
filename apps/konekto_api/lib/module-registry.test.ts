import { describe, expect, it } from 'vitest'
import { MODULE_CATALOG } from './module-catalog'
import { MODULE_REGISTRY, validateModuleConfiguration } from './module-registry'

describe('module-catalog / module-registry consistency', () => {
  it('every catalog entry with a configSchemaId has a matching registry entry', () => {
    const missing = MODULE_CATALOG.filter((module) => module.configSchemaId && !MODULE_REGISTRY[module.configSchemaId]).map(
      (module) => `${module.id} -> ${module.configSchemaId}`,
    )
    expect(missing).toEqual([])
  })

  it('every implemented module either has a configSchemaId or intentionally needs no configuration', () => {
    const implementedWithoutSchema = MODULE_CATALOG.filter((module) => module.implemented && !module.configSchemaId).map((module) => module.id)
    // core navigation modules (home/services/bookings/messages/profile/hotel_info/basic_notifications)
    // são estruturais, sem configuration própria — todo o resto implementado precisa de configSchemaId.
    expect(implementedWithoutSchema.sort()).toEqual(
      ['home', 'hotel_info', 'services', 'bookings', 'messages', 'profile', 'basic_notifications'].sort(),
    )
  })
})

describe('validateModuleConfiguration', () => {
  it('accepts a valid generic_service configuration', () => {
    const result = validateModuleConfiguration('generic_service', {
      title: 'Spa',
      showOnHome: true,
      order: 1,
      capabilities: { allowsScheduling: true, acceptsOnlinePayment: false },
    })
    expect(result.success).toBe(true)
  })

  it('rejects configuration with the wrong type', () => {
    const result = validateModuleConfiguration('generic_service', { order: 'first' })
    expect(result).toEqual({ success: false, error: 'invalid_configuration' })
  })

  it('rejects an unknown module id', () => {
    const result = validateModuleConfiguration('not_a_real_module', {})
    expect(result).toEqual({ success: false, error: 'unknown_module' })
  })

  it('restaurant registers a table-booking action and capability beyond the generic set', () => {
    const entry = MODULE_REGISTRY.restaurant
    expect(entry.actions).toContain('bookTable')
    expect(entry.capabilities.some((c) => c.id === 'allowsTableBooking')).toBe(true)
  })
})
