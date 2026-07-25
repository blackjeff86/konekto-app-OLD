import { prisma } from '@/lib/prisma'
import { getPlanPreset } from '@/lib/plan-presets'
import { isModuleId } from '@/lib/module-catalog'
import type { HotelPlan } from '@/app/generated/prisma/client'

interface HotelConfigShape {
  hotelInfo?: { name?: string; address?: string }
  extraModules?: string[]
  [key: string]: unknown
}

export interface HotelOverview {
  hotelId: string
  name: string
  address: string | null
  createdAt: Date
  subscription: {
    planName: string
    monthlyAmount: number | null
    status: string
    paymentStatus: string
    notes: string | null
    plan: HotelPlan
    presetId: string
  } | null
  // Módulos permitidos pelo Plan Preset — informativo pro konekto_admin
  // mostrar como "sempre ligado" (não editável) em vez de duplicar
  // PLAN_PRESETS no lado Flutter.
  allowedModules: string[]
  // Só as extras de cortesia (`Hotel.config.extraModules`) — nunca inclui
  // os do preset, pra bater exatamente com o que o PATCH de cortesia
  // espera de volta (substituição total, não união).
  extraModules: string[]
  activeGuestCount: number
  integration: {
    configured: boolean
    enabled: boolean
    lastInboundSyncAt: Date | null
    lastOutboundAt: Date | null
    lastOutboundOk: boolean | null
    lastOutboundError: string | null
  }
  unreadSupportMessages: number
}

/// Monta a visão administrativa de UM hotel — reaproveitada tanto pela
/// lista (`GET /api/platform-admin/hotels`) quanto pelo detalhamento
/// (`GET /api/platform-admin/hotels/[hotelId]`), pra não duplicar a lógica
/// de agregação em dois lugares. Nunca inclui `apiKeyHash`/`webhookSecret`
/// de `HotelIntegration` — mesmo nível de exposição do endpoint que o
/// próprio hotel usa.
export async function buildHotelOverview(hotel: { id: string; config: unknown; createdAt: Date }): Promise<HotelOverview> {
  const config = hotel.config as HotelConfigShape

  const [subscription, activeGuestCount, integration, unreadSupportMessages] = await Promise.all([
    prisma.hotelSubscription.findUnique({ where: { hotelId: hotel.id } }),
    prisma.guest.count({ where: { hotelId: hotel.id, status: 'active' } }),
    prisma.hotelIntegration.findUnique({ where: { hotelId: hotel.id } }),
    prisma.platformSupportMessage.count({ where: { hotelId: hotel.id, senderType: 'hotel', readByPlatform: false } }),
  ])

  const plan = subscription?.plan ?? 'essential'
  const presetId = subscription?.presetId ?? plan

  return {
    hotelId: hotel.id,
    name: config.hotelInfo?.name ?? hotel.id,
    address: config.hotelInfo?.address ?? null,
    createdAt: hotel.createdAt,
    subscription: subscription
      ? {
          planName: subscription.planName,
          monthlyAmount: subscription.monthlyAmount,
          status: subscription.status,
          paymentStatus: subscription.paymentStatus,
          notes: subscription.notes,
          plan,
          presetId,
        }
      : null,
    allowedModules: getPlanPreset(presetId).moduleIds,
    extraModules: (config.extraModules ?? []).filter(isModuleId),
    activeGuestCount,
    integration: {
      configured: integration !== null,
      enabled: integration?.enabled ?? false,
      lastInboundSyncAt: integration?.lastInboundSyncAt ?? null,
      lastOutboundAt: integration?.lastOutboundAt ?? null,
      lastOutboundOk: integration?.lastOutboundOk ?? null,
      lastOutboundError: integration?.lastOutboundError ?? null,
    },
    unreadSupportMessages,
  }
}
