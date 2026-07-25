import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    service: { findUnique: vi.fn(), findMany: vi.fn(), aggregate: vi.fn(), create: vi.fn() },
    hotelSubscription: { findUnique: vi.fn() },
    hotel: { findUnique: vi.fn() },
  },
}))
vi.mock('@/lib/translate', () => ({ autoTranslateOrNull: vi.fn().mockResolvedValue(null) }))

import { prisma } from '@/lib/prisma'
import { signStaffToken } from '@/lib/jwt'
import { GET, POST } from './route'

function postRequest(hotelId: string, token: string, body: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/services`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
    body: JSON.stringify(body),
  })
}

function getRequest(hotelId: string, token?: string): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/services`, {
    headers: token ? { authorization: `Bearer ${token}` } : {},
  })
}

async function gerenteToken(hotelId = 'hotel_1') {
  return signStaffToken({ sub: 'staff_1', hotelId, role: 'gerente', email: 'a@b.com', name: 'A' })
}

const params = Promise.resolve({ hotelId: 'hotel_1' })

const baseBody = {
  name: 'Room Service',
  slug: 'room-service',
  icon: 'room_service',
  description: 'desc',
  type: 'room_service',
  category: 'Quarto',
  moduleId: 'room_service',
}

describe('GET .../services — gating por módulo (Fase 12)', () => {
  beforeEach(() => vi.clearAllMocks())

  const svcRoomService = { id: 's1', moduleId: 'room_service', enabled: true } as never
  const svcSpaGated = { id: 's2', moduleId: 'spa', enabled: true } as never
  const svcLegacyNoModule = { id: 's3', moduleId: null, enabled: true } as never

  it('hides a service whose module the plan does not allow, from a guest (no token)', async () => {
    vi.mocked(prisma.service.findMany).mockResolvedValue([svcRoomService, svcSpaGated, svcLegacyNoModule])
    vi.mocked(prisma.hotel.findUnique).mockResolvedValue({ config: {} } as never)
    vi.mocked(prisma.hotelSubscription.findUnique).mockResolvedValue({ plan: 'essential', presetId: 'essential' } as never)

    const response = await GET(getRequest('hotel_1'), { params })
    const body = (await response.json()) as { id: string }[]

    // room_service está no preset essential; spa não está; moduleId null nunca é escondido.
    expect(body.map((s) => s.id).sort()).toEqual(['s1', 's3'])
  })

  it('a gerente of the same hotel sees every service regardless of module gating', async () => {
    vi.mocked(prisma.service.findMany).mockResolvedValue([svcRoomService, svcSpaGated, svcLegacyNoModule])
    const token = await gerenteToken()

    const response = await GET(getRequest('hotel_1', token), { params })
    const body = (await response.json()) as { id: string }[]

    expect(body).toHaveLength(3)
    // gerente não deveria nem disparar a resolução de módulos habilitados.
    expect(prisma.hotel.findUnique).not.toHaveBeenCalled()
  })
})

describe('POST .../services — validação de horário de funcionamento', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(prisma.service.findUnique).mockResolvedValue(null)
    vi.mocked(prisma.service.aggregate).mockResolvedValue({ _max: { position: null } } as never)
    // essential já permite room_service (ver PLAN_PRESETS) — cobre o caso comum;
    // os testes de gating do módulo em si ficam num describe próprio abaixo.
    vi.mocked(prisma.hotelSubscription.findUnique).mockResolvedValue({ plan: 'essential', presetId: 'essential' } as never)
  })

  it('creates a service without any operating-hours fields (legacy behavior)', async () => {
    vi.mocked(prisma.service.create).mockResolvedValue({ id: 'svc_1' } as never)
    const token = await gerenteToken()

    const response = await POST(postRequest('hotel_1', token, baseBody), { params })

    expect(response.status).toBe(201)
  })

  it('creates a service with a complete operating-hours config, including an overnight window', async () => {
    vi.mocked(prisma.service.create).mockResolvedValue({ id: 'svc_1' } as never)
    const token = await gerenteToken()

    const response = await POST(
      postRequest('hotel_1', token, {
        ...baseBody,
        operatingDaysOfWeek: [5, 6],
        operatingStartMinute: 1140,
        operatingEndMinute: 60,
      }),
      { params },
    )

    expect(response.status).toBe(201)
  })

  it('rejects operatingStartMinute set without the other required fields', async () => {
    const token = await gerenteToken()

    const response = await POST(postRequest('hotel_1', token, { ...baseBody, operatingStartMinute: 420 }), { params })

    expect(response.status).toBe(400)
    expect(prisma.service.create).not.toHaveBeenCalled()
  })

  it('rejects start === end (zero-width window)', async () => {
    const token = await gerenteToken()

    const response = await POST(
      postRequest('hotel_1', token, {
        ...baseBody,
        operatingDaysOfWeek: [1],
        operatingStartMinute: 600,
        operatingEndMinute: 600,
      }),
      { params },
    )

    expect(response.status).toBe(400)
    expect(prisma.service.create).not.toHaveBeenCalled()
  })
})

describe('POST .../services — gating por módulo (Fase 12)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(prisma.service.findUnique).mockResolvedValue(null)
    vi.mocked(prisma.service.aggregate).mockResolvedValue({ _max: { position: null } } as never)
  })

  it('rejects an unknown moduleId with 400', async () => {
    const token = await gerenteToken()
    const response = await POST(postRequest('hotel_1', token, { ...baseBody, moduleId: 'not_a_real_module' }), { params })
    expect(response.status).toBe(400)
  })

  it('rejects a moduleId the hotel plan does not allow with 403', async () => {
    vi.mocked(prisma.hotelSubscription.findUnique).mockResolvedValue({ plan: 'essential', presetId: 'essential' } as never)
    const token = await gerenteToken()

    // 'spa' não está no preset essential (ver PLAN_PRESETS.essential.moduleIds).
    const response = await POST(postRequest('hotel_1', token, { ...baseBody, type: 'activity', moduleId: 'spa' }), { params })

    expect(response.status).toBe(403)
    expect(await response.json()).toEqual({ error: 'module_not_allowed_for_plan' })
    expect(prisma.service.create).not.toHaveBeenCalled()
  })

  it('allows a moduleId the hotel plan permits', async () => {
    vi.mocked(prisma.hotelSubscription.findUnique).mockResolvedValue({ plan: 'premium', presetId: 'premium' } as never)
    vi.mocked(prisma.service.create).mockResolvedValue({ id: 'svc_1' } as never)
    const token = await gerenteToken()

    const response = await POST(postRequest('hotel_1', token, { ...baseBody, type: 'activity', moduleId: 'spa' }), { params })

    expect(response.status).toBe(201)
  })
})
