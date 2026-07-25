/** Portado de apps/konekto_portal/lib/data/support_repository.dart. */
export type SupportSenderType = 'hotel' | 'platform'

export interface SupportMessage {
  id: string
  senderType: SupportSenderType
  body: string
  readByHotel: boolean
  createdAt: string
}

export function isSupportMessageFromPlatform(message: Pick<SupportMessage, 'senderType'>): boolean {
  return message.senderType === 'platform'
}
