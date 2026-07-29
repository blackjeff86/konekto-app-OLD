const TICKS = [
  { deg: 0, opacity: 1 },
  { deg: 45, opacity: 0.87 },
  { deg: 90, opacity: 0.74 },
  { deg: 135, opacity: 0.61 },
  { deg: 180, opacity: 0.48 },
  { deg: 225, opacity: 0.35 },
  { deg: 270, opacity: 0.22 },
  { deg: 315, opacity: 0.13 },
];

type Props = {
  className?: string;
};

/** Spinner de traços (estilo iOS) pra sinalizar módulo "em breve" sem usar texto. */
export function ComingSoonSpinner({ className }: Props) {
  return (
    <svg
      className={`shrink-0 animate-spin text-primary motion-reduce:animate-none ${className ?? ""}`}
      viewBox="0 0 24 24"
      fill="none"
      aria-hidden="true"
    >
      {TICKS.map((tick) => (
        <line
          key={tick.deg}
          x1="12"
          y1="3.5"
          x2="12"
          y2="8"
          stroke="currentColor"
          strokeWidth="2.5"
          strokeLinecap="round"
          opacity={tick.opacity}
          transform={`rotate(${tick.deg} 12 12)`}
        />
      ))}
    </svg>
  );
}
