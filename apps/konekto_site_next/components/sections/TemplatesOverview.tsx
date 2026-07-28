import { TEMPLATES } from "@/content/templates"
import { Section } from "@/components/ui/Section"
import { SectionHeading } from "@/components/ui/SectionHeading"

export function TemplatesOverview() {
  return (
    <Section id="templates" alt>
      <SectionHeading
        eyebrow="Templates"
        title="Cinco identidades visuais. A mesma plataforma por trás."
        lede="Aura, Bosque, Elite, Pulse e Horizon representam experiências visuais diferentes dentro da mesma estrutura. Os templates definem a linguagem visual. Os módulos definem os recursos. Os fluxos centrais do piloto permanecem compatíveis nos cinco."
        maxWidth="820px"
        marginBottom="40px"
      />
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-5">
        {TEMPLATES.map((template) => (
          <div key={template.id} className="rounded-[22px] border border-border bg-white p-5">
            <p className="text-[0.72rem] font-bold uppercase tracking-[0.18em] text-primary">{template.tagline}</p>
            <h3 className="mt-3 text-[1.05rem] font-bold text-ink">{template.name}</h3>
            <p className="mt-3 text-[0.9rem] leading-[1.65] text-muted">{template.description}</p>
          </div>
        ))}
      </div>
      <p className="mx-auto mt-8 max-w-[760px] text-center text-[0.92rem] leading-[1.75] text-muted">
        Os cinco templates já existem como parte da plataforma. Hoje, a Home é a camada mais
        específica por template, enquanto os fluxos operacionais centrais do piloto seguem em uma
        base compartilhada e compatível entre eles.
      </p>
    </Section>
  )
}
