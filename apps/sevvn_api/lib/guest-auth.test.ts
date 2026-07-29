import { describe, expect, it } from 'vitest'
import { signGuestToken, verifyGuestToken, type GuestTokenPayload } from './guest-auth'

const samplePayload: GuestTokenPayload = {
  sub: 'guest_1',
  hotelId: 'hotel_1',
  firstName: 'Jefferson',
  lastName: 'Brito',
  roomNumber: '701',
}

describe('signGuestToken / verifyGuestToken', () => {
  it('round-trips the payload through sign and verify', async () => {
    const token = await signGuestToken(samplePayload)
    const verified = await verifyGuestToken(token)

    expect(verified.sub).toBe(samplePayload.sub)
    expect(verified.hotelId).toBe(samplePayload.hotelId)
    expect(verified.firstName).toBe(samplePayload.firstName)
    expect(verified.lastName).toBe(samplePayload.lastName)
    expect(verified.roomNumber).toBe(samplePayload.roomNumber)
  })

  it('rejects a tampered token', async () => {
    const token = await signGuestToken(samplePayload)
    const tampered = `${token.slice(0, -2)}xx`

    await expect(verifyGuestToken(tampered)).rejects.toThrow()
  })
})
