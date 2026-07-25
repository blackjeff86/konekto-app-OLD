/** Portado de apps/konekto_portal/lib/data/hotel_config_repository.dart. */
import { apiRequest } from './client'
import type { HotelConfig, WifiSettings } from '@/types/hotelConfig'

export function getHotelConfig(hotelId: string): Promise<HotelConfig> {
  return apiRequest<HotelConfig>(`/api/hotels/${hotelId}`, {
    errorMessage: 'Falha ao carregar configuração do hotel.',
  })
}

export interface BrandingInput {
  name?: string | null
  logoUrl?: string | null
  address?: string | null
  primary?: string | null
  secondary?: string | null
}

export function updateBranding(hotelId: string, token: string, input: BrandingInput): Promise<void> {
  const body: Record<string, unknown> = {}
  if (input.name != null || input.logoUrl != null || input.address != null) {
    body.hotelInfo = {
      ...(input.name != null ? { name: input.name } : {}),
      ...(input.logoUrl != null ? { logoUrl: input.logoUrl } : {}),
      ...(input.address != null ? { address: input.address } : {}),
    }
  }
  if (input.primary != null || input.secondary != null) {
    body.colorPalette = {
      ...(input.primary != null ? { primary: input.primary } : {}),
      ...(input.secondary != null ? { secondary: input.secondary } : {}),
    }
  }
  return apiRequest<void>(`/api/hotels/${hotelId}`, {
    method: 'PATCH',
    token,
    body,
    errorMessage: 'Falha ao salvar configuração.',
  })
}

/**
 * Substitui a lista inteira de imagens do carrossel de destaque da home do
 * hóspede — sempre manda o array completo já editado.
 */
export function updatePromoImages(
  hotelId: string,
  token: string,
  images: string[],
  carouselHeight = 250,
): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}`, {
    method: 'PATCH',
    token,
    body: {
      hotelInfo: {
        promoImages: { images, carouselHeight, carouselEnabled: true },
      },
    },
    errorMessage: 'Falha ao salvar carrossel.',
  })
}

/**
 * Wi-Fi padrão do hotel — vive num HotelContent separado (guestInfo), não
 * no Hotel.config. 404 = ainda não configurado, não é erro.
 *
 * `guestInfo` é um doc privado no backend (`PRIVATE_DOC_NAMES` em
 * app/api/hotels/[hotelId]/content/[docName]/route.ts) — GET exige staff
 * autenticado do próprio hotel, então o token é obrigatório aqui (achado
 * durante QA manual: o Dart original chama esse GET sem token nenhum, o
 * que hoje resulta em 401 na Wi-Fi da aba Marca em produção — replicamos
 * o bug por padrão, mas como é uma correção trivial e sem risco, já
 * corrigimos aqui em vez de herdar o defeito).
 */
export async function getWifiSettings(hotelId: string, token: string): Promise<WifiSettings> {
  try {
    const data = await apiRequest<{ wifi?: { network_name?: string; password?: string } }>(
      `/api/hotels/${hotelId}/content/guestInfo`,
      { token, errorMessage: 'Falha ao carregar configuração de wifi.' },
    )
    return {
      networkName: data.wifi?.network_name ?? '',
      password: data.wifi?.password ?? '',
    }
  } catch (error) {
    if (error instanceof Error && 'status' in error && (error as { status: number }).status === 404) {
      return { networkName: '', password: '' }
    }
    throw error
  }
}

export function updateWifiSettings(
  hotelId: string,
  token: string,
  networkName: string,
  password: string,
): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}/content/guestInfo`, {
    method: 'PATCH',
    token,
    body: { data: { wifi: { network_name: networkName, password } } },
    errorMessage: 'Falha ao salvar configuração de wifi.',
  })
}

/** Infraestrutura visual do app do hóspede — legado, ver `updateTemplate`. */
export function updateInfra(hotelId: string, token: string, infra: string): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}`, {
    method: 'PATCH',
    token,
    body: { infra },
    errorMessage: 'Falha ao salvar aparência.',
  })
}

/**
 * Template White Label do app do hóspede (Aura/Bosque/Elite/Pulse/Horizon).
 * O backend valida de novo se o template está liberado pro plano do hotel
 * (403 `template_not_allowed_for_plan` se não estiver) — a restrição por
 * `allowedTemplates` na UI é só conveniência, não a única barreira.
 */
export function updateTemplate(hotelId: string, token: string, template: string): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}`, {
    method: 'PATCH',
    token,
    body: { template },
    errorMessage: 'Falha ao salvar template.',
  })
}

interface ServicesPageDoc {
  pageStyles?: { banner?: { imageUrl?: string } }
  [key: string]: unknown
}

async function getServicesPageDoc(hotelId: string): Promise<ServicesPageDoc> {
  try {
    return await apiRequest<ServicesPageDoc>(`/api/hotels/${hotelId}/content/servicesPage`, {
      errorMessage: 'Falha ao carregar configuração da página de serviços.',
    })
  } catch (error) {
    if (error instanceof Error && 'status' in error && (error as { status: number }).status === 404) {
      return {}
    }
    throw error
  }
}

/** Imagem do banner do topo da tela "Serviços" no app do hóspede. */
export async function getServicesPageBannerImageUrl(hotelId: string): Promise<string> {
  const doc = await getServicesPageDoc(hotelId)
  return doc.pageStyles?.banner?.imageUrl ?? ''
}

/**
 * Manda o doc `servicesPage` inteiro de volta (o PATCH substitui o
 * documento todo) — por isso busca o atual antes de mesclar, pra não
 * apagar outras chaves que possam existir nele.
 */
export async function updateServicesPageBannerImageUrl(
  hotelId: string,
  token: string,
  imageUrl: string,
): Promise<void> {
  const doc = await getServicesPageDoc(hotelId)
  const merged: ServicesPageDoc = {
    ...doc,
    pageStyles: { ...doc.pageStyles, banner: { ...doc.pageStyles?.banner, imageUrl } },
  }
  return apiRequest<void>(`/api/hotels/${hotelId}/content/servicesPage`, {
    method: 'PATCH',
    token,
    body: { data: merged },
    errorMessage: 'Falha ao salvar banner de serviços.',
  })
}
