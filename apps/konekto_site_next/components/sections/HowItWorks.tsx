import { Section } from "@/components/ui/Section";
import { SectionHeading } from "@/components/ui/SectionHeading";

const STEPS = ["Plano", "Template", "Módulos", "Marca", "Publicado", "Evolui"];

export function HowItWorks() {
  return (
    <Section id="como-funciona" alt paddingY="64px">
      <SectionHeading
        eyebrow="Como funciona"
        title="Do plano ao aplicativo publicado, em uma jornada só"
        marginBottom="56px"
      />
      <div className="relative grid grid-cols-3 gap-x-[14px] gap-y-[32px] sm:grid-cols-6 sm:gap-y-[14px]">
        <div
          aria-hidden="true"
          className="absolute left-[8%] right-[8%] top-[23px] hidden h-[2px] bg-border sm:block"
        />
        {STEPS.map((step, index) => {
          const isLast = index === STEPS.length - 1;
          return (
            <div key={step} className="relative text-center">
              <div
                className={`relative mx-auto flex h-[46px] w-[46px] items-center justify-center rounded-full text-[15px] font-semibold ${
                  isLast ? "bg-primary text-white" : "bg-ink text-white"
                }`}
                style={{ fontFamily: "var(--font-mono)" }}
              >
                {String(index + 1).padStart(2, "0")}
              </div>
              <div
                className={`mt-[14px] text-[13.5px] font-bold ${isLast ? "text-primary" : "text-ink"}`}
              >
                {step}
              </div>
            </div>
          );
        })}
      </div>
    </Section>
  );
}
