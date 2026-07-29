'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'

/** /settings sem sub-rota redireciona pra a primeira aba (Marca) — mesmo padrão da raiz `/`. */
export default function SettingsIndexPage() {
  const router = useRouter()

  useEffect(() => {
    router.replace('/settings/branding')
  }, [router])

  return null
}
