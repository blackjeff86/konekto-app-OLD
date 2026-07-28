/**
 * Portado de apps/konekto_portal/lib/data/rooms_repository.dart +
 * models/room.dart. `RoomActiveStay.consumptionTotal` NÃO vem pronto da
 * API — é calculado aqui a partir dos pedidos aninhados de cada hóspede,
 * exatamente como `RoomActiveStay.fromJson` faz no Dart (client-side,
 * duplicando o cálculo do backend — problema pré-existente, replicado
 * como está, não é escopo desta migração corrigir).
 */
import { apiRequest } from './client'
import type { Room, RoomInput } from '@/types/room'

interface RawOrder {
  price?: number | null
  quantity?: number | null
}

interface RawGuest {
  orders?: RawOrder[]
}

interface RawActiveStay {
  id: string
  checkInDate: string
  checkOutDate: string
  guests?: RawGuest[]
}

interface RawRoom {
  id: string
  number: string
  description: string | null
  activeStay: RawActiveStay | null
}

function mapRoom(raw: RawRoom): Room {
  const guests = raw.activeStay?.guests ?? []
  const consumptionTotal = guests.reduce((total, guest) => {
    const guestTotal = (guest.orders ?? []).reduce((sum, order) => {
      if (order.price == null) return sum
      return sum + order.price * (order.quantity ?? 1)
    }, 0)
    return total + guestTotal
  }, 0)

  return {
    id: raw.id,
    number: raw.number,
    description: raw.description,
    activeStay: raw.activeStay
      ? {
          id: raw.activeStay.id,
          checkInDate: raw.activeStay.checkInDate,
          checkOutDate: raw.activeStay.checkOutDate,
          guestCount: guests.length,
          consumptionTotal,
        }
      : null,
  }
}

export async function listRooms(hotelId: string, token: string): Promise<Room[]> {
  const raw = await apiRequest<RawRoom[]>(`/api/hotels/${hotelId}/rooms`, {
    token,
    errorMessage: 'Falha ao carregar quartos.',
  })
  return raw.map(mapRoom)
}

export function createRoom(hotelId: string, token: string, input: RoomInput): Promise<Room> {
  const body =
    input.description == null
      ? { number: input.number }
      : { number: input.number, description: input.description }

  return apiRequest<RawRoom>(`/api/hotels/${hotelId}/rooms`, {
    method: 'POST',
    token,
    body,
    conflictMessage: 'Já existe um quarto com esse número.',
    errorMessage: 'Falha ao criar quarto.',
  }).then(mapRoom)
}

export function updateRoom(
  hotelId: string,
  roomId: string,
  token: string,
  input: RoomInput,
): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}/rooms/${roomId}`, {
    method: 'PATCH',
    token,
    body: input,
    conflictMessage: 'Já existe um quarto com esse número.',
    errorMessage: 'Falha ao atualizar quarto.',
  })
}

export function deleteRoom(hotelId: string, roomId: string, token: string): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}/rooms/${roomId}`, {
    method: 'DELETE',
    token,
    conflictMessage: 'Esse quarto já teve estadias — não pode ser removido.',
    errorMessage: 'Falha ao remover quarto.',
  })
}
