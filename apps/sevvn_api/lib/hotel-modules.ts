export function readHotelModuleConfiguration(hotelConfig: unknown, moduleId: string): Record<string, unknown> {
  if (!hotelConfig || typeof hotelConfig !== 'object') return {}

  const config = hotelConfig as { modules?: unknown }
  if (!config.modules || typeof config.modules !== 'object') return {}

  const moduleState = (config.modules as Record<string, unknown>)[moduleId]
  if (!moduleState || typeof moduleState !== 'object') return {}

  const configuration = (moduleState as { configuration?: unknown }).configuration
  return configuration && typeof configuration === 'object' ? (configuration as Record<string, unknown>) : {}
}
