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
  /** Template White Label do app do hóspede (Aura/Bosque/Elite/Pulse/Horizon). */
  template?: string
  /** Derivados pelo backend a partir de `HotelSubscription.presetId` — nunca
   *  guardados em `Hotel.config`, só calculados na resposta do GET. */
  plan?: 'essential' | 'premium' | 'enterprise'
  allowedTemplates?: string[]
  /** Módulos já resolvidos (preset + extras de cortesia − desligados pelo
   *  hotel) — um módulo AUSENTE desta lista não está disponível pro plano
   *  do hotel de jeito nenhum (nem a equipe Konekto liberou como cortesia);
   *  um módulo PRESENTE com `enabled: false` está disponível mas o próprio
   *  hotel desligou. */
  enabledModules?: ResolvedHotelModule[]
}

export interface ResolvedHotelModule {
  id: string
  enabled: boolean
  configuration: Record<string, unknown>
}

export interface WifiSettings {
  networkName: string
  password: string
}
