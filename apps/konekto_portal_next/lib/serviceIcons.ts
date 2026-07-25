/**
 * Portado de apps/konekto_portal/lib/features/services/service_icons.dart —
 * mapa nome->emoji (equivalente ao nome->IconData do Material Icons, já que
 * este app não usa uma biblioteca de ícones). '❓' é o fallback pra nomes
 * desconhecidos (ex: serviço criado antes de um ícone ser removido da lista).
 */
export const SERVICE_ICON_OPTIONS: Record<string, string> = {
  room_service: '🛎️',
  spa: '💆',
  restaurant: '🍽️',
  event: '🎉',
  sports_soccer: '⚽',
  pedal_bike: '🚲',
  local_laundry_service: '🧺',
  pool: '🏊',
  fitness_center: '🏋️',
  local_bar: '🍸',
  directions_car: '🚗',
  celebration: '🎊',
  local_shipping: '🚚',
  pets: '🐾',
  child_care: '👶',
}

export function serviceIconFor(iconName: string): string {
  return SERVICE_ICON_OPTIONS[iconName] ?? '❓'
}
