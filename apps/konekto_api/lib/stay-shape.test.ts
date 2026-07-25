import { describe, expect, it } from 'vitest'
import { flattenStayRoomNumber } from './stay-shape'

describe('flattenStayRoomNumber', () => {
  it('replaces the nested room object with a flat roomNumber field', () => {
    const stay = { id: 'stay_1', status: 'active', room: { number: '701' } }

    const flattened = flattenStayRoomNumber(stay)

    expect(flattened).toEqual({ id: 'stay_1', status: 'active', roomNumber: '701' })
    expect(flattened).not.toHaveProperty('room')
  })

  it('preserves every other field untouched', () => {
    const stay = { id: 'stay_2', guests: ['g1', 'g2'], room: { number: '105' } }

    const flattened = flattenStayRoomNumber(stay)

    expect(flattened.guests).toEqual(['g1', 'g2'])
    expect(flattened.roomNumber).toBe('105')
  })
})
