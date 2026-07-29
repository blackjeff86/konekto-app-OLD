"use client";

import { AuraCard, AuraIconButton, AuraSectionHeading, AuraShell, AuraTopBar } from "@/components/guest/aura/AuraPrimitives";

export function GuestClaimScreen({
  claimCode,
  claimError,
  isPending,
  onChangeClaimCode,
  onSubmit,
  themeStyle,
}: {
  claimCode: string;
  claimError: string | null;
  isPending: boolean;
  onChangeClaimCode: (value: string) => void;
  onSubmit: (event: React.FormEvent<HTMLFormElement>) => void;
  themeStyle: React.CSSProperties;
}) {
  return (
    <AuraShell
      style={themeStyle}
      topBar={
        <AuraTopBar
          eyebrow="Aura Arrival"
          title="Acesso do hospede"
          subtitle="Experiencia segura e personalizada para cada hotel."
          action={<AuraIconButton icon="lock" label="Acesso protegido" />}
        />
      }
    >
      <AuraCard className="guest-card">
        <AuraSectionHeading
          title="Entre com o seu codigo"
          copy="O hotel exibido neste app sera sempre derivado do codigo de acesso validado, nunca de uma escolha manual do navegador."
        />

        <form className="guest-form" onSubmit={onSubmit}>
          <label className="guest-label" htmlFor="claimCode">
            Codigo de acesso
          </label>
          <input
            id="claimCode"
            value={claimCode}
            onChange={(event) => onChangeClaimCode(event.target.value)}
            placeholder="SV-P84YQ3"
            autoCapitalize="characters"
            className="guest-input"
          />
          <button
            type="submit"
            className="guest-button"
            disabled={isPending || !claimCode.trim()}
          >
            {isPending ? "Validando..." : "Entrar"}
          </button>
        </form>

        {claimError ? <p className="guest-error">{claimError}</p> : null}
      </AuraCard>
    </AuraShell>
  );
}
