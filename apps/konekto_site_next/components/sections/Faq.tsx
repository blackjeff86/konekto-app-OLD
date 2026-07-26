import { FAQ_ITEMS } from "@/content/faq";
import { Section } from "@/components/ui/Section";

export function Faq() {
  return (
    <Section id="faq">
      <div className="mx-auto mb-11 max-w-[760px] text-center">
        <p className="eyebrow">FAQ</p>
        <h2 className="mt-[10px] text-[32px] font-extrabold leading-[1.15] tracking-[-0.02em] text-ink">
          Perguntas frequentes
        </h2>
      </div>
      <div className="mx-auto max-w-[760px]">
        {FAQ_ITEMS.map((item, index) => (
          <div
            key={item.question}
            className={`py-5 ${index < FAQ_ITEMS.length - 1 ? "border-b border-border" : ""}`}
          >
            <p className="text-[15px] font-bold text-ink">{item.question}</p>
            <p className="mt-2 text-[13.5px] leading-[1.6] text-muted">{item.answer}</p>
          </div>
        ))}
      </div>
    </Section>
  );
}
