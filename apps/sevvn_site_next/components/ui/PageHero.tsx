import { Badge } from "@/components/ui/Badge"

interface PageHeroProps {
  eyebrow: string
  title: string
  description: string
  badge?: string
}

export function PageHero({ eyebrow, title, description, badge }: PageHeroProps) {
  return (
    <section className="border-b border-border bg-[linear-gradient(180deg,#fff_0%,#fff_55%,#fafaf9_100%)] pb-16 pt-20">
      <div className="mx-auto max-w-[920px] px-8 text-center">
        <p className="eyebrow">{eyebrow}</p>
        <h1 className="mt-3 text-[clamp(2.5rem,6vw,4.2rem)] font-extrabold leading-[1.03] tracking-[-0.04em] text-ink">
          {title}
        </h1>
        <p className="mx-auto mt-5 max-w-[720px] text-[1.04rem] leading-[1.75] text-muted">
          {description}
        </p>
        {badge ? <Badge className="mt-6">{badge}</Badge> : null}
      </div>
    </section>
  )
}
