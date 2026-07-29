import { afterEach, describe, expect, it } from 'vitest'
import { clearStoredToken, consumeTokenFromUrl, getStoredToken, setStoredToken } from './tokenStorage'

afterEach(() => {
  window.localStorage.clear()
  window.history.replaceState(null, '', '/')
})

describe('tokenStorage', () => {
  it('stores and retrieves the token under the sevvn_portal_auth_token key', () => {
    setStoredToken('abc123')
    expect(window.localStorage.getItem('sevvn_portal_auth_token')).toBe('abc123')
    expect(getStoredToken()).toBe('abc123')
  })

  it('migrates the legacy konekto token key automatically', () => {
    window.localStorage.setItem('konekto_portal_auth_token', 'legacy-token')

    expect(getStoredToken()).toBe('legacy-token')
    expect(window.localStorage.getItem('sevvn_portal_auth_token')).toBe('legacy-token')
    expect(window.localStorage.getItem('konekto_portal_auth_token')).toBeNull()
  })

  it('clears the stored token', () => {
    setStoredToken('abc123')
    clearStoredToken()
    expect(getStoredToken()).toBeNull()
  })

  it('consumes ?token= from the URL, persists it, and strips it from the address bar', () => {
    window.history.pushState(null, '', '/?token=xyz789&other=1')

    const consumed = consumeTokenFromUrl()

    expect(consumed).toBe('xyz789')
    expect(getStoredToken()).toBe('xyz789')
    expect(window.location.search).toBe('?other=1')
  })

  it('returns null and does not touch storage when there is no token in the URL', () => {
    window.history.pushState(null, '', '/?other=1')

    const consumed = consumeTokenFromUrl()

    expect(consumed).toBeNull()
    expect(getStoredToken()).toBeNull()
  })
})
