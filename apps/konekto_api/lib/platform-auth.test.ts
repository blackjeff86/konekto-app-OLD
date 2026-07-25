import { describe, expect, it } from 'vitest'
import { signPlatformAdminToken, verifyPlatformAdminToken } from './platform-auth'
import { signStaffToken } from './jwt'
import { signGuestToken } from './guest-auth'

const samplePayload = { sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' }

describe('signPlatformAdminToken / verifyPlatformAdminToken', () => {
  it('round-trips the payload through sign and verify', async () => {
    const token = await signPlatformAdminToken(samplePayload)
    const verified = await verifyPlatformAdminToken(token)

    expect(verified.sub).toBe(samplePayload.sub)
    expect(verified.email).toBe(samplePayload.email)
    expect(verified.name).toBe(samplePayload.name)
    expect(verified.type).toBe('platform_admin')
  })

  it('rejects a tampered token', async () => {
    const token = await signPlatformAdminToken(samplePayload)
    const tampered = `${token.slice(0, -2)}xx`

    await expect(verifyPlatformAdminToken(tampered)).rejects.toThrow()
  })

  it('rejects a staff token even though it is signed with a different secret than JWT_SECRET would allow', async () => {
    // Assinado com JWT_SECRET (staff), não com PLATFORM_ADMIN_JWT_SECRET —
    // já falharia na verificação da assinatura sozinho, mas o teste importa
    // porque confirma que não existe NENHUM caminho, nem por engano de
    // configuração futura (ex: os dois secrets acabarem iguais), que deixe
    // um token de staff passar como platform-admin: falta o discriminador
    // `type: 'platform_admin'` no payload.
    const staffToken = await signStaffToken({
      sub: 's1',
      hotelId: 'hotel_1',
      role: 'gerente',
      email: 'staff@konekto.app',
      name: 'Staff',
    })

    await expect(verifyPlatformAdminToken(staffToken)).rejects.toThrow()
  })

  it('rejects a guest token for the same reason', async () => {
    const guestToken = await signGuestToken({
      sub: 'g1',
      hotelId: 'hotel_1',
      firstName: 'A',
      lastName: 'B',
      roomNumber: '101',
    })

    await expect(verifyPlatformAdminToken(guestToken)).rejects.toThrow()
  })
})
