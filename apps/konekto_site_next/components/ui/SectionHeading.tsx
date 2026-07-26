type Props = {
  eyebrow: string;
  title: string;
  lede?: string;
  maxWidth?: string;
  titleSize?: string;
  marginBottom?: string;
  className?: string;
};

export function SectionHeading({
  eyebrow,
  title,
  lede,
  maxWidth = "640px",
  titleSize = "34px",
  marginBottom = "0",
  className,
}: Props) {
  return (
    <div
      className={`mx-auto text-center ${className ?? ""}`}
      style={{ maxWidth, marginBottom }}
    >
      <p className="eyebrow">{eyebrow}</p>
      <h2
        className="mt-[10px] font-extrabold leading-[1.15] tracking-[-0.02em] text-ink"
        style={{ fontSize: titleSize }}
      >
        {title}
      </h2>
      {lede ? <p className="mt-[14px] text-[16px] leading-[1.6] text-muted">{lede}</p> : null}
    </div>
  );
}
