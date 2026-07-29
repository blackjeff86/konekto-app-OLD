import { describe, expect, it } from 'vitest'
import { formatDate, formatDateTime } from './date'

describe('formatDate', () => {
  it('formats using UTC components, not the local timezone', () => {
    // Regressão: getters locais (getDate/getMonth) deslocam a data em
    // fusos negativos (ex: America/Sao_Paulo) pra um dia antes.
    expect(formatDate('2026-07-01T00:00:00.000Z')).toBe('01/07/2026')
    expect(formatDate('2026-12-31T23:59:00.000Z')).toBe('31/12/2026')
  })
})

describe('formatDateTime', () => {
  it('formats the UTC time-of-day, matching the Dart app (no .toLocal() call)', () => {
    expect(formatDateTime('2026-07-02T00:00:00.000Z')).toBe('02/07/2026 00:00')
    expect(formatDateTime('2026-07-01T21:05:00.000Z')).toBe('01/07/2026 21:05')
  })
})
