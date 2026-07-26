type Props = {
  id?: string;
  alt?: boolean;
  paddingY?: string;
  className?: string;
  children: React.ReactNode;
};

/** Wrapper compartilhado por todas as seções da Landing — padding vertical e container centralizado consistentes. */
export function Section({ id, alt, paddingY = "96px", className, children }: Props) {
  return (
    <section
      id={id}
      className={`${alt ? "bg-surface-alt" : ""} ${className ?? ""}`}
      style={{ paddingTop: paddingY, paddingBottom: paddingY }}
    >
      <div className="mx-auto max-w-[1180px] px-8">{children}</div>
    </section>
  );
}
