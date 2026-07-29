"use client";

import { useMemo } from "react";
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
  const branding = useMemo(() => inferClaimBranding(), []);

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
      </div>
    </AuraShell>
  );
}

function inferClaimBranding(): {
  hotelName: string;
  logoUrl: string | null;
  monogram: string;
  welcomeCopy: string;
} {
  if (typeof window === "undefined") {
    return {
      hotelName: "Seu hotel na Sevvn",
      logoUrl: null,
      monogram: "S",
      welcomeCopy:
        "Bem-vindo. Digite o seu codigo de acesso para entrar na sua experiencia de hospedagem.",
    };
  }

  const hostname = window.location.hostname.toLowerCase();
  const reservedHosts = new Set([
    "localhost",
    "127.0.0.1",
    "sevvn-guest.vercel.app",
    "sevvnguestnext.vercel.app",
    "sevvnguestnext-5ohd8v0ej-jeffersonbrito86-gmailcoms-projects.vercel.app",
  ]);

  if (reservedHosts.has(hostname) || hostname.endsWith(".vercel.app")) {
    return {
      hotelName: "Seu hotel na Sevvn",
      logoUrl: null,
      monogram: "S",
      welcomeCopy:
        "Bem-vindo. Digite o seu codigo de acesso para entrar na sua experiencia de hospedagem.",
    };
  }

  const subdomain = hostname.split(".")[0]?.trim();
  if (!subdomain) {
    return {
      hotelName: "Seu hotel na Sevvn",
      logoUrl: null,
      monogram: "S",
      welcomeCopy:
        "Bem-vindo. Digite o seu codigo de acesso para entrar na sua experiencia de hospedagem.",
    };
  }

  const hotelName = subdomain
    .split("-")
    .filter(Boolean)
    .map((chunk) => chunk.charAt(0).toUpperCase() + chunk.slice(1))
    .join(" ");

  const monogram = hotelName
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0])
    .join("")
    .toUpperCase();

  return {
    hotelName,
    logoUrl: null,
    monogram: monogram || "S",
    welcomeCopy:
      "Bem-vindo. Digite o seu codigo de acesso para entrar na sua experiencia de hospedagem.",
  };
}
