import 'dotenv/config'
import { prisma } from '../lib/prisma'

type JsonObject = Record<string, unknown>

function asObject(value: unknown): JsonObject {
  return value && typeof value === 'object' && !Array.isArray(value) ? (value as JsonObject) : {}
}

async function main() {
  const hotels = await prisma.hotel.findMany({
    select: {
      id: true,
      kind: true,
      config: true,
    },
    orderBy: { createdAt: 'asc' },
    take: 50,
  })

  console.log(
    JSON.stringify(
      hotels.map((hotel) => {
        const config = asObject(hotel.config)
        const hotelInfo = asObject(config.hotelInfo)

        return {
          id: hotel.id,
          kind: hotel.kind,
          name: typeof hotelInfo.name === 'string' ? hotelInfo.name : null,
        }
      }),
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
