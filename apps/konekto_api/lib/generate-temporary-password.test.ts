import { describe, expect, it } from 'vitest'
import { generateTemporaryPassword } from './generate-temporary-password'

describe('generateTemporaryPassword', () => {
  it('generates a 12-character password', () => {
    expect(generateTemporaryPassword()).toHaveLength(12)
  })

  it('never includes visually-ambiguous characters (0/O, 1/l/I)', () => {
    for (let i = 0; i < 200; i++) {
      const password = generateTemporaryPassword()
      expect(password).not.toMatch(/[0O1lI]/)
    }
  })

  it('generates different passwords on each call', () => {
    const passwords = new Set(Array.from({ length: 20 }, () => generateTemporaryPassword()))
    expect(passwords.size).toBe(20)
  })
})
