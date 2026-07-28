import 'dotenv/config'
import type { Prisma } from '../app/generated/prisma/client'
import { prisma } from '../lib/prisma'

type JsonObject = Record<string, unknown>

function asObject(value: unknown): JsonObject {
  return value && typeof value === 'object' && !Array.isArray(value) ? (value as JsonObject) : {}
}

async function main() {
  const hotelId = process.argv[2] ?? 'hotel_1'

  const hotel = await prisma.hotel.findUnique({
    where: { id: hotelId },
    select: { id: true, config: true },
  })

  if (!hotel) {
    throw new Error(`Hotel ${hotelId} não encontrado.`)
  }

  const currentConfig = asObject(hotel.config)
  const currentModules = asObject(currentConfig.modules)
  const conciergeState = asObject(currentModules.concierge)
  const conciergeConfiguration = asObject(conciergeState.configuration)

  const nextConfig = {
    ...currentConfig,
    modules: {
      ...currentModules,
      concierge: {
        enabled: conciergeState.enabled !== false,
        configuration: {
          ...conciergeConfiguration,
          title: conciergeConfiguration.title ?? 'Concierge Sevvn',
          openingHours: conciergeConfiguration.openingHours ?? 'Atendimento 24 horas',
          requestCategories:
            conciergeConfiguration.requestCategories ?? [
              'Transfer',
              'Reservas externas',
              'Passeios',
              'Comemoracoes',
              'Apoio durante a estadia',
            ],
          responseSlaMinutes: conciergeConfiguration.responseSlaMinutes ?? 15,
          showEstimatedResponseTime:
            conciergeConfiguration.showEstimatedResponseTime ?? true,
          allowFileAttachments:
            conciergeConfiguration.allowFileAttachments ?? false,
          escalationMode: conciergeConfiguration.escalationMode ?? 'hybrid',
        },
      },
    },
  }

  const service = await prisma.service.upsert({
    where: {
      hotelId_slug: {
        hotelId,
        slug: 'concierge',
      },
    },
    update: {
      name: 'Concierge',
      icon: 'support_agent',
      description:
        'Atendimento personalizado para pedidos especiais, reservas, transfer e apoio ao hospede durante a estadia.',
      type: 'activity',
      category: 'Experiencias',
      moduleId: 'concierge',
      enabled: true,
      bannerImageUrl: null,
      operatingDaysOfWeek: [],
      operatingStartMinute: null,
      operatingEndMinute: null,
    },
    create: {
      hotelId,
      name: 'Concierge',
      slug: 'concierge',
      icon: 'support_agent',
      description:
        'Atendimento personalizado para pedidos especiais, reservas, transfer e apoio ao hospede durante a estadia.',
      type: 'activity',
      category: 'Experiencias',
      moduleId: 'concierge',
      position: 999,
      enabled: true,
      bannerImageUrl: null,
      operatingDaysOfWeek: [],
      operatingStartMinute: null,
      operatingEndMinute: null,
    },
  })

  await prisma.hotel.update({
    where: { id: hotelId },
    data: { config: nextConfig as Prisma.InputJsonValue },
  })

  console.log(
    JSON.stringify(
      {
        ok: true,
        hotelId,
        serviceId: service.id,
        serviceSlug: service.slug,
        moduleId: service.moduleId,
      },
      null,
      2,
    ),
  )
}

main()
  .catch((error) => {
    console.error(error)
    process.exitCode = 1
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
