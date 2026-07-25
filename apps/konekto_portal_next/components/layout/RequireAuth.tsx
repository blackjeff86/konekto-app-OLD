'use client'

import { useEffect } from 'react'
import type { ReactNode } from 'react'
import { useAuth } from '@/lib/auth/AuthProvider'
import { siteLoginUrl } from '@/lib/siteConfig'

/**
 * Gate de autenticação client-side — portado de StaffGate +
 * RedirectToLoginPage (apps/konekto_portal/lib/auth/staff_gate.dart,
 * lib/features/login/redirect_to_login_page.dart).
 *
 * Como o auth é só localStorage, middleware.ts do Next (que só enxerga
 * cookies/headers) não protege rota no servidor — este componente client
 * é o único gate real.
 */
export function RequireAuth({ children }: { children: ReactNode }) {
  const { status, errorCode } = useAuth()

  useEffect(() => {
    if (status !== 'unauthenticated') return

    const url = new URL(siteLoginUrl)
    if (errorCode) url.searchParams.set('error', errorCode)
    window.location.href = url.toString()
  }, [status, errorCode])

  if (status === 'authenticated') {
    return <>{children}</>
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-page">
      <div className="flex flex-col items-center gap-4">
        <div
          className="h-8 w-8 animate-spin rounded-full border-2 border-gold border-t-transparent"
          role="status"
          aria-label="Carregando"
        />
        {status === 'unauthenticated' && (
          <p className="text-sm text-slate">Redirecionando para o login...</p>
        )}
      </div>
    </div>
  )
}
