type Props = {
  children: React.ReactNode;
  tone?: "primary" | "ink" | "muted";
  className?: string;
};

const TONE_CLASSES: Record<NonNullable<Props["tone"]>, string> = {
  primary: "bg-primary-soft text-primary-text",
  ink: "bg-ink text-white",
  muted: "bg-card text-muted",
};

export function Badge({ children, tone = "primary", className }: Props) {
  return (
    <span
      className={`inline-flex items-center rounded-full px-3 py-[0.35rem] text-[0.68rem] font-bold uppercase tracking-[0.04em] ${TONE_CLASSES[tone]} ${className ?? ""}`}
    >
      {children}
    </span>
  );
}
