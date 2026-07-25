'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { RequireAuth } from '@/components/layout/RequireAuth'
import { useAuth } from '@/lib/auth/AuthProvider'

/**
 * Rota raiz — consome `?token=` (via AuthProvider) e redireciona pra
 * /dashboard uma vez autenticado (Fase 6, tarefa 35). Sem sessão,
 * RequireAuth já cuida do redirect externo pro login.html.
 */
export default function Home() {
  const { status } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (status === 'authenticated') router.replace('/dashboard')
  }, [status, router])

  return (
    <RequireAuth>
      <main className="flex flex-1 items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-gold border-t-transparent" />
      </main>
    </RequireAuth>
  )
}
