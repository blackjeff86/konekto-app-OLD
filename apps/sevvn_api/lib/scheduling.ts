// Regras de agendamento por `ServiceItem` — usado pelos endpoints de
// criação/edição de item (valida a configuração que o hotel digita), pelo
// endpoint de disponibilidade (gera a grade de horários pro hóspede) e por
// `POST /api/orders` (revalida o horário escolhido antes de criar o
// pedido). Mantido num só lugar pra não divergir entre os três.

export interface SchedulingFields {
  durationMinutes?: number | null
  capacityPerSlot?: number | null
  availableDaysOfWeek?: number[] | null
  availabilityStartMinute?: number | null
  availabilityEndMinute?: number | null
}

export type SchedulingValidationResult =
  | { ok: true }
  | { ok: false; error: string }

// `durationMinutes` é o campo "interruptor": setado = agendamento
// habilitado, e nesse caso os outros 4 campos precisam vir juntos e fazer
// sentido entre si (janela positiva, item cabe pelo menos uma vez nela).
export function validateSchedulingFields(fields: SchedulingFields): SchedulingValidationResult {
  if (fields.durationMinutes == null) {
    return { ok: true }
  }

  const { durationMinutes, capacityPerSlot, availableDaysOfWeek, availabilityStartMinute, availabilityEndMinute } =
    fields

  if (capacityPerSlot == null || availabilityStartMinute == null || availabilityEndMinute == null) {
    return { ok: false, error: 'incomplete_scheduling_config' }
  }
  if (!availableDaysOfWeek || availableDaysOfWeek.length === 0) {
    return { ok: false, error: 'incomplete_scheduling_config' }
  }
  if (availabilityEndMinute <= availabilityStartMinute) {
    return { ok: false, error: 'invalid_availability_window' }
  }
  if (durationMinutes > availabilityEndMinute - availabilityStartMinute) {
    return { ok: false, error: 'duration_exceeds_availability_window' }
  }

  return { ok: true }
}

// Horários candidatos (minutos-desde-meia-noite) dentro da janela — o
// hóspede só pode reservar exatamente um desses instantes, nunca um valor
// livre. Espaçados pela própria duração do item (sem intervalo entre um
// atendimento e o próximo).
export function generateSlotStartMinutes(fields: {
  durationMinutes: number
  availabilityStartMinute: number
  availabilityEndMinute: number
}): number[] {
  const slots: number[] = []
  for (
    let start = fields.availabilityStartMinute;
    start + fields.durationMinutes <= fields.availabilityEndMinute;
    start += fields.durationMinutes
  ) {
    slots.push(start)
  }
  return slots
}

export function minuteOfDayToTimeString(minute: number): string {
  const hours = Math.floor(minute / 60)
  const minutes = minute % 60
  return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`
}

// ISO weekday (1=segunda...7=domingo) — mesmo valor de `DateTime.weekday`
// no Dart. Usa os getters UTC pra ler o horário de parede que o cliente
// mandou (sem depender do timezone do processo Node em runtime).
export function isoWeekdayUtc(date: Date): number {
  const jsDay = date.getUTCDay() // 0=domingo...6=sábado
  return jsDay === 0 ? 7 : jsDay
}

export function minuteOfDayUtc(date: Date): number {
  return date.getUTCHours() * 60 + date.getUTCMinutes()
}

// Zera segundos/milissegundos — o "instante" de um slot é sempre um
// horário redondo por minuto (grade gerada em incrementos de
// `durationMinutes`). Sem isso, dois pedidos pro "mesmo" horário mas com
// segundos/ms diferentes (só possível batendo direto na API, o app sempre
// manda segundos=0) contariam como slots distintos pro lock e pra
// contagem de capacidade, driblando o limite.
export function canonicalizeSlotStart(date: Date): Date {
  return new Date(
    Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), date.getUTCHours(), date.getUTCMinutes(), 0, 0),
  )
}

const MAX_BOOKING_HORIZON_MS = 90 * 24 * 60 * 60 * 1000 // 90 dias

// `scheduledFor` nunca pode ser no passado nem longe demais no futuro —
// usado tanto pra item com agendamento (`isValidScheduledSlot`) quanto pra
// reserva de mesa de restaurante (sem grade de horários, mas com o mesmo
// bound de bom senso).
export function isBookableInstant(scheduledFor: Date, now: Date = new Date()): boolean {
  return scheduledFor.getTime() > now.getTime() && scheduledFor.getTime() - now.getTime() <= MAX_BOOKING_HORIZON_MS
}

// Confere se `scheduledFor` cai num dia habilitado, bate exatamente num
// slot gerado pela configuração do item, e está dentro de uma janela de
// tempo razoável (nunca no passado, nem longe demais no futuro) — usado
// tanto por `POST /api/orders` (criação) quanto por `PATCH
// /api/orders/[orderId]` (reagendamento) pra revalidar o horário antes de
// gravar.
export function isValidScheduledSlot(
  item: {
    durationMinutes: number
    availableDaysOfWeek: number[]
    availabilityStartMinute: number
    availabilityEndMinute: number
  },
  scheduledFor: Date,
  now: Date = new Date(),
): boolean {
  if (!isBookableInstant(scheduledFor, now)) {
    return false
  }
  if (!item.availableDaysOfWeek.includes(isoWeekdayUtc(scheduledFor))) {
    return false
  }
  const slots = generateSlotStartMinutes(item)
  return slots.includes(minuteOfDayUtc(scheduledFor))
}

export interface OperatingHoursFields {
  operatingDaysOfWeek?: number[] | null
  operatingStartMinute?: number | null
  operatingEndMinute?: number | null
}

// Regra "tudo ou nada", igual `validateSchedulingFields` mas sem
// duração/capacidade/"cabe na janela" — horário de funcionamento de
// `Service` inteiro pode atravessar meia-noite (ver `isWithinOperatingHours`),
// então aqui só exige que início e fim sejam diferentes, não que fim > início.
export function validateOperatingHoursFields(fields: OperatingHoursFields): SchedulingValidationResult {
  const hasAnyField =
    fields.operatingStartMinute != null || fields.operatingEndMinute != null || (fields.operatingDaysOfWeek?.length ?? 0) > 0
  if (!hasAnyField) {
    return { ok: true }
  }

  if (fields.operatingStartMinute == null || fields.operatingEndMinute == null) {
    return { ok: false, error: 'incomplete_operating_hours_config' }
  }
  if (!fields.operatingDaysOfWeek || fields.operatingDaysOfWeek.length === 0) {
    return { ok: false, error: 'incomplete_operating_hours_config' }
  }
  if (fields.operatingStartMinute === fields.operatingEndMinute) {
    return { ok: false, error: 'invalid_operating_hours_window' }
  }

  return { ok: true }
}

// `true` se não configurado (sem restrição, comportamento padrão). Senão,
// compara dia da semana ISO + minuto do dia contra a janela — com suporte
// explícito a janela que atravessa meia-noite (ex: restaurante que funciona
// das 19h às 01h): quando `operatingEndMinute <= operatingStartMinute`, o
// instante conta como dentro do horário se abriu HOJE à noite (dia
// habilitado, minuto >= início) OU se ainda está aberto da noite de ONTEM
// (dia anterior habilitado, minuto < fim).
export function isWithinOperatingHours(config: OperatingHoursFields, instant: Date): boolean {
  const { operatingDaysOfWeek, operatingStartMinute, operatingEndMinute } = config
  if (!operatingDaysOfWeek || operatingDaysOfWeek.length === 0 || operatingStartMinute == null || operatingEndMinute == null) {
    return true
  }

  const minute = minuteOfDayUtc(instant)
  const weekday = isoWeekdayUtc(instant)
  const previousWeekday = weekday === 1 ? 7 : weekday - 1

  if (operatingEndMinute > operatingStartMinute) {
    return operatingDaysOfWeek.includes(weekday) && minute >= operatingStartMinute && minute < operatingEndMinute
  }

  const openingTonight = operatingDaysOfWeek.includes(weekday) && minute >= operatingStartMinute
  const stillOpenFromLastNight = operatingDaysOfWeek.includes(previousWeekday) && minute < operatingEndMinute
  return openingTonight || stillOpenFromLastNight
}
