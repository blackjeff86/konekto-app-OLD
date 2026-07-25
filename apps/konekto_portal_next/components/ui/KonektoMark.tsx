/** Portado de KonektoMark (apps/konekto_portal/lib/theme/konekto_brand.dart) — dois quadrados arredondados sobrepostos. */
export function KonektoMark({ size = 32 }: { size?: number }) {
  return (
    <div className="relative shrink-0" style={{ width: size, height: size }}>
      <div
        className="absolute rounded-[16%] border-[color:var(--color-gold-light)]"
        style={{
          left: size * 0.12,
          top: size * 0.12,
          width: size * 0.56,
          height: size * 0.56,
          borderWidth: size * 0.06,
        }}
      />
      <div
        className="absolute rounded-[10%] bg-gold"
        style={{ left: size * 0.52, top: size * 0.52, width: size * 0.34, height: size * 0.34 }}
      />
    </div>
  )
}
