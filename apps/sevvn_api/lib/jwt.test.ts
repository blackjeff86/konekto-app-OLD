import { describe, expect, it } from 'vitest'
import { signStaffToken, verifyStaffToken, type StaffTokenPayload } from './jwt'

const samplePayload: StaffTokenPayload = {
  sub: 'staff_1',
  hotelId: 'hotel_1',
  role: 'gerente',
  email: 'gerente@hotel.com',
  name: 'Gerente Teste',
}

describe('signStaffToken / verifyStaffToken', () => {
  it('round-trips the payload through sign and verify', async () => {
    const token = await signStaffToken(samplePayload)
    const verified = await verifyStaffToken(token)

    expect(verified.sub).toBe(samplePayload.sub)
    expect(verified.hotelId).toBe(samplePayload.hotelId)
    expect(verified.role).toBe(samplePayload.role)
    expect(verified.email).toBe(samplePayload.email)
    expect(verified.name).toBe(samplePayload.name)
  })

  it('rejects a tampered token', async () => {
    const token = await signStaffToken(samplePayload)
    const tampered = `${token.slice(0, -2)}xx`

    await expect(verifyStaffToken(tampered)).rejects.toThrow()
  })

  it('rejects a token signed with a different secret', async () => {
    const token = await signStaffToken(samplePayload)
    const originalSecret = process.env.JWT_SECRET
    process.env.JWT_SECRET = 'a-completely-different-secret'

    await expect(verifyStaffToken(token)).rejects.toThrow()

    process.env.JWT_SECRET = originalSecret
  })
})
