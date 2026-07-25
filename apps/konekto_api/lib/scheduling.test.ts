import { describe, expect, it } from 'vitest'
import {
  canonicalizeSlotStart,
  generateSlotStartMinutes,
  isBookableInstant,
  isValidScheduledSlot,
  isWithinOperatingHours,
  isoWeekdayUtc,
  minuteOfDayToTimeString,
  minuteOfDayUtc,
  validateOperatingHoursFields,
  validateSchedulingFields,
} from './scheduling'

// "Agora" fixo, sempre anterior (mas dentro dos 90 dias de horizonte) às
// datas de fixture usadas nos testes abaixo (2026-07-2x) — evita que os
// testes fiquem "bomba-relógio" e comecem a falhar sozinhos quando o
// relógio real passar dessas datas.
const FIXED_NOW = new Date('2026-07-01T00:00:00Z')

describe('validateSchedulingFields', () => {
  it('accepts a fully-null config (scheduling disabled)', () => {
    expect(
      validateSchedulingFields({
        durationMinutes: null,
        capacityPerSlot: null,
        availableDaysOfWeek: null,
        availabilityStartMinute: null,
        availabilityEndMinute: null,
      }),
    ).toEqual({ ok: true })
  })

  it('accepts a complete config', () => {
    expect(
      validateSchedulingFields({
        durationMinutes: 60,
        capacityPerSlot: 1,
        availableDaysOfWeek: [2, 3, 4, 5, 6, 7],
        availabilityStartMinute: 840,
        availabilityEndMinute: 1380,
      }),
    ).toEqual({ ok: true })
  })

  it('rejects duration set without the other required fields', () => {
    const result = validateSchedulingFields({ durationMinutes: 60 })
    expect(result).toEqual({ ok: false, error: 'incomplete_scheduling_config' })
  })

  it('rejects an empty availableDaysOfWeek', () => {
    const result = validateSchedulingFields({
      durationMinutes: 60,
      capacityPerSlot: 1,
      availableDaysOfWeek: [],
      availabilityStartMinute: 840,
      availabilityEndMinute: 1380,
    })
    expect(result).toEqual({ ok: false, error: 'incomplete_scheduling_config' })
  })

  it('rejects an end time not after the start time', () => {
    const result = validateSchedulingFields({
      durationMinutes: 60,
      capacityPerSlot: 1,
      availableDaysOfWeek: [2],
      availabilityStartMinute: 900,
      availabilityEndMinute: 900,
    })
    expect(result).toEqual({ ok: false, error: 'invalid_availability_window' })
  })

  it('rejects a duration that does not fit in the availability window', () => {
    const result = validateSchedulingFields({
      durationMinutes: 120,
      capacityPerSlot: 1,
      availableDaysOfWeek: [2],
      availabilityStartMinute: 840,
      availabilityEndMinute: 900,
    })
    expect(result).toEqual({ ok: false, error: 'duration_exceeds_availability_window' })
  })
})

describe('generateSlotStartMinutes', () => {
  it('spaces slots by the duration, with no gap between the end of one and the start of the next', () => {
    const slots = generateSlotStartMinutes({ durationMinutes: 60, availabilityStartMinute: 840, availabilityEndMinute: 1380 })
    expect(slots).toEqual([840, 900, 960, 1020, 1080, 1140, 1200, 1260, 1320])
  })

  it('excludes a final partial slot that would run past the availability window', () => {
    const slots = generateSlotStartMinutes({ durationMinutes: 45, availabilityStartMinute: 0, availabilityEndMinute: 100 })
    expect(slots).toEqual([0, 45])
  })
})

describe('minuteOfDayToTimeString', () => {
  it('formats minutes-since-midnight as HH:mm', () => {
    expect(minuteOfDayToTimeString(840)).toBe('14:00')
    expect(minuteOfDayToTimeString(5)).toBe('00:05')
  })
})

describe('isoWeekdayUtc / minuteOfDayUtc', () => {
  it('reads Tuesday 14:00 UTC as ISO weekday 2 and minute 840', () => {
    const date = new Date('2026-07-21T14:00:00Z') // 2026-07-21 é uma terça-feira
    expect(isoWeekdayUtc(date)).toBe(2)
    expect(minuteOfDayUtc(date)).toBe(840)
  })

  it('reads Sunday as ISO weekday 7 (not JS Date getUTCDay 0)', () => {
    const date = new Date('2026-07-26T00:00:00Z') // 2026-07-26 é um domingo
    expect(isoWeekdayUtc(date)).toBe(7)
  })
})

describe('isValidScheduledSlot', () => {
  const item = {
    durationMinutes: 60,
    availableDaysOfWeek: [2, 3, 4, 5, 6, 7],
    availabilityStartMinute: 840,
    availabilityEndMinute: 1380,
  }

  it('accepts an exact slot boundary on an allowed day', () => {
    expect(isValidScheduledSlot(item, new Date('2026-07-21T14:00:00Z'), FIXED_NOW)).toBe(true)
  })

  it('rejects a time that does not land on a slot boundary', () => {
    expect(isValidScheduledSlot(item, new Date('2026-07-21T14:30:00Z'), FIXED_NOW)).toBe(false)
  })

  it('rejects a day of week outside availableDaysOfWeek (Monday)', () => {
    expect(isValidScheduledSlot(item, new Date('2026-07-20T14:00:00Z'), FIXED_NOW)).toBe(false)
  })

  it('rejects a time outside the availability window', () => {
    expect(isValidScheduledSlot(item, new Date('2026-07-21T23:00:00Z'), FIXED_NOW)).toBe(false)
  })

  it('rejects an instant that is not strictly in the future', () => {
    const now = new Date('2026-07-21T14:00:00Z')
    expect(isValidScheduledSlot(item, new Date('2026-07-21T14:00:00Z'), now)).toBe(false)
    expect(isValidScheduledSlot(item, new Date('2026-07-21T13:00:00Z'), now)).toBe(false)
  })

  it('rejects an instant more than 90 days in the future', () => {
    const now = new Date('2026-01-01T00:00:00Z')
    // Terça-feira, 91 dias depois de `now`.
    expect(isValidScheduledSlot(item, new Date('2026-04-02T14:00:00Z'), now)).toBe(false)
  })

  it('accepts an instant within the 90-day booking horizon', () => {
    const now = new Date('2026-01-01T00:00:00Z')
    expect(isValidScheduledSlot(item, new Date('2026-01-06T14:00:00Z'), now)).toBe(true)
  })
})

describe('canonicalizeSlotStart', () => {
  it('zeroes seconds and milliseconds while preserving the wall-clock minute', () => {
    const canonical = canonicalizeSlotStart(new Date('2026-07-21T14:00:37.512Z'))
    expect(canonical.toISOString()).toBe('2026-07-21T14:00:00.000Z')
  })
})

describe('isBookableInstant', () => {
  const now = new Date('2026-07-21T14:00:00Z')

  it('accepts an instant strictly in the future within the horizon', () => {
    expect(isBookableInstant(new Date('2026-07-21T15:00:00Z'), now)).toBe(true)
  })

  it('rejects an instant that is now or in the past', () => {
    expect(isBookableInstant(now, now)).toBe(false)
    expect(isBookableInstant(new Date('2026-07-21T13:00:00Z'), now)).toBe(false)
  })

  it('rejects an instant more than 90 days out', () => {
    expect(isBookableInstant(new Date('2026-10-21T14:00:01Z'), now)).toBe(false)
  })
})

describe('validateOperatingHoursFields', () => {
  it('accepts a fully-empty config (no restriction)', () => {
    expect(
      validateOperatingHoursFields({ operatingDaysOfWeek: [], operatingStartMinute: null, operatingEndMinute: null }),
    ).toEqual({ ok: true })
  })

  it('accepts a complete config, including an overnight window (end < start)', () => {
    expect(
      validateOperatingHoursFields({
        operatingDaysOfWeek: [5, 6],
        operatingStartMinute: 1140, // 19:00
        operatingEndMinute: 60, // 01:00 do dia seguinte
      }),
    ).toEqual({ ok: true })
  })

  it('rejects a start time set without the other required fields', () => {
    expect(validateOperatingHoursFields({ operatingStartMinute: 1140 })).toEqual({
      ok: false,
      error: 'incomplete_operating_hours_config',
    })
  })

  it('rejects days set without start/end minutes', () => {
    expect(validateOperatingHoursFields({ operatingDaysOfWeek: [1, 2] })).toEqual({
      ok: false,
      error: 'incomplete_operating_hours_config',
    })
  })

  it('rejects start === end (zero-width window)', () => {
    expect(
      validateOperatingHoursFields({ operatingDaysOfWeek: [1], operatingStartMinute: 600, operatingEndMinute: 600 }),
    ).toEqual({ ok: false, error: 'invalid_operating_hours_window' })
  })
})

describe('isWithinOperatingHours', () => {
  it('returns true when not configured at all', () => {
    expect(
      isWithinOperatingHours(
        { operatingDaysOfWeek: [], operatingStartMinute: null, operatingEndMinute: null },
        new Date('2026-07-21T03:00:00Z'),
      ),
    ).toBe(true)
  })

  describe('same-day window (room service kitchen, 07:00-23:00)', () => {
    const config = { operatingDaysOfWeek: [1, 2, 3, 4, 5, 6, 7], operatingStartMinute: 420, operatingEndMinute: 1380 }

    it('accepts an instant inside the window', () => {
      expect(isWithinOperatingHours(config, new Date('2026-07-21T14:00:00Z'))).toBe(true)
    })

    it('rejects an instant before opening', () => {
      expect(isWithinOperatingHours(config, new Date('2026-07-21T05:00:00Z'))).toBe(false)
    })

    it('rejects an instant after closing', () => {
      expect(isWithinOperatingHours(config, new Date('2026-07-21T23:30:00Z'))).toBe(false)
    })
  })

  describe('overnight window (restaurant, 19:00-01:00, Tue-Sun)', () => {
    const config = { operatingDaysOfWeek: [2, 3, 4, 5, 6, 7], operatingStartMinute: 1140, operatingEndMinute: 60 }

    it('accepts an instant right after opening tonight (Tuesday 20:00)', () => {
      expect(isWithinOperatingHours(config, new Date('2026-07-21T20:00:00Z'))).toBe(true) // terça
    })

    it('accepts an instant in the early morning still counted as last night (Wednesday 00:30)', () => {
      expect(isWithinOperatingHours(config, new Date('2026-07-22T00:30:00Z'))).toBe(true) // quarta 00:30 = ainda a "noite de terça"
    })

    it('rejects an instant right after closing (Wednesday 01:30)', () => {
      expect(isWithinOperatingHours(config, new Date('2026-07-22T01:30:00Z'))).toBe(false)
    })

    it('rejects the early morning after a day NOT in the allowed list (Tuesday 00:30, i.e. Monday night)', () => {
      // availableDaysOfWeek não inclui segunda (1) — a "noite de segunda" nunca abriu.
      expect(isWithinOperatingHours(config, new Date('2026-07-21T00:30:00Z'))).toBe(false)
    })

    it('rejects an instant in the closed daytime gap (Wednesday 12:00)', () => {
      expect(isWithinOperatingHours(config, new Date('2026-07-22T12:00:00Z'))).toBe(false)
    })
  })
})
