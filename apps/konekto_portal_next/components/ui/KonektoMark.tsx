/** Mark oficial da marca (o mesmo sunburst de 8 pontas usado em apps/konekto_site/index.html) — substitui o desenho antigo de dois quadrados sobrepostos. */
export function KonektoMark({ size = 32 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 100 100" fill="var(--color-gold)" aria-hidden="true" className="shrink-0">
      <rect x="46" y="6" width="8" height="30" rx="4" />
      <rect x="46" y="64" width="8" height="30" rx="4" />
      <rect x="46" y="6" width="8" height="30" rx="4" transform="rotate(45 50 50)" />
      <rect x="46" y="6" width="8" height="30" rx="4" transform="rotate(90 50 50)" />
      <rect x="46" y="6" width="8" height="30" rx="4" transform="rotate(135 50 50)" />
      <rect x="46" y="6" width="8" height="30" rx="4" transform="rotate(180 50 50)" />
      <rect x="46" y="6" width="8" height="30" rx="4" transform="rotate(225 50 50)" />
      <rect x="46" y="6" width="8" height="30" rx="4" transform="rotate(270 50 50)" />
      <rect x="46" y="6" width="8" height="30" rx="4" transform="rotate(315 50 50)" />
    </svg>
  )
}
