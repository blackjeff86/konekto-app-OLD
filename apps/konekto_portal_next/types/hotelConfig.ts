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
  infra?: string
}

export interface WifiSettings {
  networkName: string
  password: string
}
