/** Portado de apps/konekto_portal/lib/data/hotel_config_repository.dart. */
export interface HotelConfig {
  hotelInfo?: {
    name?: string
    logoUrl?: string
    address?: string
    promoImages?: {
      images?: string[]
      carouselHeight?: number
      carouselEnabled?: boolean
    }
  }
  colorPalette?: {
    primary?: string
    secondary?: string
  }
  /** Legado — substituído por `template` (White Label, ver Fase 4/Task 15). */
  infra?: string
  /** Template White Label do app do hóspede (Aura/Bosque/Elite/Pulse/Horizon). */
  template?: string
  /** Derivados pelo backend a partir de `HotelSubscription.plan` — nunca
   *  guardados em `Hotel.config`, só calculados na resposta do GET. */
  plan?: 'essential' | 'premium' | 'enterprise'
  allowedTemplates?: string[]
}

export interface WifiSettings {
  networkName: string
  password: string
}
