import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { enforceRateLimit } from '@/lib/rate-limit'
import { withRequestLogging } from '@/lib/request-logging'

export const runtime = 'nodejs'

interface HotelConfigShape {
  hotelInfo?: {
    name?: string
    logoUrl?: string
    guestSubdomain?: string
    customGuestDomain?: string
  }
  colorPalette?: {
    primary?: string
    secondary?: string
  }
  template?: string
}

interface BrandingMatch {
  hotelId: string
  hotelName: string
  logoUrl: string | null
  monogram: string
  welcomeCopy: string
  colorPalette?: {
    primary?: string
    secondary?: string
  }
  template?: string
  matchType: 'subdomain' | 'custom-domain' | 'fallback'
}

export async function GET(request: NextRequest) {
  return withRequestLogging(
    request,
    { route: '/api/public/guest-branding/resolve', surface: 'public-branding' },
    async () => {
      const rateLimited = enforceRateLimit(request, {
        bucket: 'public-guest-branding',
        max: 120,
        windowMs: 60 * 1000,
      })
      if (rateLimited) return rateLimited

      const host = sanitizeHost(request.nextUrl.searchParams.get('host'))
      if (!host) {
        return NextResponse.json(buildFallbackBranding())
      }

      const hotels = await prisma.hotel.findMany({
        select: {
          id: true,
          config: true,
        },
      })

      for (const hotel of hotels) {
        const config = (hotel.config as HotelConfigShape | null) ?? {}
        const hotelInfo = config.hotelInfo ?? {}
        const guestSubdomain = sanitizeLabel(hotelInfo.guestSubdomain)
        const customGuestDomain = sanitizeHost(hotelInfo.customGuestDomain ?? null)

        if (customGuestDomain && host === customGuestDomain) {
          return NextResponse.json(buildBranding(hotel.id, config, 'custom-domain'))
        }

        if (guestSubdomain && isHostForSubdomain(host, guestSubdomain)) {
          return NextResponse.json(buildBranding(hotel.id, config, 'subdomain'))
        }
      }

      return NextResponse.json(buildFallbackBranding())
    },
  )
}

function buildBranding(
  hotelId: string,
  config: HotelConfigShape,
  matchType: BrandingMatch['matchType'],
): BrandingMatch {
  const hotelName = normalizeHotelName(config.hotelInfo?.name)
  return {
    hotelId,
    hotelName,
    logoUrl: normalizeNullable(config.hotelInfo?.logoUrl),
    monogram: buildMonogram(hotelName),
    welcomeCopy: `Bem-vindo ao ${hotelName}. Digite o seu codigo de acesso para entrar na sua experiencia de hospedagem.`,
    colorPalette: config.colorPalette,
    template: typeof config.template === 'string' ? config.template : undefined,
    matchType,
  }
}

function buildFallbackBranding(): BrandingMatch {
  return {
    hotelId: '',
    hotelName: 'Seu hotel na Sevvn',
    logoUrl: null,
    monogram: 'S',
    welcomeCopy: 'Bem-vindo. Digite o seu codigo de acesso para entrar na sua experiencia de hospedagem.',
    matchType: 'fallback',
  }
}

function normalizeHotelName(name: string | undefined): string {
  const trimmed = name?.trim()
  return trimmed && trimmed.length > 0 ? trimmed : 'Seu hotel na Sevvn'
}

function buildMonogram(hotelName: string): string {
  const monogram = hotelName
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0])
    .join('')
    .toUpperCase()

  return monogram || 'S'
}

function sanitizeHost(host: string | null): string | null {
  if (!host) return null
  const normalized = host.trim().toLowerCase().replace(/^https?:\/\//, '').replace(/\/.*$/, '').replace(/:\d+$/, '')
  return normalized || null
}

function sanitizeLabel(value: string | undefined): string | null {
  if (!value) return null
  const normalized = value.trim().toLowerCase().replace(/[^a-z0-9-]/g, '')
  return normalized || null
}

function normalizeNullable(value: string | undefined): string | null {
  const trimmed = value?.trim()
  return trimmed && trimmed.length > 0 ? trimmed : null
}

function isHostForSubdomain(host: string, guestSubdomain: string): boolean {
  return host === `${guestSubdomain}.sevvn.app` || host === `${guestSubdomain}.vercel.app`
}
