"use client";

import type { CSSProperties, ReactNode } from "react";
import {
  AuraBottomNav,
  AuraCard,
  AuraIconButton,
  AuraShell,
  AuraTopBar,
  type AuraBottomNavItem,
} from "@/components/guest/aura/AuraPrimitives";
import type { GuestSession } from "@/lib/guest-session";
import type {
  GuestLoadState,
  GuestViewState,
  ResolvedModulesShape,
} from "@/lib/guest-shell";
import { activeModuleId, viewForModule } from "@/lib/guest-shell";

export function GuestAuthenticatedShell({
  bottomNavItems,
  children,
  loadState,
  onSignOut,
  onViewChange,
  resolvedModules,
  session,
  themeStyle,
  view,
}: {
  bottomNavItems: AuraBottomNavItem[];
  children: ReactNode;
  loadState: GuestLoadState;
  onSignOut: () => void;
  onViewChange: (view: GuestViewState) => void;
  resolvedModules: ResolvedModulesShape | null;
  session: GuestSession;
  themeStyle: CSSProperties;
  view: GuestViewState;
}) {
  return (
    <AuraShell
      style={themeStyle}
      topBar={
        <AuraTopBar
          eyebrow="Aura Stay"
          title={`${session.guest.firstName} ${session.guest.lastName}`}
          subtitle={`Quarto ${session.guest.roomNumber}`}
          action={<AuraIconButton icon="logout" label="Sair" onClick={onSignOut} />}
        />
      }
      footer={
        loadState.status === "ready" && bottomNavItems.length > 0 ? (
          <AuraBottomNav
            activeId={activeModuleId(view)}
            items={bottomNavItems}
            onSelect={(itemId) => {
              const module = resolvedModules?.bottomNav.find(
                (entry) => entry.id === itemId,
              );
              if (module) {
                onViewChange(viewForModule(module));
              }
            }}
          />
        ) : undefined
      }
    >
      <div className="guest-shell-header">
        <div>
          <p className="guest-eyebrow">Sessao autenticada</p>
          <h1 className="guest-title">
            {loadState.status === "ready"
              ? loadState.hotel.hotelInfo?.name || "Sevvn Guest"
              : "Sevvn Guest"}
          </h1>
          <p className="guest-copy">Hotel autenticado: {session.guest.hotelId}</p>
        </div>
      </div>

      <AuraCard className="guest-security-note" soft>
        <section className="guest-security-note">
          <strong>Regra de seguranca ativa:</strong> o app carrega dados apenas
          para o hotel vinculado ao claim autenticado. O `hotelId` vem da
          sessao do hospede, nao de URL livre ou troca manual.
        </section>
      </AuraCard>

      {loadState.status === "loading" ? (
        <p className="guest-copy">Carregando hotel e servicos...</p>
      ) : null}

      {loadState.status === "error" ? (
        <p className="guest-error">{loadState.message}</p>
      ) : null}

      {children}
    </AuraShell>
  );
}
