'use client'

import type { ReactNode } from 'react'
import { RequireAuth } from '@/components/layout/RequireAuth'
import { PortalSidebar } from '@/components/layout/PortalSidebar'
import { PortalBreadcrumb } from '@/components/layout/PortalBreadcrumb'
import { useOrderNotifications } from '@/hooks/useOrderNotifications'

/**
 * Layout do shell autenticado — portado da estrutura Row(sidebar, coluna
 * de conteúdo) de DashboardPage (apps/konekto_portal/lib/features/
 * dashboard/dashboard_page.dart). O polling/notificação de pedido novo
 * (Fase 4, tarefa 23) mora aqui, sempre montado — roda independente de
 * qual seção do portal está aberta — e agora também alimenta os badges do
 * PortalSidebar.
 */
export default function PortalLayout({ children }: { children: ReactNode }) {
  const badgeCounts = useOrderNotifications()

  return (
    <RequireAuth>
      <div className="flex min-h-screen">
        <PortalSidebar badgeCounts={badgeCounts} />
        <div className="flex min-w-0 flex-1 flex-col">
          <PortalBreadcrumb />
          <div className="flex-1 p-8">{children}</div>
        </div>
      </div>
    </RequireAuth>
  )
}
