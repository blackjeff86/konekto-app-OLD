// ATENÇÃO: este script roda contra o `DATABASE_URL` configurado no `.env`
// local — hoje só existe UM banco (não há dev/prod separados), então rodar
// `npm run db:seed` sempre atinge o banco de verdade.
//
// Histórico: este script já foi responsável por semear `hotel_1`/`hotel_2`
// como instalações-demonstração dos templates antigos (Verde Pousada/Amara
// Bay). Isso não existe mais — os únicos templates são os 5 do White Label
// (Aura/Bosque/Elite/Pulse/Horizon), que não precisam de nenhum hotel
// "modelo" no banco (a prévia de cada um no portal usa print estático, ver
// public/appearance/ em konekto_portal_next). Hotéis reais nascem só pelo
// fluxo de "Novo cliente" do konekto_admin (POST /api/platform-admin/hotels),
// nunca por este seed.
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

function readJsonIfExists(filePath: string): Record<string, unknown> | null {
  if (!fs.existsSync(filePath)) return null
  return JSON.parse(fs.readFileSync(filePath, 'utf8')) as Record<string, unknown>
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

// Conta da equipe da Sevvn pro portal admin interno (`konekto_admin`) —
// sem endpoint de auto-cadastro, então a primeira conta só existe se essas
// duas env vars estiverem configuradas; sem elas, pula graciosamente (mesmo
// padrão de chave ausente já usado no projeto pra outras integrações).
async function seedPlatformAdmin(): Promise<void> {
  const email = process.env.PLATFORM_ADMIN_EMAIL
  const initialPassword = process.env.PLATFORM_ADMIN_INITIAL_PASSWORD
  if (!email || !initialPassword) {
    console.log('  platform_admins <- pulado (PLATFORM_ADMIN_EMAIL/PLATFORM_ADMIN_INITIAL_PASSWORD ausentes)')
    return
  }

  const passwordHash = await bcrypt.hash(initialPassword, 10)
  await prisma.platformAdmin.upsert({
    where: { email },
    update: {},
    create: { email, passwordHash, name: 'Sevvn Admin' },
  })
  console.log(`  platform_admins <- ${email}`)
}

async function main(): Promise<void> {
  console.log('Semeando Postgres (Neon)...')
  await seedGlobal()
  await seedPlatformAdmin()
  console.log('Concluído.')
}

main().finally(() => prisma.$disconnect())
