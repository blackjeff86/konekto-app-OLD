'use client'

interface CopyableCodeBoxProps {
  value: string
  fontSize?: number
}

/** Portado de apps/konekto_portal/lib/widgets/copyable_code_box.dart. */
export function CopyableCodeBox({ value, fontSize = 18 }: CopyableCodeBoxProps) {
  async function handleCopy() {
    await navigator.clipboard.writeText(value)
  }

  return (
    <div className="flex items-center gap-2 rounded-[10px] border border-border-strong bg-black/3 px-3.5 py-3">
      <span className="flex-1 select-all font-bold text-gold-light" style={{ fontSize }}>
        {value}
      </span>
      <button
        type="button"
        aria-label="Copiar código"
        onClick={handleCopy}
        className="text-slate"
      >
        ⧉
      </button>
    </div>
  )
}
