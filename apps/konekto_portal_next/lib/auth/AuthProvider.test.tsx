import { render, screen, waitFor } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { AuthProvider, useAuth } from './AuthProvider'

vi.mock('@/lib/api/client', () => ({
  apiRequest: vi.fn(),
}))
vi.mock('./tokenStorage', () => ({
  consumeTokenFromUrl: vi.fn(),
  getStoredToken: vi.fn(),
  setStoredToken: vi.fn(),
  clearStoredToken: vi.fn(),
}))

import { apiRequest } from '@/lib/api/client'
import { clearStoredToken, getStoredToken } from './tokenStorage'

function AuthProbe() {
  const { status, session, errorCode } = useAuth()
  return (
    <div>
      <span data-testid="status">{status}</span>
      <span data-testid="error-code">{errorCode ?? ''}</span>
      <span data-testid="session-name">{session?.name ?? ''}</span>
    </div>
  )
}

describe('AuthProvider', () => {
  afterEach(() => {
    vi.clearAllMocks()
  })

  it('becomes unauthenticated when there is no stored token', async () => {
    vi.mocked(getStoredToken).mockReturnValue(null)

    render(
      <AuthProvider>
        <AuthProbe />
      </AuthProvider>,
    )

    await waitFor(() => expect(screen.getByTestId('status')).toHaveTextContent('unauthenticated'))
    expect(screen.getByTestId('error-code')).toHaveTextContent('')
    expect(apiRequest).not.toHaveBeenCalled()
  })

  it('becomes authenticated when a stored token resolves against /api/auth/me', async () => {
    vi.mocked(getStoredToken).mockReturnValue('stored-token')
    vi.mocked(apiRequest).mockResolvedValue({
      staff: { id: 'u1', hotelId: 'h1', role: 'gerente', name: 'Ana', email: 'ana@hotel.com' },
    })

    render(
      <AuthProvider>
        <AuthProbe />
      </AuthProvider>,
    )

    await waitFor(() => expect(screen.getByTestId('status')).toHaveTextContent('authenticated'))
    expect(screen.getByTestId('session-name')).toHaveTextContent('Ana')
    expect(apiRequest).toHaveBeenCalledWith('/api/auth/me', expect.objectContaining({ token: 'stored-token' }))
  })

  it('clears the token and reports staff_not_found when the stored token is no longer valid', async () => {
    vi.mocked(getStoredToken).mockReturnValue('stale-token')
    vi.mocked(apiRequest).mockRejectedValue(new Error('401'))

    render(
      <AuthProvider>
        <AuthProbe />
      </AuthProvider>,
    )

    await waitFor(() => expect(screen.getByTestId('status')).toHaveTextContent('unauthenticated'))
    expect(screen.getByTestId('error-code')).toHaveTextContent('staff_not_found')
    expect(clearStoredToken).toHaveBeenCalled()
  })
})
