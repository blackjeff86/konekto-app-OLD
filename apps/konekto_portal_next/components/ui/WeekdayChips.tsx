'use client'

/** Portado de apps/konekto_portal/lib/widgets/weekday_chips.dart. ISO weekday (1=segunda...7=domingo). */
const WEEKDAY_LABELS = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom']

interface WeekdayChipsProps {
  selectedDays: Set<number>
  onToggleDay: (day: number) => void
}

export function WeekdayChips({ selectedDays, onToggleDay }: WeekdayChipsProps) {
  return (
    <div className="flex flex-wrap gap-1.5">
      {WEEKDAY_LABELS.map((label, index) => {
        const day = index + 1
        const selected = selectedDays.has(day)
        return (
          <button
            key={day}
            type="button"
            onClick={() => onToggleDay(day)}
            className="rounded-full border px-3 py-1 text-xs"
            style={{
              borderColor: selected ? 'var(--color-gold)' : 'var(--color-border-strong)',
              backgroundColor: selected ? 'rgba(255,46,136,0.14)' : 'rgba(22,24,29,0.03)',
              color: selected ? 'var(--color-gold-light)' : 'var(--color-cream)',
            }}
          >
            {label}
          </button>
        )
      })}
    </div>
  )
}
