import { ComingSoonSpinner } from "@/components/ui/ComingSoonSpinner";
import { Section } from "@/components/ui/Section";
import { SectionHeading } from "@/components/ui/SectionHeading";

interface ModuleEntry {
  name: string;
  implemented: boolean;
}

interface ModuleCategory {
  label: string;
  modules: ModuleEntry[];
}

/**
 * Status (`implemented`) reflete apps/konekto_api/lib/module-catalog.ts —
 * módulos já ativos primeiro, "Em breve" depois, dentro de cada categoria.
 */
const CATEGORIES: ModuleCategory[] = [
  {
    label: "Hospitalidade",
    modules: [
      { name: "Room Service", implemented: true },
      { name: "Restaurantes", implemented: true },
      { name: "Passeios", implemented: true },
      { name: "Spa", implemented: true },
      { name: "Concierge", implemented: false },
      { name: "Eventos", implemented: false },
      { name: "Lavanderia", implemented: false },
      { name: "Estacionamento", implemented: false },
      { name: "Academia", implemented: false },
      { name: "Kids Club", implemented: false },
    ],
  },
  {
    label: "Experiência",
    modules: [
      { name: "Programa de Fidelidade", implemented: true },
      { name: "Carteira Digital", implemented: true },
      { name: "Promoções", implemented: true },
      { name: "Avaliações", implemented: false },
      { name: "Chat Multilíngue", implemented: false },
      { name: "Notificações Inteligentes", implemented: false },
    ],
  },
  {
    label: "Operação",
    modules: [
      { name: "Informações da Hospedagem", implemented: true },
      { name: "Reservas", implemented: true },
      { name: "Perfil", implemented: true },
      { name: "Mensagens", implemented: true },
      { name: "Check-in Digital", implemented: false },
      { name: "Check-out Digital", implemented: false },
    ],
  },
  {
    label: "Comunicação",
    modules: [
      { name: "Avisos", implemented: true },
      { name: "Central de Ajuda", implemented: false },
      { name: "FAQ", implemented: false },
    ],
  },
];

const TOTAL_MODULES = CATEGORIES.flatMap((category) => category.modules).length;
const LIVE_MODULES = CATEGORIES.flatMap((category) => category.modules).filter(
  (moduleEntry) => moduleEntry.implemented,
).length;

export function ModuleGrid() {
  return (
    <Section id="modulos">
      <SectionHeading
        eyebrow="Monte seu aplicativo"
        title="Ative só os módulos que sua operação precisa"
        lede={`${LIVE_MODULES} módulos já disponíveis hoje, de um catálogo de ${TOTAL_MODULES} — e crescendo toda semana.`}
        marginBottom="48px"
      />
      <div className="grid grid-cols-1 gap-[18px] sm:grid-cols-2 lg:grid-cols-4">
        {CATEGORIES.map((category) => (
          <div key={category.label} className="rounded-[14px] bg-card p-[22px] text-left">
            <p className="mb-3 text-[13px] font-bold uppercase tracking-[0.04em] text-primary">
              {category.label}
            </p>
            <div className="flex flex-col gap-[9px] text-[13.5px]">
              {category.modules.map((moduleEntry) => (
                <div
                  key={moduleEntry.name}
                  className={`flex items-center gap-[7px] ${
                    moduleEntry.implemented ? "text-ink" : "text-muted"
                  }`}
                >
                  <span>• {moduleEntry.name}</span>
                  {!moduleEntry.implemented && (
                    <>
                      <ComingSoonSpinner className="h-[13px] w-[13px]" />
                      <span className="sr-only">Em breve</span>
                    </>
                  )}
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </Section>
  );
}
