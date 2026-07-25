'use client'

import { useState } from 'react'
import { Modal } from '@/components/ui/Modal'
import { WeekdayChips } from '@/components/ui/WeekdayChips'
import { SERVICE_ICON_OPTIONS } from '@/lib/serviceIcons'
import {
  operatingHoursApplicable,
  serviceTypeDescription,
  serviceTypeLabel,
  type Service,
  type ServiceType,
} from '@/types/service'
import type { CreateServiceInput, OperatingHoursInput, UpdateServiceInput } from '@/lib/api/services'
import type { ModuleDefinition } from '@/types/moduleCatalog'

const NEW_CATEGORY_SENTINEL = '__new_category__'
const SERVICE_TYPES: ServiceType[] = ['room_service', 'restaurant', 'activity']

function slugify(value: string): string {
  const normalized = value.toLowerCase().trim()
  const withDashes = normalized.replace(/[^a-z0-9]+/g, '-')
  return withDashes.replace(/(^-+)|(-+$)/g, '')
}

function minuteFromTime(time: string): number {
  const [hours, minutes] = time.split(':').map(Number)
  return hours * 60 + minutes
}

function timeFromMinute(minute: number | null): string {
  if (minute == null) return ''
  const hours = Math.floor(minute / 60)
    .toString()
    .padStart(2, '0')
  const mins = (minute % 60).toString().padStart(2, '0')
  return `${hours}:${mins}`
}

interface ServiceFormDialogProps {
  existing: Service | null
  existingCategories: string[]
  /** Módulos de Hospitalidade que o plano do hotel permite (Fase 12) —
   *  só relevante ao criar (moduleId é fixado na criação, igual `type`). */
  allowedHospitalidadeModules: ModuleDefinition[]
  onClose: () => void
  onSubmitCreate: (input: CreateServiceInput) => Promise<void>
  onSubmitUpdate: (input: UpdateServiceInput) => Promise<void>
}

/** Portado de _ServiceFormDialog (apps/konekto_portal/lib/features/services/services_list_page.dart). */
export function ServiceFormDialog({
  existing,
  existingCategories,
  allowedHospitalidadeModules,
  onClose,
  onSubmitCreate,
  onSubmitUpdate,
}: ServiceFormDialogProps) {
  const [name, setName] = useState(existing?.name ?? '')
  const [description, setDescription] = useState(existing?.description ?? '')
  const [icon, setIcon] = useState(existing?.icon ?? Object.keys(SERVICE_ICON_OPTIONS)[0])
  const [type, setType] = useState<ServiceType>(existing?.type ?? 'activity')
  const [moduleId, setModuleId] = useState(allowedHospitalidadeModules[0]?.id ?? '')
  const categoryIsKnown = existing != null && existingCategories.includes(existing.category)
  const [selectedCategory, setSelectedCategory] = useState(
    existing != null
      ? categoryIsKnown
        ? existing.category
        : NEW_CATEGORY_SENTINEL
      : existingCategories[0] ?? NEW_CATEGORY_SENTINEL,
  )
  const [newCategory, setNewCategory] = useState(existing != null && !categoryIsKnown ? existing.category : '')

  const applicable = operatingHoursApplicable(existing?.type ?? type)
  const [hoursEnabled, setHoursEnabled] = useState(existing?.operatingStartMinute != null)
  const [start, setStart] = useState(timeFromMinute(existing?.operatingStartMinute ?? null))
  const [end, setEnd] = useState(timeFromMinute(existing?.operatingEndMinute ?? null))
  const [selectedDays, setSelectedDays] = useState<Set<number>>(
    new Set(existing?.operatingDaysOfWeek ?? []),
  )

  const [errorMessage, setErrorMessage] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)

  function toggleDay(day: number) {
    setSelectedDays((current) => {
      const next = new Set(current)
      if (next.has(day)) next.delete(day)
      else next.add(day)
      return next
    })
  }

  async function handleSubmit() {
    const trimmedName = name.trim()
    const category = selectedCategory === NEW_CATEGORY_SENTINEL ? newCategory.trim() : selectedCategory
    if (!trimmedName) {
      setErrorMessage('Informe o nome do serviço.')
      return
    }
    if (!category) {
      setErrorMessage('Informe a categoria do serviço.')
      return
    }
    if (existing == null && !moduleId) {
      setErrorMessage('Selecione o módulo deste serviço.')
      return
    }

    let operatingHours: OperatingHoursInput | undefined
    if (applicable && hoursEnabled) {
      if (selectedDays.size === 0) {
        setErrorMessage('Selecione pelo menos um dia da semana.')
        return
      }
      if (!start || !end) {
        setErrorMessage('Informe o horário de início e fim.')
        return
      }
      const startMinute = minuteFromTime(start)
      const endMinute = minuteFromTime(end)
      if (startMinute === endMinute) {
        setErrorMessage('O horário de início e fim não podem ser iguais.')
        return
      }
      operatingHours = {
        operatingDaysOfWeek: [...selectedDays].sort((a, b) => a - b),
        operatingStartMinute: startMinute,
        operatingEndMinute: endMinute,
      }
    }

    setIsSubmitting(true)
    setErrorMessage(null)
    try {
      if (existing == null) {
        await onSubmitCreate({
          name: trimmedName,
          slug: slugify(trimmedName),
          icon,
          description: description.trim(),
          type,
          category,
          moduleId,
          operatingHours,
        })
      } else {
        await onSubmitUpdate({
          name: trimmedName,
          icon,
          description: description.trim(),
          category,
          ...(applicable
            ? { operatingHours: operatingHours ?? { operatingDaysOfWeek: [], operatingStartMinute: null, operatingEndMinute: null } }
            : {}),
        })
      }
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : 'Falha ao salvar serviço.')
      setIsSubmitting(false)
    }
  }

  return (
    <Modal
      title={existing ? 'Editar serviço' : 'Criar serviço'}
      onClose={onClose}
      footer={
        <>
          <button type="button" onClick={onClose} className="text-sm text-slate">
            Cancelar
          </button>
          <button
            type="button"
            onClick={handleSubmit}
            disabled={isSubmitting}
            className="text-sm font-semibold text-gold-light disabled:opacity-60"
          >
            Salvar
          </button>
        </>
      }
    >
      <div className="flex flex-col gap-3">
        {errorMessage && (
          <div className="rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
            {errorMessage}
          </div>
        )}

        {existing == null && (
          <div>
            <p className="mb-1.5 text-xs text-slate">Comportamento no app do hóspede</p>
            <div className="flex flex-wrap gap-2">
              {SERVICE_TYPES.map((option) => (
                <button
                  key={option}
                  type="button"
                  onClick={() => setType(option)}
                  className="rounded-full border px-3 py-1.5 text-[12.5px]"
                  style={{
                    borderColor: type === option ? 'var(--color-gold)' : 'var(--color-border-strong)',
                    backgroundColor: type === option ? 'var(--color-gold)' : 'transparent',
                    color: type === option ? 'var(--color-ink)' : 'var(--color-slate)',
                    fontWeight: type === option ? 700 : 400,
                  }}
                >
                  {serviceTypeLabel[option]}
                </button>
              ))}
            </div>
            <p className="mt-1.5 text-[11.5px] text-slate">{serviceTypeDescription[type]}</p>
          </div>
        )}

        {existing == null && (
          <label className="text-xs text-slate">
            Módulo
            {allowedHospitalidadeModules.length === 0 ? (
              <p className="mt-1 text-[12.5px] text-cream">
                Nenhum módulo de Hospitalidade liberado pro plano deste hotel ainda.
              </p>
            ) : (
              <select
                value={moduleId}
                onChange={(event) => setModuleId(event.target.value)}
                className="mt-1 block w-full rounded-[10px] border border-border-strong bg-transparent px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
              >
                {allowedHospitalidadeModules.map((module) => (
                  <option key={module.id} value={module.id}>
                    {module.name}
                  </option>
                ))}
              </select>
            )}
            <p className="mt-1.5 text-[11.5px] text-slate">
              Controla se este serviço pode ser desligado inteiro pela tela Módulos, sem editar cada
              serviço um a um.
            </p>
          </label>
        )}

        <Field label="Nome do serviço" value={name} onChange={setName} />

        <label className="text-xs text-slate">
          Categoria
          <select
            value={selectedCategory}
            onChange={(event) => setSelectedCategory(event.target.value)}
            className="mt-1 block w-full rounded-[10px] border border-border-strong bg-transparent px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
          >
            {existingCategories.map((category) => (
              <option key={category} value={category}>
                {category}
              </option>
            ))}
            <option value={NEW_CATEGORY_SENTINEL}>+ Nova categoria</option>
          </select>
        </label>
        {selectedCategory === NEW_CATEGORY_SENTINEL && (
          <Field label="Nome da nova categoria" value={newCategory} onChange={setNewCategory} />
        )}

        <label className="text-xs text-slate">
          Ícone
          <select
            value={icon}
            onChange={(event) => setIcon(event.target.value)}
            className="mt-1 block w-full rounded-[10px] border border-border-strong bg-transparent px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
          >
            {Object.entries(SERVICE_ICON_OPTIONS).map(([name_, emoji]) => (
              <option key={name_} value={name_}>
                {emoji} {name_}
              </option>
            ))}
          </select>
        </label>

        <Field label="Descrição" value={description} onChange={setDescription} multiline />

        {applicable && (
          <div className="rounded-[10px] border border-border-strong p-3">
            <label className="flex items-center gap-2 text-[12.5px] text-cream">
              <input
                type="checkbox"
                checked={hoursEnabled}
                onChange={(event) => setHoursEnabled(event.target.checked)}
              />
              Horário de funcionamento restrito
            </label>
            {hoursEnabled && (
              <div className="mt-2.5 flex flex-col gap-2.5">
                <WeekdayChips selectedDays={selectedDays} onToggleDay={toggleDay} />
                <div className="flex gap-2.5">
                  <label className="flex-1 text-xs text-slate">
                    Início
                    <input
                      type="time"
                      value={start}
                      onChange={(event) => setStart(event.target.value)}
                      className="mt-1 block w-full rounded-[10px] border border-border-strong bg-transparent px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
                    />
                  </label>
                  <label className="flex-1 text-xs text-slate">
                    Fim
                    <input
                      type="time"
                      value={end}
                      onChange={(event) => setEnd(event.target.value)}
                      className="mt-1 block w-full rounded-[10px] border border-border-strong bg-transparent px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
                    />
                  </label>
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </Modal>
  )
}

function Field({
  label,
  value,
  onChange,
  multiline,
}: {
  label: string
  value: string
  onChange: (value: string) => void
  multiline?: boolean
}) {
  const baseClasses =
    'w-full rounded-[10px] border border-border-strong bg-transparent px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold'
  return (
    <label className="text-xs text-slate">
      {label}
      {multiline ? (
        <textarea
          value={value}
          onChange={(event) => onChange(event.target.value)}
          rows={2}
          className={`${baseClasses} mt-1 block`}
        />
      ) : (
        <input
          type="text"
          value={value}
          onChange={(event) => onChange(event.target.value)}
          className={`${baseClasses} mt-1 block`}
        />
      )}
    </label>
  )
}
