/** Portado de apps/konekto_portal/lib/models/room.dart. */

/** Resumo da estadia ATIVA de um quarto, embutido em GET /rooms. */
export interface RoomActiveStay {
  id: string
  checkInDate: string
  checkOutDate: string
  guestCount: number
  consumptionTotal: number
}

export interface Room {
  id: string
  number: string
  description: string | null
  activeStay: RoomActiveStay | null
}

export function isRoomOccupied(room: Pick<Room, 'activeStay'>): boolean {
  return room.activeStay != null
}

export interface RoomInput {
  number: string
  description?: string | null
}
