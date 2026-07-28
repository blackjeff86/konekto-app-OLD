import { render, screen, waitFor } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { RequireAuth } from './RequireAuth'

vi.mock('@/lib/auth/AuthProvider', () => ({
  useAuth: vi.fn(),
}))

import { useAuth } from '@/lib/auth/AuthProvider'

function stubLocation() {
  const original = window.location
  // jsdom doesn't implement real navigation; replace with a plain writable stub
  // so we can assert on the href the component tried to navigate to.
  Object.defineProperty(window, 'location', {
    writable: true,
    value: { href: '' },
  })
  return () => {
    Object.defineProperty(window, 'location', { writable: true, value: original })
  }
}

describe('RequireAuth', () => {
  let restoreLocation: () => void

  beforeEach(() => {
    restoreLocation = stubLocation()
  })

  afterEach(() => {
    restoreLocation()
    vi.clearAllMocks()
  })

  it('shows a splash spinner while auth status is unknown', () => {
    vi.mocked(useAuth).mockReturnValue({
      status: 'unknown',
      session: null,
      errorCode: null,
      token: null,
      signInWithToken: vi.fn(),
      signOut: vi.fn(),
    })

    render(
      <RequireAuth>
        <div>conteúdo protegido</div>
      </RequireAuth>,
    )

    expect(screen.getByRole('status')).toBeInTheDocument()
    expect(screen.queryByText('conteúdo protegido')).not.toBeInTheDocument()
  })

  it('renders children when authenticated', () => {
    vi.mocked(useAuth).mockReturnValue({
      status: 'authenticated',
      session: { uid: 'u1', hotelId: 'h1', role: 'gerente', name: 'Ana', email: 'a@a.com' },
      errorCode: null,
      token: 'tok',
      signInWithToken: vi.fn(),
      signOut: vi.fn(),
    })

    render(
      <RequireAuth>
        <div>conteúdo protegido</div>
      </RequireAuth>,
    )

    expect(screen.getByText('conteúdo protegido')).toBeInTheDocument()
  })

  it('hard-redirects to the site login page when unauthenticated', async () => {
    vi.mocked(useAuth).mockReturnValue({
      status: 'unauthenticated',
      session: null,
      errorCode: null,
      token: null,
      signInWithToken: vi.fn(),
      signOut: vi.fn(),
    })

    render(
      <RequireAuth>
        <div>conteúdo protegido</div>
      </RequireAuth>,
    )

    await waitFor(() =>
      expect(window.location.href).toBe('https://sevvn-site.vercel.app/login'),
    )
  })

  it('appends ?error=<code> when redirecting after an invalid stored session', async () => {
    vi.mocked(useAuth).mockReturnValue({
      status: 'unauthenticated',
      session: null,
      errorCode: 'staff_not_found',
      token: null,
      signInWithToken: vi.fn(),
      signOut: vi.fn(),
    })

    render(
      <RequireAuth>
        <div>conteúdo protegido</div>
      </RequireAuth>,
    )

    await waitFor(() =>
      expect(window.location.href).toBe(
        'https://sevvn-site.vercel.app/login?error=staff_not_found',
      ),
    )
  })
})
