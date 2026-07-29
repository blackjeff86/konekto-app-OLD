"use client";

import { useEffect, useState } from "react";
import { AuraCard, AuraIconButton, AuraSectionHeading, AuraShell, AuraTopBar } from "@/components/guest/aura/AuraPrimitives";
import { resolveGuestBranding } from "@/lib/api/hotels";
import type { GuestClaimBranding } from "@/lib/guest-types";

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
  const [branding, setBranding] = useState<GuestClaimBranding>(getFallbackBranding());

  useEffect(() => {
    if (typeof window === "undefined") return;

    const hostname = window.location.hostname;
    if (!hostname) return;

    void resolveGuestBranding(hostname)
      .then((result) => setBranding(result))
      .catch(() => setBranding(getFallbackBranding()));
  }, []);

  return (
    <AuraShell
      style={themeStyle}
    >
      <div className="aura-claim-stage">
        <div className="aura-claim-brand">
          <div className="aura-claim-brand-mark">
            {branding.logoUrl ? (
              <img
                src={branding.logoUrl}
                alt={`Logo de ${branding.hotelName}`}
                className="aura-claim-brand-image"
              />
            ) : (
              <span className="aura-claim-brand-monogram">
                {branding.monogram}
              </span>
            )}
          </div>
          <p className="guest-card-label">Portal do hospede</p>
          <h1 className="aura-claim-brand-name">{branding.hotelName}</h1>
          <p className="aura-claim-brand-copy">
            {branding.welcomeCopy}
          </p>
        </div>

        <AuraCard className="guest-card aura-claim-card">
          <div className="aura-claim-card-heading">
            <AuraTopBar
              eyebrow="Chegada Sevvn"
              title="Acesso do hospede"
              subtitle="Entre com o seu codigo de acesso para abrir a sua experiencia no hotel."
              action={<AuraIconButton icon="lock" label="Acesso protegido" />}
            />
          </div>

        <AuraSectionHeading
          title="Entre com o seu codigo"
          copy="O acesso do hospede continua protegido pelo codigo validado pela Sevvn. O hotel exibido nesta tela vem do endereco oficial configurado para a propriedade."
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
      </div>
    </AuraShell>
  );
}

function getFallbackBranding(): GuestClaimBranding {
  return {
    hotelId: "",
    hotelName: "Seu hotel na Sevvn",
    logoUrl: null,
    monogram: "S",
    welcomeCopy:
      "Bem-vindo. Digite o seu codigo de acesso para entrar na sua experiencia de hospedagem.",
    matchType: "fallback",
  };
}
