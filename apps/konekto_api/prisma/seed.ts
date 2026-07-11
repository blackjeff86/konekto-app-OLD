import 'dotenv/config'
import fs from 'node:fs'
import path from 'node:path'
import bcrypt from 'bcryptjs'
import { PrismaClient, type Prisma } from '../app/generated/prisma/client'
import { PrismaNeon } from '@prisma/adapter-neon'
import { neonConfig } from '@neondatabase/serverless'
import ws from 'ws'

neonConfig.webSocketConstructor = ws

const connectionString = process.env.DATABASE_URL
if (!connectionString) {
  throw new Error('Missing required env var: DATABASE_URL')
}
const prisma = new PrismaClient({ adapter: new PrismaNeon({ connectionString }) })

const SEED_DATA_ROOT = path.join(__dirname, 'seed-data')

// Mapeia nome do arquivo JSON -> docName usado em hotels/{hotelId}/content/{docName} (Firestore antigo).
// Mantido por enquanto pras telas antigas do app do hóspede (Fase 4, ainda
// não removidas — ver tasks/plan.md Phase D) continuarem funcionando durante
// a transição pro modelo de serviços dinâmicos (Service/ServiceItem).
const CONTENT_FILES: Record<string, string> = {
  'guest_info.json': 'guestInfo',
  'services_page.json': 'servicesPage',
  'room_service_menu.json': 'roomService',
  'spa_services.json': 'spa',
  'spa_availability.json': 'spaAvailability',
  'restaurants.json': 'restaurants',
  'restaurant_availability.json': 'restaurantAvailability',
  'eventos_data.json': 'eventos',
  'event_availability.json': 'eventAvailability',
  'passeios_data.json': 'passeios',
  'passeios_availability.json': 'passeiosAvailability',
  'mapa_data.json': 'mapa',
}

interface ServiceSeedItem {
  name: string
  description: string
  price: number | null
  imageUrl: string | null
  location?: string | null
  category?: string | null
  extraInfo?: string | null
}

interface ServiceSeedDefinition {
  slug: string
  name: string
  icon: string
  description: string
  type: 'room_service' | 'restaurant' | 'activity'
  category: string
  bannerImageUrl: string | null
  items: ServiceSeedItem[]
}

function readJsonIfExists(filePath: string): Record<string, unknown> | null {
  if (!fs.existsSync(filePath)) return null
  return JSON.parse(fs.readFileSync(filePath, 'utf8')) as Record<string, unknown>
}

function slugify(value: string): string {
  return value
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '')
}

function assetPath(hotelId: string, folder: string, fileName: string): string {
  return `assets/tenant_assets/hotels/${hotelId}/images/${folder}/${fileName}`
}

function toPrice(value: unknown): number | null {
  return typeof value === 'number' ? value : null
}

function buildRoomServiceDefinition(hotelDir: string): ServiceSeedDefinition | null {
  const raw = readJsonIfExists(path.join(hotelDir, 'room_service_menu.json'))
  if (!raw) return null
  const pageConfig = raw.pageConfig as Record<string, unknown> | undefined
  const menu = (raw.menu as Array<{ category?: string; items?: Array<Record<string, unknown>> }>) ?? []

  const items: ServiceSeedItem[] = []
  for (const categoryEntry of menu) {
    for (const item of categoryEntry.items ?? []) {
      items.push({
        name: (item.name as string) ?? '',
        description: (item.description as string) ?? '',
        price: toPrice(item.price),
        imageUrl: (item.imageUrl as string) ?? null,
        category: categoryEntry.category ?? null,
        extraInfo: (item.preparationTime as string) ?? null,
      })
    }
  }

  return {
    slug: 'room-service',
    name: (pageConfig?.title as string) ?? 'Serviço de Quarto',
    icon: 'room_service',
    description: 'Cardápio de room service.',
    type: 'room_service',
    category: 'Serviço de Quarto',
    bannerImageUrl: (pageConfig?.headerImage as string) ?? null,
    items,
  }
}

function buildSpaDefinition(hotelDir: string): ServiceSeedDefinition | null {
  const raw = readJsonIfExists(path.join(hotelDir, 'spa_services.json'))
  if (!raw) return null
  const pageConfig = raw.pageConfig as Record<string, unknown> | undefined
  const spaServices = (raw.spaServices as Array<Record<string, unknown>>) ?? []

  const items: ServiceSeedItem[] = spaServices.map((item) => ({
    name: (item.name as string) ?? '',
    description: (item.description as string) ?? '',
    price: toPrice(item.price),
    imageUrl: (item.imageUrl as string) ?? null,
  }))

  return {
    slug: 'spa',
    name: (pageConfig?.title as string) ?? 'SPA',
    icon: 'spa',
    description: 'Serviços de spa.',
    type: 'activity',
    category: 'Passeio / Atividade',
    bannerImageUrl: (pageConfig?.bannerImageUrl as string) ?? null,
    items,
  }
}

function buildRestaurantDefinitions(hotelDir: string): ServiceSeedDefinition[] {
  const raw = readJsonIfExists(path.join(hotelDir, 'restaurants.json'))
  if (!raw) return []
  const restaurants = (raw.restaurants as Array<Record<string, unknown>>) ?? []

  return restaurants.map((restaurant) => {
    const menuItems = (restaurant.menuItems as Array<Record<string, unknown>>) ?? []
    return {
      slug: (restaurant.slug as string) ?? slugify((restaurant.name as string) ?? 'restaurante'),
      name: (restaurant.name as string) ?? 'Restaurante',
      icon: 'restaurant',
      description: (restaurant.description as string) ?? '',
      type: 'restaurant',
      category: 'Restaurante',
      bannerImageUrl: (restaurant.imageUrl as string) ?? null,
      items: menuItems.map((item) => ({
        name: (item.name as string) ?? '',
        description: (item.description as string) ?? '',
        price: toPrice(item.price),
        imageUrl: (item.imageUrl as string) ?? null,
      })),
    }
  })
}

function buildEventosDefinition(hotelId: string, hotelDir: string): ServiceSeedDefinition | null {
  const raw = readJsonIfExists(path.join(hotelDir, 'eventos_data.json'))
  if (!raw) return null
  const pageConfig = raw.pageConfig as Record<string, unknown> | undefined
  const eventos = (raw.eventos as Array<Record<string, unknown>>) ?? []

  const items: ServiceSeedItem[] = eventos.map((item) => ({
    name: (item.title as string) ?? '',
    description: (item.description as string) ?? '',
    price: null,
    imageUrl: item.imageFileName ? assetPath(hotelId, 'eventos', item.imageFileName as string) : null,
    location: (item.location as string) ?? null,
  }))

  return {
    slug: 'eventos',
    name: (pageConfig?.title as string) ?? 'Eventos',
    icon: 'event',
    description: 'Eventos do hotel.',
    type: 'activity',
    category: 'Passeio / Atividade',
    bannerImageUrl: (pageConfig?.bannerImageUrl as string) ?? null,
    items,
  }
}

function buildPasseiosDefinition(hotelId: string, hotelDir: string): ServiceSeedDefinition | null {
  const raw = readJsonIfExists(path.join(hotelDir, 'passeios_data.json'))
  if (!raw) return null
  const pageConfig = raw.pageConfig as Record<string, unknown> | undefined
  const passeios = (raw.passeios as Array<Record<string, unknown>>) ?? []

  const items: ServiceSeedItem[] = passeios.map((item) => ({
    name: (item.passeioTitle as string) ?? '',
    description: (item.description as string) ?? '',
    price: null,
    imageUrl: item.imageFileName ? assetPath(hotelId, 'passeios', item.imageFileName as string) : null,
    location: (item.location as string) ?? null,
  }))

  return {
    slug: 'passeios',
    name: (pageConfig?.title as string) ?? 'Passeios',
    icon: 'sports_soccer',
    description: 'Passeios e atividades locais.',
    type: 'activity',
    category: 'Passeio / Atividade',
    bannerImageUrl: (pageConfig?.bannerImageUrl as string) ?? null,
    items,
  }
}

async function seedService(hotelId: string, position: number, definition: ServiceSeedDefinition): Promise<void> {
  const service = await prisma.service.upsert({
    where: { hotelId_slug: { hotelId, slug: definition.slug } },
    update: {
      name: definition.name,
      icon: definition.icon,
      description: definition.description,
      category: definition.category,
      bannerImageUrl: definition.bannerImageUrl,
      position,
    },
    create: {
      hotelId,
      slug: definition.slug,
      name: definition.name,
      icon: definition.icon,
      description: definition.description,
      type: definition.type,
      category: definition.category,
      bannerImageUrl: definition.bannerImageUrl,
      position,
    },
  })

  // Substitui os itens do serviço inteiros a cada seed — mais simples que
  // fazer diff, e o seed só roda contra dados de teste/fixture.
  await prisma.serviceItem.deleteMany({ where: { serviceId: service.id } })
  for (let i = 0; i < definition.items.length; i++) {
    const item = definition.items[i]
    await prisma.serviceItem.create({
      data: {
        serviceId: service.id,
        name: item.name,
        description: item.description,
        price: item.price,
        imageUrl: item.imageUrl,
        location: item.location ?? null,
        category: item.category ?? null,
        extraInfo: item.extraInfo ?? null,
        position: i,
      },
    })
  }
  console.log(`  services/${definition.slug} (${definition.name}) <- ${definition.items.length} itens`)
}

async function seedServicesForHotel(hotelId: string, hotelDir: string): Promise<void> {
  const definitions: ServiceSeedDefinition[] = []

  const roomService = buildRoomServiceDefinition(hotelDir)
  if (roomService) definitions.push(roomService)

  const spa = buildSpaDefinition(hotelDir)
  if (spa) definitions.push(spa)

  definitions.push(...buildRestaurantDefinitions(hotelDir))

  const eventos = buildEventosDefinition(hotelId, hotelDir)
  if (eventos) definitions.push(eventos)

  const passeios = buildPasseiosDefinition(hotelId, hotelDir)
  if (passeios) definitions.push(passeios)

  for (let i = 0; i < definitions.length; i++) {
    await seedService(hotelId, i, definitions[i])
  }
}

async function seedHotel(hotelId: string): Promise<void> {
  const hotelDir = path.join(SEED_DATA_ROOT, hotelId)
  const tenantConfig = readJsonIfExists(path.join(hotelDir, 'tenant_config.json'))
  if (!tenantConfig) {
    console.log(`  (pulando ${hotelId}: tenant_config.json não encontrado)`)
    return
  }

  await prisma.hotel.upsert({
    where: { id: hotelId },
    update: { config: tenantConfig as unknown as Prisma.InputJsonValue },
    create: { id: hotelId, config: tenantConfig as unknown as Prisma.InputJsonValue },
  })
  console.log(`  hotels/${hotelId} <- tenant_config.json`)

  for (const [fileName, docName] of Object.entries(CONTENT_FILES)) {
    const content = readJsonIfExists(path.join(hotelDir, fileName))
    if (!content) continue
    await prisma.hotelContent.upsert({
      where: { hotelId_docName: { hotelId, docName } },
      update: { data: content as unknown as Prisma.InputJsonValue },
      create: { hotelId, docName, data: content as unknown as Prisma.InputJsonValue },
    })
    console.log(`  hotels/${hotelId}/content/${docName} <- ${fileName}`)
  }

  await seedServicesForHotel(hotelId, hotelDir)
}

async function seedGlobal(): Promise<void> {
  const promotions = readJsonIfExists(path.join(SEED_DATA_ROOT, 'promotions.json'))
  if (!promotions) return
  await prisma.brandContent.upsert({
    where: { key: 'promotions' },
    update: { data: promotions as unknown as Prisma.InputJsonValue },
    create: { key: 'promotions', data: promotions as unknown as Prisma.InputJsonValue },
  })
  console.log('  brand_content/promotions <- promotions.json')
}

async function seedTestStaff(): Promise<void> {
  const passwordHash = await bcrypt.hash('konekto123', 10)
  await prisma.staff.upsert({
    where: { email: 'gerente.teste@konekto.app' },
    update: {},
    create: {
      email: 'gerente.teste@konekto.app',
      passwordHash,
      hotelId: 'hotel_1',
      role: 'gerente',
      name: 'Gerente Teste',
    },
  })
  console.log('  staff <- gerente.teste@konekto.app (senha: konekto123)')
}

async function main(): Promise<void> {
  console.log('Semeando Postgres (Neon)...')
  await seedGlobal()
  for (const hotelId of ['hotel_1', 'hotel_2']) {
    console.log(`Hotel: ${hotelId}`)
    await seedHotel(hotelId)
  }
  await seedTestStaff()
  console.log('Concluído.')
}

main()
  .catch((error: unknown) => {
    console.error('Falha ao semear:', error)
    process.exitCode = 1
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
