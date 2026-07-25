'use client'

import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react'
import type { ReactNode } from 'react'
import { apiRequest } from '@/lib/api/client'
import { staffSessionFromJson, type StaffSession } from '@/types/staffSession'
import { clearStoredToken, consumeTokenFromUrl, getStoredToken, setStoredToken } from './tokenStorage'

/**
 * Fonte única do fluxo de autenticação de staff — portado de
 * AuthRepository + StaffGate (apps/konekto_portal/lib/auth/*.dart). O login
 * em si acontece em apps/konekto_site/login.html (única tela de login real
 * do produto); este provider só consome o token que a página de login manda
 * via `?token=` na URL, ou rehidrata um token já persistido no localStorage.
 *
 * 100% client-side (localStorage, sem cookies) — ver decisão de arquitetura
 * no plano de migração.
 */

type AuthStatus = 'unknown' | 'unauthenticated' | 'authenticated'

interface AuthState {
  status: AuthStatus
  session: StaffSession | null
  errorCode: string | null
}

interface StaffMeResponse {
  staff: Parameters<typeof staffSessionFromJson>[0]
}

interface AuthContextValue extends AuthState {
  token: string | null
  signInWithToken: (token: string) => Promise<void>
  signOut: () => void
}

const AuthContext = createContext<AuthContextValue | null>(null)

async function fetchMe(token: string): Promise<StaffSession> {
  const response = await apiRequest<StaffMeResponse>('/api/auth/me', {
    token,
    errorMessage: 'Sessão inválida.',
  })
  return staffSessionFromJson(response.staff)
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<AuthState>({
    status: 'unknown',
    session: null,
    errorCode: null,
  })
  const [token, setToken] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false

    async function restoreSession() {
      consumeTokenFromUrl()
      const storedToken = getStoredToken()
      if (!storedToken) {
        if (!cancelled) setState({ status: 'unauthenticated', session: null, errorCode: null })
        return
      }
      try {
        const session = await fetchMe(storedToken)
        if (!cancelled) {
          setToken(storedToken)
          setState({ status: 'authenticated', session, errorCode: null })
        }
      } catch {
        clearStoredToken()
        if (!cancelled) {
          setState({ status: 'unauthenticated', session: null, errorCode: 'staff_not_found' })
        }
      }
    }

    void restoreSession()
    return () => {
      cancelled = true
    }
  }, [])

  const signInWithToken = useCallback(async (newToken: string) => {
    setStoredToken(newToken)
    const session = await fetchMe(newToken)
    setToken(newToken)
    setState({ status: 'authenticated', session, errorCode: null })
  }, [])

  const signOut = useCallback(() => {
    clearStoredToken()
    setToken(null)
    setState({ status: 'unauthenticated', session: null, errorCode: null })
  }, [])

  const value = useMemo<AuthContextValue>(
    () => ({ ...state, token, signInWithToken, signOut }),
    [state, token, signInWithToken, signOut],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth deve ser usado dentro de um AuthProvider')
  }
  return context
}
