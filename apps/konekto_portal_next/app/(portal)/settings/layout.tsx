'use client'

import type { ReactNode } from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { useAuth } from '@/lib/auth/AuthProvider'

const SETTINGS_TABS = [
  { label: 'Marca', href: '/settings/branding' },
  { label: 'Aparência', href: '/settings/appearance' },
  { label: 'Módulos', href: '/settings/modules' },
  { label: 'Serviços', href: '/settings/services' },
  { label: 'Quartos', href: '/settings/rooms' },
  { label: 'Cupons', href: '/settings/coupons' },
  { label: 'Parceiros', href: '/settings/partners' },
  { label: 'Pagamentos', href: '/settings/payments' },
  { label: 'Integrações', href: '/settings/integrations' },
  { label: 'Equipe', href: '/settings/staff' },
]

/**
 * Shell de Configurações — portado de SettingsPage (apps/konekto_portal/
 * lib/features/settings/settings_page.dart). Só `gerente` acessa; os chips
 * de seção viram links reais, mas continuam visíveis mesmo dentro de
 * /settings/services/[serviceId] (mesmo comportamento do Flutter, onde o
 * gerenciamento de itens de um serviço não esconde os chips do nível
 * acima).
 */
export default function SettingsLayout({ children }: { children: ReactNode }) {
  const { session } = useAuth()
  const pathname = usePathname()

  if (session && session.role !== 'gerente') {
    return <p className="text-[14px] text-cream">Só gerentes têm acesso a Configurações.</p>
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap gap-2">
        {SETTINGS_TABS.map((tab) => {
          const isActive = pathname?.startsWith(tab.href) ?? false
          return (
            <Link
              key={tab.href}
              href={tab.href}
              className="rounded-full border px-3.5 py-1.5 text-[12.5px]"
              style={{
                borderColor: isActive ? 'var(--color-gold)' : 'var(--color-border-strong)',
                backgroundColor: isActive ? 'var(--color-gold)' : 'transparent',
                color: isActive ? 'var(--color-ink)' : 'var(--color-slate)',
                fontWeight: isActive ? 700 : 400,
              }}
            >
              {tab.label}
            </Link>
          )
        })}
      </div>
      {children}
    </div>
  )
}
