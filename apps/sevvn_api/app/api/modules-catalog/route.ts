import { NextResponse } from 'next/server'
import { MODULE_CATALOG, SERVICE_GROUPS } from '@/lib/module-catalog'
import { PLAN_PRESETS } from '@/lib/plan-presets'

export const runtime = 'nodejs'

/// Catálogo público de módulos — portal, konekto_admin e o app do hóspede
/// consultam este endpoint em runtime em vez de manter cópia local (ver
/// header doc de lib/module-catalog.ts). Sem dado sensível/por-hotel aqui,
/// por isso sem auth — mesma convenção de GET /api/hotels (diretório
/// público).
export async function GET() {
  return NextResponse.json({
    modules: MODULE_CATALOG,
    serviceGroups: SERVICE_GROUPS,
    planPresets: PLAN_PRESETS,
  })
}
