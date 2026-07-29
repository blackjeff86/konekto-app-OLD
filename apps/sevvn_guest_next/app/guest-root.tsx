"use client";

import { useEffect, useMemo, useState, useTransition } from "react";
import type { AuraBottomNavItem } from "@/components/guest/aura/AuraPrimitives";
import { GuestAuthenticatedShell } from "@/components/guest/GuestAuthenticatedShell";
import { GuestClaimScreen } from "@/components/guest/GuestClaimScreen";
import { GuestCurrentView } from "@/components/guest/GuestCurrentView";
import { claimGuestAccess } from "@/lib/api/guest";
import {
  getGuestHotelConfig,
  getGuestItemAvailability,
  getGuestRestaurantTableAvailability,
  getGuestService,
  getGuestServices,
} from "@/lib/api/hotels";
import { getModulesCatalog } from "@/lib/api/modules-catalog";
import { getGuestNotices } from "@/lib/api/notices";
import { createGuestOrder, getGuestOrders } from "@/lib/api/orders";
import { getGuestMessages, sendGuestMessage } from "@/lib/api/messages";
import type {
  ConciergeModuleConfig,
  GuestClaimResponse,
  GuestHotelConfig,
  GuestItemAvailabilityResponse,
  GuestMessage,
  GuestNotice,
  GuestOrder,
  RoomServiceModuleConfig,
  GuestScheduledSlot,
  GuestService,
  GuestTableAvailabilityItem,
  RestaurantBookingMode,
  RestaurantModuleConfig,
  ServiceItem,
  GuestTemplateId,
} from "@/lib/guest-types";
import type { ModuleDefinition, ModulesCatalogResponse } from "@/lib/module-catalog";
import {
  clearGuestSession,
  loadGuestSession,
  saveGuestSession,
  type GuestSession,
} from "@/lib/guest-session";
import {
  groupServicesByCatalog,
  resolveBottomNavModules,
  resolveHomeModules,
  resolveServicesMenuModules,
} from "@/lib/module-engine";
import {
  activeModuleId,
  getModuleRuntimeStatus,
  iconForModule,
  supportsModuleNavigation,
  type GuestLoadState as LoadState,
  type GuestOrdersState as OrdersState,
  type GuestServiceDetailState as ServiceDetailState,
  type GuestViewState as ViewState,
  type ResolvedModulesShape,
  useResolvedModules,
  viewForModule,
} from "@/lib/guest-shell";
import { createAuraThemeStyle } from "@/lib/theme/aura";

type RoomServiceComposerProps = {
  token: string;
  service: GuestService;
  moduleConfig: RoomServiceModuleConfig;
  onOrderCreated: (order: GuestOrder) => void;
};

type RestaurantReservationComposerProps = {
  token: string;
  hotelId: string;
  service: GuestService;
  moduleConfig: RestaurantModuleConfig;
  onOrderCreated: (order: GuestOrder) => void;
};

type ActivityBookingComposerProps = {
  token: string;
  hotelId: string;
  service: GuestService;
  onOrderCreated: (order: GuestOrder) => void;
};

type ConciergeComposerProps = {
  token: string;
  service: GuestService;
  moduleConfig: ConciergeModuleConfig;
  variant?: "inline" | "page";
};

const templateAccent: Record<GuestTemplateId, string> = {
  aura: "#6750A4",
  bosque: "#173124",
  elite: "#1D1C15",
  pulse: "#F2CA50",
  horizon: "#0077B6",
};

export function GuestRoot() {
  const [session, setSession] = useState<GuestSession | null>(null);
  const [claimCode, setClaimCode] = useState("");
  const [claimError, setClaimError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();
  const [loadState, setLoadState] = useState<LoadState>({ status: "idle" });
  const [view, setView] = useState<ViewState>({ kind: "home" });
  const [ordersState, setOrdersState] = useState<OrdersState>({
    status: "idle",
    orders: [],
  });
  const [serviceDetailState, setServiceDetailState] = useState<ServiceDetailState>({
    status: "idle",
  });
  const [noticesState, setNoticesState] = useState<{
    status: "idle" | "loading" | "ready" | "error";
    notices: GuestNotice[];
  }>({
    status: "idle",
    notices: [],
  });

  useEffect(() => {
    const stored = loadGuestSession();
    if (stored) {
      setSession(stored);
    }
  }, []);

  useEffect(() => {
    if (!session) {
      setLoadState({ status: "idle" });
      return;
    }

    let cancelled = false;
    setLoadState({ status: "loading" });

    void Promise.all([
      getGuestHotelConfig(session.guest.hotelId),
      getGuestServices(session.guest.hotelId),
      getModulesCatalog(),
    ])
      .then(([hotel, services, modulesCatalog]) => {
        if (cancelled) return;

        if (hotel.id !== session.guest.hotelId) {
          throw new Error(
            "O hotel retornado pela API nao corresponde ao hotel autenticado do hospede.",
          );
        }

        setLoadState({ status: "ready", hotel, services, modulesCatalog });
      })
      .catch(() => {
        if (cancelled) return;
        setLoadState({
          status: "error",
          message:
            "Nao foi possivel carregar os dados do hotel com seguranca. Tente entrar novamente.",
        });
      });

    return () => {
      cancelled = true;
    };
  }, [session]);

  useEffect(() => {
    if (!session || view.kind !== "bookings") return;

    let cancelled = false;
    setOrdersState((current) => ({ ...current, status: "loading" }));

    void getGuestOrders(session.token)
      .then((orders) => {
        if (cancelled) return;
        setOrdersState({ status: "ready", orders });
      })
      .catch(() => {
        if (cancelled) return;
        setOrdersState({ status: "error", orders: [] });
      });

    return () => {
      cancelled = true;
    };
  }, [session, view]);

  useEffect(() => {
    if (!session || view.kind !== "service-detail") {
      setServiceDetailState({ status: "idle" });
      return;
    }

    let cancelled = false;
    setServiceDetailState({ status: "loading" });

    void getGuestService(session.guest.hotelId, view.serviceId)
      .then((service) => {
        if (cancelled) return;
        setServiceDetailState({ status: "ready", service });
      })
      .catch(() => {
        if (cancelled) return;
        setServiceDetailState({
          status: "error",
          message:
            "Nao foi possivel carregar os detalhes desse servico no hotel autenticado.",
        });
      });

    return () => {
      cancelled = true;
    };
  }, [session, view]);

  useEffect(() => {
    if (!session || view.kind !== "notices") return;

    let cancelled = false;
    setNoticesState((current) => ({
      status: current.notices.length > 0 ? "ready" : "loading",
      notices: current.notices,
    }));

    void getGuestNotices(session.token)
      .then((notices) => {
        if (cancelled) return;
        setNoticesState({ status: "ready", notices });
      })
      .catch(() => {
        if (cancelled) return;
        setNoticesState({ status: "error", notices: [] });
      });

    return () => {
      cancelled = true;
    };
  }, [session, view]);

  const accentColor = useMemo(() => {
    if (loadState.status !== "ready") return "var(--accent)";
    const template = loadState.hotel.template ?? "aura";
    return templateAccent[template];
  }, [loadState]);

  const resolvedModules = useResolvedModules(loadState);
  const themeStyle = useMemo(
    () =>
      createAuraThemeStyle(
        loadState.status === "ready" ? loadState.hotel : undefined,
      ),
    [loadState],
  );

  const bottomNavItems = useMemo<AuraBottomNavItem[]>(() => {
    if (!resolvedModules) return [];

    return resolvedModules.bottomNav.map((module) => ({
      id: module.id,
      icon: iconForModule(module.id),
      label: module.name,
    }));
  }, [resolvedModules]);

  function handleClaimSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setClaimError(null);

    startTransition(() => {
      void claimGuestAccess(claimCode.trim().toUpperCase())
        .then((result) => {
          const nextSession = buildSession(result);
          saveGuestSession(nextSession);
          setSession(nextSession);
          setView({ kind: "home" });
          setClaimCode("");
        })
        .catch(() => {
          setClaimError("Codigo invalido ou acesso indisponivel no momento.");
        });
    });
  }

  function handleSignOut() {
    clearGuestSession();
    setSession(null);
    setClaimError(null);
    setView({ kind: "home" });
  }

  function handleGuestOrderCreated(order: GuestOrder) {
    setOrdersState((current) => {
      const nextOrders =
        current.status === "ready"
          ? [order, ...current.orders.filter((entry) => entry.id !== order.id)]
          : [order];

      return {
        status: "ready",
        orders: nextOrders,
      };
    });
  }

  if (!session) {
    return (
      <GuestClaimScreen
        claimCode={claimCode}
        claimError={claimError}
        isPending={isPending}
        onChangeClaimCode={setClaimCode}
        onSubmit={handleClaimSubmit}
        themeStyle={themeStyle}
      />
    );
  }

  return (
    <GuestAuthenticatedShell
      bottomNavItems={bottomNavItems}
      loadState={loadState}
      onSignOut={handleSignOut}
      onViewChange={setView}
      resolvedModules={resolvedModules}
      session={session}
      themeStyle={themeStyle}
      view={view}
    >
      {loadState.status === "ready" && resolvedModules ? (
        <GuestCurrentView>
          <div className="guest-module-nav">
            {resolvedModules.home.slice(0, 4).map((module) => (
              <button
              key={module.id}
              type="button"
              className={`aura-action-tile${
                supportsModuleNavigation(module) ? "" : " aura-action-tile-disabled"
              }`}
              disabled={!supportsModuleNavigation(module)}
              onClick={() => setView(viewForModule(module))}
            >
                <span className="aura-action-tile-visual material-symbols-outlined">
                  {iconForModule(module.id)}
                </span>
                <span className="aura-action-tile-label">{module.name}</span>
              </button>
            ))}
          </div>

          {renderCurrentView({
            view,
            hotel: loadState.hotel,
            session,
            services: loadState.services,
            resolvedModules,
            ordersState,
            serviceDetailState,
            token: session.token,
            onOrderCreated: handleGuestOrderCreated,
            onOpenServices: () => setView({ kind: "services" }),
            onOpenBookings: () => setView({ kind: "bookings" }),
            onOpenMessages: () => setView({ kind: "messages" }),
            onOpenNotices: () => setView({ kind: "notices" }),
            onOpenProfile: () => setView({ kind: "profile" }),
            onOpenService: (serviceId) => setView({ kind: "service-detail", serviceId }),
            onBackToServices: () => setView({ kind: "services" }),
            noticesState,
          })}
        </GuestCurrentView>
      ) : null}
    </GuestAuthenticatedShell>
  );
}

function buildSession(result: GuestClaimResponse): GuestSession {
  return {
    token: result.token,
    guest: result.guest,
  };
}

function renderCurrentView({
  view,
  hotel,
  session,
  services,
  resolvedModules,
  ordersState,
  serviceDetailState,
  token,
  onOrderCreated,
  onOpenServices,
  onOpenBookings,
  onOpenMessages,
  onOpenNotices,
  onOpenProfile,
  onOpenService,
  onBackToServices,
  noticesState,
}: {
  view: ViewState;
  hotel: GuestHotelConfig;
  session: GuestSession;
  services: GuestService[];
  resolvedModules: NonNullable<ReturnType<typeof useResolvedModules>>;
  ordersState: OrdersState;
  serviceDetailState: ServiceDetailState;
  token: string;
  onOrderCreated: (order: GuestOrder) => void;
  onOpenServices: () => void;
  onOpenBookings: () => void;
  onOpenMessages: () => void;
  onOpenNotices: () => void;
  onOpenProfile: () => void;
  onOpenService: (serviceId: string) => void;
  onBackToServices: () => void;
  noticesState: {
    status: "idle" | "loading" | "ready" | "error";
    notices: GuestNotice[];
  };
}) {
  if (view.kind === "services") {
    return (
      <>
        <section className="aura-directory-hero">
          <p className="guest-card-label">Catalogo autenticado</p>
          <h2 className="aura-directory-title">Servicos</h2>
          <p className="guest-copy aura-directory-copy">
            Experiencias e operacoes habilitadas especificamente para este hotel.
            O catalogo abaixo reflete os modulos ativos e os servicos reais disponiveis.
          </p>
        </section>

        <section className="aura-directory-grid">
          {resolvedModules.groupedServices.flatMap((section, sectionIndex) =>
            section.services.map((service, serviceIndex) => {
              const isFeature = sectionIndex === 0 && serviceIndex === 0;
              return (
                <button
                  key={service.id}
                  type="button"
                  className={`aura-service-card${isFeature ? " aura-service-card-feature" : ""}`}
                  onClick={() => onOpenService(service.id)}
                >
                  {service.bannerImageUrl ? (
                    <div
                      className="aura-service-card-media"
                      style={{ backgroundImage: `url(${service.bannerImageUrl})` }}
                    />
                  ) : (
                    <div className="aura-service-card-media aura-service-card-media-fallback" />
                  )}
                  <div className="aura-service-card-overlay" />
                  <div className="aura-service-card-content">
                    <div className="aura-service-card-topline">
                      <span className="material-symbols-outlined">
                        {service.icon || iconForModule(service.moduleId ?? service.type)}
                      </span>
                      <span>{section.title ?? service.category ?? "Hospitalidade"}</span>
                    </div>
                    <h3>{service.name}</h3>
                    <p>{service.description}</p>
                  </div>
                </button>
              );
            }),
          )}
        </section>

        <section className="aura-directory-note">
          <div className="aura-directory-note-icon">
            <span className="material-symbols-outlined">concierge</span>
          </div>
          <div>
            <h3>Solicitacoes especiais</h3>
            <p>
              Se o que voce procura nao estiver listado aqui, o concierge pode
              receber pedidos personalizados dentro do mesmo contexto autenticado.
            </p>
          </div>
        </section>

        {resolvedModules.groupedServices.length === 0 ? (
          <section className="guest-card guest-card-wide">
            <p className="guest-copy">
              Nenhum servico agrupado disponivel no momento.
            </p>
          </section>
        ) : null}
      </>
    );
  }

  if (view.kind === "service-detail") {
    if (serviceDetailState.status === "loading" || serviceDetailState.status === "idle") {
      return (
        <article className="guest-card guest-card-wide">
          <p className="guest-copy">
            Carregando detalhes do servico no contexto autenticado do hotel...
          </p>
        </article>
      );
    }

    if (serviceDetailState.status === "error") {
      return (
        <article className="guest-card guest-card-wide">
          <p className="guest-error">{serviceDetailState.message}</p>
        </article>
      );
    }

    const service = serviceDetailState.service;
    const restaurantModuleConfig = getRestaurantModuleConfig(hotel.enabledModules);
    const roomServiceModuleConfig = getRoomServiceModuleConfig(hotel.enabledModules);
    const conciergeModuleConfig = getConciergeModuleConfig(hotel.enabledModules);
    const showRestaurantMenu =
      service.type !== "restaurant" || restaurantModuleConfig.showMenuInGuestApp !== false;
    const showRestaurantPrices =
      service.type !== "restaurant" || restaurantModuleConfig.showMenuPrices !== false;

    return (
      <>
        <section className="aura-detail-hero">
          {service.bannerImageUrl ? (
            <div
              className="aura-detail-hero-media"
              style={{ backgroundImage: `url(${service.bannerImageUrl})` }}
            />
          ) : (
            <div className="aura-detail-hero-media aura-detail-hero-media-fallback" />
          )}
          <div className="aura-detail-hero-overlay" />
          <div className="aura-detail-hero-content">
            <button
              type="button"
              className="aura-back-chip"
              onClick={onBackToServices}
            >
              <span className="material-symbols-outlined">arrow_back</span>
              Voltar para servicos
            </button>
            <span className="aura-service-card-topline">
              <span className="material-symbols-outlined">
                {service.icon || iconForModule(service.moduleId ?? service.type)}
              </span>
              <span>{service.type.replaceAll("_", " ")}</span>
            </span>
            <h2>{service.name}</h2>
            <p>{service.description}</p>
          </div>
        </section>

        <section className="aura-detail-meta">
          <article className="aura-detail-meta-card">
            <p className="guest-card-label">Modulo</p>
            <strong>{service.moduleId ?? "Nao informado"}</strong>
          </article>
          <article className="aura-detail-meta-card">
            <p className="guest-card-label">Itens ativos</p>
            <strong>{service.items?.length ?? 0}</strong>
          </article>
          <article className="aura-detail-meta-card">
            <p className="guest-card-label">Template</p>
            <strong>{hotel.template ?? "aura"}</strong>
          </article>
        </section>

        {showRestaurantMenu ? (
          service.items?.length ? (
            <section className="aura-detail-items">
              <div className="aura-section-headline">
                <h3 className="aura-section-title">Itens disponiveis</h3>
                <span className="guest-card-label">Catalogo real do hotel</span>
              </div>
              <div className="aura-detail-item-list">
                {service.items.map((item) => (
                  <article key={item.id} className="aura-detail-item-card">
                    <div className="aura-detail-item-media">
                      {item.imageUrl ? (
                        <div
                          className="aura-detail-item-media-image"
                          style={{ backgroundImage: `url(${item.imageUrl})` }}
                        />
                      ) : (
                        <div className="aura-detail-item-media-fallback">
                          <span className="material-symbols-outlined">
                            {service.icon || iconForModule(service.moduleId ?? service.type)}
                          </span>
                        </div>
                      )}
                    </div>
                    <div className="aura-detail-item-body">
                      <div className="aura-detail-item-header">
                        <h4>{item.name}</h4>
                        <strong>
                          {showRestaurantPrices
                            ? formatItemPrice(item.price)
                            : "oculto"}
                        </strong>
                      </div>
                      <p>{item.description || "Sem descricao."}</p>
                      <div className="guest-chip-list">
                        <span className="guest-chip">{item.category ?? "item"}</span>
                        {item.durationMinutes ? (
                          <span className="guest-chip">
                            {item.durationMinutes} min
                          </span>
                        ) : null}
                        {item.isMinibarItem ? (
                          <span className="guest-chip">frigobar</span>
                        ) : null}
                      </div>
                    </div>
                  </article>
                ))}
              </div>
            </section>
          ) : null
        ) : service.type === "restaurant" ? (
          <section className="guest-card guest-card-wide">
            <p className="guest-card-label">Cardapio</p>
            <h3 className="guest-card-title">Cardapio oculto pelo hotel</h3>
            <p className="guest-copy">
              Este restaurante aceita reservas mesmo sem exibir os pratos dentro do
              app do hospede.
            </p>
          </section>
        ) : null}

        {service.tableTypes?.length ? (
          <section className="guest-card guest-card-wide">
            <div className="aura-section-headline">
              <h3 className="aura-section-title">Mesas e configuracoes</h3>
              <span className="guest-card-label">Restaurante</span>
            </div>
            <div className="guest-services-list">
              {service.tableTypes.map((tableType) => (
                <div key={tableType.id} className="guest-service-row">
                  <div>
                    <strong>{tableType.name}</strong>
                    <p className="guest-copy">
                      Capacidade: {tableType.capacity} pessoa(s)
                    </p>
                    <p className="guest-copy">
                      {tableType.description || "Tipo de mesa sem descricao."}
                    </p>
                  </div>
                  <span className="guest-service-tag">mesa</span>
                </div>
              ))}
            </div>
          </section>
        ) : null}

        <section className="guest-card guest-card-wide">
          <div className="aura-section-headline">
            <h3 className="aura-section-title">Operacao autenticada</h3>
            <span className="guest-card-label">Fluxo real</span>
          </div>
          {service.type === "room_service" && service.items?.length ? (
            <RoomServiceComposer
              token={token}
              service={service}
              moduleConfig={roomServiceModuleConfig}
              onOrderCreated={onOrderCreated}
            />
          ) : null}
          {service.type === "restaurant" ? (
            <RestaurantReservationComposer
              token={token}
              hotelId={hotel.id}
              service={service}
              moduleConfig={restaurantModuleConfig}
              onOrderCreated={onOrderCreated}
            />
          ) : null}
          {service.type === "activity" && service.items?.length ? (
            <ActivityBookingComposer
              token={token}
              hotelId={hotel.id}
              service={service}
              onOrderCreated={onOrderCreated}
            />
          ) : null}
          {service.moduleId === "concierge" ? (
            <ConciergeComposer
              token={token}
              service={service}
              moduleConfig={conciergeModuleConfig}
            />
          ) : null}
          <div className="guest-service-row">
            <div>
              <strong>Isolamento ativo</strong>
              <p className="guest-copy">
                Pedidos, reservas e mensagens continuam vinculados ao hotel e ao
                hospede autenticados pelo token da estadia.
              </p>
            </div>
          </div>
        </section>
      </>
    );
  }

  if (view.kind === "bookings") {
    return (
      <div className="guest-grid">
        <article className="guest-card guest-card-wide">
          <p className="guest-card-label">Reservas e pedidos</p>
          <h2 className="guest-card-title">Historico do hospede autenticado</h2>
          {ordersState.status === "loading" ? (
            <p className="guest-copy">Carregando pedidos do hospede...</p>
          ) : null}
          {ordersState.status === "error" ? (
            <p className="guest-error">
              Nao foi possivel carregar os pedidos autenticados do hospede.
            </p>
          ) : null}
          {ordersState.status === "ready" ? (
            <div className="guest-services-list">
              {ordersState.orders.length === 0 ? (
                <p className="guest-copy">Nenhum pedido ou reserva encontrado.</p>
              ) : (
                ordersState.orders.map((order) => (
                  <div key={order.id} className="guest-service-row">
                    <div>
                      <strong>{order.itemName}</strong>
                      <p className="guest-copy">
                        Status: {order.status} • Quantidade: {order.quantity}
                      </p>
                      <p className="guest-copy">
                        Tipo: {describeGuestOrder(order, services)}
                      </p>
                      {order.price != null ? (
                        <p className="guest-copy">
                          Valor:{" "}
                          {new Intl.NumberFormat("pt-BR", {
                            style: "currency",
                            currency: "BRL",
                          }).format(order.price)}
                        </p>
                      ) : null}
                      {order.createdAt ? (
                        <p className="guest-copy">
                          Criado em:{" "}
                          {new Intl.DateTimeFormat("pt-BR", {
                            dateStyle: "short",
                            timeStyle: "short",
                          }).format(new Date(order.createdAt))}
                        </p>
                      ) : null}
                    </div>
                    <span className="guest-service-tag">{order.status}</span>
                  </div>
                ))
              )}
            </div>
          ) : null}
        </article>
      </div>
    );
  }

  if (view.kind === "messages") {
    const conciergeModuleConfig = getConciergeModuleConfig(hotel.enabledModules);
    const conciergeService =
      services.find((entry) => entry.moduleId === "concierge") ?? {
        id: "virtual-concierge",
        name: conciergeModuleConfig.title?.trim() || "Concierge Sevvn",
        slug: "concierge",
        icon: "concierge",
        description:
          "Canal autenticado para conversar com a recepcao, solicitar apoio e coordenar demandas da estadia.",
        type: "activity" as const,
        moduleId: "concierge",
        bannerImageUrl: null,
      };

    return (
      <>
        <section className="aura-chat-hero">
          <div className="aura-chat-hero-avatar">
            <span className="material-symbols-outlined">concierge</span>
          </div>
          <div>
            <p className="guest-card-label">Canal autenticado</p>
            <h2 className="aura-section-title">
              {conciergeModuleConfig.title?.trim() || "Concierge"}
            </h2>
            <p className="guest-copy">
              Atendimento vinculado a esta estadia e isolado no hotel autenticado.
            </p>
          </div>
        </section>

        <section className="guest-card guest-card-wide">
          <ConciergeComposer
            token={token}
            service={conciergeService}
            moduleConfig={conciergeModuleConfig}
            variant="page"
          />
        </section>
      </>
    );
  }

  if (view.kind === "notices") {
    return (
      <>
        <section className="aura-directory-hero">
          <p className="guest-card-label">Recepcao e operacao</p>
          <h2 className="aura-directory-title">Notificacoes</h2>
          <p className="guest-copy aura-directory-copy">
            Avisos da estadia, atualizacoes operacionais e confirmacoes enviadas
            pelo hotel autenticado.
          </p>
        </section>

        <section className="aura-notices-list">
          {noticesState.status === "loading" ? (
            <article className="aura-notice-card">
              <div className="aura-notice-icon">
                <span className="material-symbols-outlined">notifications</span>
              </div>
              <div>
                <strong>Carregando avisos...</strong>
                <p className="guest-copy">Buscando mensagens da sua estadia.</p>
              </div>
            </article>
          ) : null}

          {noticesState.status === "error" ? (
            <article className="aura-notice-card">
              <div className="aura-notice-icon aura-notice-icon-alert">
                <span className="material-symbols-outlined">error</span>
              </div>
              <div>
                <strong>Nao foi possivel carregar os avisos</strong>
                <p className="guest-copy">
                  Tente novamente daqui a pouco ou confira com a recepcao.
                </p>
              </div>
            </article>
          ) : null}

          {noticesState.status === "ready"
            ? noticesState.notices.map((notice, index) => (
                <article key={notice.id} className="aura-notice-card">
                  <div
                    className={`aura-notice-icon${
                      index === 0 ? " aura-notice-icon-primary" : ""
                    }`}
                  >
                    <span className="material-symbols-outlined">
                      {index === 0 ? "hotel_class" : "notifications"}
                    </span>
                  </div>
                  <div className="aura-notice-body">
                    <div className="aura-notice-header">
                      <strong>{summarizeNoticeTitle(notice.message, index)}</strong>
                      <span>{formatNoticeTimestamp(notice.createdAt)}</span>
                    </div>
                    <p>{notice.message}</p>
                  </div>
                </article>
              ))
            : null}
        </section>

        {noticesState.status === "ready" && noticesState.notices.length === 0 ? (
          <section className="aura-empty-state">
            <span className="material-symbols-outlined">check_circle</span>
            <p>Voce esta em dia com os avisos da sua estadia.</p>
          </section>
        ) : null}
      </>
    );
  }

  if (view.kind === "profile") {
    return (
      <>
        <section className="aura-profile-header">
          <div className="aura-profile-avatar">
            <span className="material-symbols-outlined">person</span>
          </div>
          <h2>
            {session.guest.firstName} {session.guest.lastName}
          </h2>
          <span className="aura-status-pill">
            Hospede ativo • Quarto {session.guest.roomNumber}
          </span>
        </section>

        <section className="aura-profile-stats">
          <article className="aura-detail-meta-card">
            <p className="guest-card-label">Check-in</p>
            <strong>{formatGuestDate(session.guest.checkInDate)}</strong>
          </article>
          <article className="aura-detail-meta-card">
            <p className="guest-card-label">Check-out</p>
            <strong>{formatGuestDate(session.guest.checkOutDate)}</strong>
          </article>
          <article className="aura-detail-meta-card">
            <p className="guest-card-label">Hotel</p>
            <strong>{hotel.hotelInfo?.name ?? "Sevvn Hospitality"}</strong>
          </article>
        </section>

        <section className="aura-profile-list">
          <article className="aura-profile-list-item">
            <div className="aura-profile-list-icon">
              <span className="material-symbols-outlined">wifi</span>
            </div>
            <div>
              <strong>Conectividade da estadia</strong>
              <p>Rede: {session.guest.wifiNetworkName ?? "Nao informada"}</p>
              <p>Senha: {session.guest.wifiPassword ?? "Solicite a recepcao"}</p>
            </div>
          </article>

          <article className="aura-profile-list-item">
            <div className="aura-profile-list-icon">
              <span className="material-symbols-outlined">grid_view</span>
            </div>
            <div>
              <strong>Modulos habilitados</strong>
              <p>
                {hotel.enabledModules?.filter((module) => module.enabled).length ?? 0}{" "}
                modulos ativos para esta hospedagem.
              </p>
            </div>
          </article>

          <article className="aura-profile-list-item">
            <div className="aura-profile-list-icon">
              <span className="material-symbols-outlined">verified_user</span>
            </div>
            <div>
              <strong>Seguranca da sessao</strong>
              <p>
                Os dados exibidos aqui sao resolvidos a partir do token da estadia,
                sem troca manual de hotel no navegador.
              </p>
            </div>
          </article>
        </section>
      </>
    );
  }

  const wifiPassword = session.guest.wifiPassword;

  return (
    <>
      <section className="aura-residence-card">
        <div className="aura-residence-glow" aria-hidden="true" />
        <div className="aura-residence-header">
          <div>
            <p className="guest-card-label">Sua estadia</p>
            <h2 className="aura-residence-room">Quarto {session.guest.roomNumber}</h2>
          </div>
          <span className="aura-status-pill">
            {hotel.hotelInfo?.name ?? "Sevvn Hospitality"}
          </span>
        </div>

        <div className="aura-wifi-card">
          <span className="material-symbols-outlined aura-wifi-icon">wifi</span>
          <div className="aura-wifi-copy">
            <p className="guest-card-label">Wi-Fi do hotel</p>
            <strong>{session.guest.wifiNetworkName ?? "Rede nao informada"}</strong>
            <p className="guest-copy">
              Senha: {wifiPassword ?? "Solicite a recepcao"}
            </p>
          </div>
          {wifiPassword ? (
            <button
              type="button"
              className="aura-inline-icon-button"
              onClick={() => {
                if (typeof navigator === "undefined" || !navigator.clipboard) return;
                void navigator.clipboard.writeText(wifiPassword);
              }}
              aria-label="Copiar senha do Wi-Fi"
            >
              <span className="material-symbols-outlined">content_copy</span>
            </button>
          ) : null}
        </div>
      </section>

      <section className="aura-section-block">
        <div className="aura-section-headline">
          <h3 className="aura-section-title">Acessos rapidos</h3>
          <button type="button" className="aura-link-button" onClick={onOpenServices}>
            Ver servicos
          </button>
        </div>
        <div className="aura-action-grid">
          {resolvedModules.home.slice(0, 4).map((module) => (
            <div key={module.id} className="aura-action-tile-stack">
            <button
              type="button"
              className={`aura-action-tile${
                supportsModuleNavigation(module) ? "" : " aura-action-tile-disabled"
              }`}
              disabled={!supportsModuleNavigation(module)}
              onClick={() => {
                if (!supportsModuleNavigation(module)) {
                  return;
                }
                const nextView = viewForModule(module);
                if (nextView.kind === "home") {
                  onOpenServices();
                  return;
                }
                if (nextView.kind === "services") {
                  onOpenServices();
                  return;
                }
                if (nextView.kind === "bookings") {
                  onOpenBookings();
                  return;
                }
                if (nextView.kind === "messages") {
                  onOpenMessages();
                  return;
                }
                if (nextView.kind === "notices") {
                  onOpenNotices();
                  return;
                }
                if (nextView.kind === "profile") {
                  onOpenProfile();
                  return;
                }
                onOpenServices();
              }}
            >
              <span className="aura-action-tile-visual material-symbols-outlined">
                {iconForModule(module.id)}
              </span>
              <span className="aura-action-tile-label">{module.name}</span>
            </button>
            <span
              className={`aura-runtime-chip aura-runtime-chip-${getModuleRuntimeStatus(module)}`}
            >
              {describeRuntimeStatus(getModuleRuntimeStatus(module))}
            </span>
            </div>
          ))}
        </div>
      </section>

      <section className="aura-section-block">
        <div className="aura-section-headline">
          <h3 className="aura-section-title">Sua estadia</h3>
          <span className="guest-card-label">Contexto autenticado</span>
        </div>
        <div className="aura-stay-scroll">
          <article className="aura-stay-mini-card">
            <span className="material-symbols-outlined aura-stay-mini-icon">login</span>
            <p className="guest-card-label">Check-in</p>
            <strong>{formatGuestDate(session.guest.checkInDate)}</strong>
            <p className="guest-copy">Inicio da estadia</p>
          </article>
          <article className="aura-stay-mini-card">
            <span className="material-symbols-outlined aura-stay-mini-icon">logout</span>
            <p className="guest-card-label">Check-out</p>
            <strong>{formatGuestDate(session.guest.checkOutDate)}</strong>
            <p className="guest-copy">Encerramento previsto</p>
          </article>
          <article className="aura-stay-mini-card">
            <span className="material-symbols-outlined aura-stay-mini-icon">apps</span>
            <p className="guest-card-label">Modulos ativos</p>
            <strong>{hotel.enabledModules?.filter((module) => module.enabled).length ?? 0}</strong>
            <p className="guest-copy">Pacote habilitado neste hotel</p>
          </article>
        </div>
      </section>

      <section className="aura-promo-banner">
        {hotel.hotelInfo?.promoImages?.images?.[0] ? (
          <div
            className="aura-promo-media"
            style={{ backgroundImage: `url(${hotel.hotelInfo.promoImages.images[0]})` }}
          />
        ) : (
          <div className="aura-promo-media aura-promo-media-fallback" />
        )}
        <div className="aura-promo-overlay" />
        <div className="aura-promo-content">
          <span className="aura-promo-badge">EM BREVE</span>
          <h3>Experiencias e ofertas do hotel dentro do app</h3>
          <p>
            Esta superficie ja esta preparada para receber campanhas, destaques e
            beneficios conectados aos modulos habilitados pela Sevvn.
          </p>
        </div>
      </section>

      <section className="guest-card guest-card-wide">
        <div className="aura-section-headline">
          <h3 className="aura-section-title">Prontidao do pacote Essential</h3>
          <span className="guest-card-label">29/07/2026</span>
        </div>
        <div className="aura-status-matrix">
          {buildEssentialSurfaceStatuses(resolvedModules).map((entry) => (
            <article key={entry.id} className="aura-status-row">
              <div>
                <strong>{entry.label}</strong>
                <p className="guest-copy">{entry.description}</p>
              </div>
              <span className={`aura-runtime-chip aura-runtime-chip-${entry.status}`}>
                {describeRuntimeStatus(entry.status)}
              </span>
            </article>
          ))}
        </div>
      </section>

      <section className="guest-card guest-card-wide">
        <p className="guest-card-label">Isolamento de dados</p>
        <h2 className="guest-card-title">Base pronta para operacao segura</h2>
        <div className="guest-services-list">
          <div className="guest-service-row">
            <div>
              <strong>Hotel autenticado pelo claim</strong>
              <p className="guest-copy">
                O app monta esta home a partir do token do hospede e do
                `hotelId` validado no backend.
              </p>
            </div>
          </div>
          <div className="guest-service-row">
            <div>
              <strong>Superficies orientadas por modulo</strong>
              <p className="guest-copy">
                Home, servicos e reservas passam a refletir apenas o que esse hotel
                habilitou no pacote Sevvn.
              </p>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}

function formatGuestDate(dateValue: string): string {
  const parsed = new Date(dateValue);
  if (Number.isNaN(parsed.getTime())) {
    return dateValue;
  }

  return new Intl.DateTimeFormat("pt-BR", {
    dateStyle: "medium",
  }).format(parsed);
}

function formatItemPrice(price: number | null | undefined): string {
  if (price == null) {
    return "sob consulta";
  }

  return new Intl.NumberFormat("pt-BR", {
    style: "currency",
    currency: "BRL",
  }).format(price);
}

function formatNoticeTimestamp(dateValue: string): string {
  const parsed = new Date(dateValue);
  if (Number.isNaN(parsed.getTime())) {
    return dateValue;
  }

  return new Intl.DateTimeFormat("pt-BR", {
    dateStyle: "short",
    timeStyle: "short",
  }).format(parsed);
}

function summarizeNoticeTitle(message: string, index: number): string {
  const normalized = message.trim();
  if (!normalized) {
    return index === 0 ? "Novo aviso da estadia" : "Aviso da recepcao";
  }

  const [firstSentence] = normalized.split(/[.!?]/);
  const compact = firstSentence.trim();
  if (compact.length <= 54) {
    return compact;
  }

  return `${compact.slice(0, 51).trimEnd()}...`;
}

function describeRuntimeStatus(
  status: "live" | "gated" | "coming_soon",
): string {
  if (status === "live") return "ao vivo";
  if (status === "gated") return "por modulo";
  return "em breve";
}

function buildEssentialSurfaceStatuses(
  resolvedModules: ResolvedModulesShape,
): Array<{
  id: string;
  label: string;
  description: string;
  status: "live" | "gated" | "coming_soon";
}> {
  const hasModule = (id: string) =>
    resolvedModules.home.some((module) => module.id === id) ||
    resolvedModules.bottomNav.some((module) => module.id === id) ||
    resolvedModules.servicesMenu.some((module) => module.id === id);

  return [
    {
      id: "home",
      label: "Home da hospedagem",
      description: "Quarto, Wi-Fi, datas da estadia e atalhos essenciais.",
      status: "live",
    },
    {
      id: "services",
      label: "Directory de servicos",
      description: "Catalogo real do hotel, agrupado por modulo e servico.",
      status: "live",
    },
    {
      id: "orders",
      label: "Pedidos e reservas",
      description: "Historico autenticado do hospede com pedidos e reservas.",
      status: "live",
    },
    {
      id: "messages",
      label: "Concierge / mensagens",
      description: "Conversa com a recepcao pelo token da estadia.",
      status: hasModule("messages") || hasModule("concierge") ? "live" : "gated",
    },
    {
      id: "notifications",
      label: "Notificacoes basicas",
      description: "Avisos da estadia enviados pelo hotel autenticado.",
      status: hasModule("basic_notifications") ? "live" : "gated",
    },
    {
      id: "profile",
      label: "Perfil / contexto da estadia",
      description: "Identidade do hospede, hotel e seguranca da sessao.",
      status: "live",
    },
    {
      id: "wallet",
      label: "Carteira / fidelidade",
      description: "Superficies ainda nao portadas para o corte Essential do Aura.",
      status: "coming_soon",
    },
  ];
}

function RoomServiceComposer({
  token,
  service,
  moduleConfig,
  onOrderCreated,
}: RoomServiceComposerProps) {
  const orderableItems = (service.items ?? []).filter((item) => !item.isMinibarItem);
  const minibarItems = (service.items ?? []).filter((item) => item.isMinibarItem);
  const showMinibar = moduleConfig.showMinibarInGuestApp !== false;
  const allowGuestConsumptionReports =
    moduleConfig.allowGuestConsumptionReports !== false;

  const [selectedItemId, setSelectedItemId] = useState(orderableItems[0]?.id ?? "");
  const [quantity, setQuantity] = useState("1");
  const [note, setNote] = useState("");
  const [status, setStatus] = useState<"idle" | "submitting" | "success" | "error">(
    "idle",
  );
  const [message, setMessage] = useState<string | null>(null);
  const [minibarState, setMinibarState] = useState<{
    status: "idle" | "submitting" | "success" | "error";
    itemId: string | null;
    message: string | null;
  }>({
    status: "idle",
    itemId: null,
    message: null,
  });

  useEffect(() => {
    setSelectedItemId(orderableItems[0]?.id ?? "");
    setQuantity("1");
    setNote("");
    setStatus("idle");
    setMessage(null);
    setMinibarState({ status: "idle", itemId: null, message: null });
  }, [orderableItems, service.id]);

  const selectedItem = orderableItems.find((item) => item.id === selectedItemId) ?? null;

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!selectedItem) {
      setStatus("error");
      setMessage("Selecione um item valido para continuar.");
      return;
    }

    const parsedQuantity = Number.parseInt(quantity, 10);
    if (!Number.isInteger(parsedQuantity) || parsedQuantity < 1) {
      setStatus("error");
      setMessage("Informe uma quantidade valida.");
      return;
    }

    setStatus("submitting");
    setMessage(null);

    try {
      const order = await createGuestOrder({
        token,
        serviceId: service.id,
        serviceItemId: selectedItem.id,
        quantity: parsedQuantity,
        note,
      });

      onOrderCreated(order);
      setStatus("success");
      setMessage("Pedido enviado com sucesso para o hotel.");
      setQuantity("1");
      setNote("");
    } catch (error) {
      setStatus("error");
      setMessage(
        error instanceof Error
          ? error.message
          : "Nao foi possivel enviar o pedido agora.",
      );
    }
  }

  async function handleMinibarReport(item: ServiceItem) {
    setMinibarState({
      status: "submitting",
      itemId: item.id,
      message: null,
    });

    try {
      const order = await createGuestOrder({
        token,
        serviceId: service.id,
        serviceItemId: item.id,
        quantity: 1,
        consumptionReport: true,
      });

      onOrderCreated(order);
      setMinibarState({
        status: "success",
        itemId: item.id,
        message: `Consumo de ${item.name} informado com sucesso.`,
      });
    } catch (error) {
      setMinibarState({
        status: "error",
        itemId: item.id,
        message:
          error instanceof Error
            ? error.message
            : "Nao foi possivel informar o consumo agora.",
      });
    }
  }

  return (
    <section className="guest-order-panel">
      <div>
        <strong>Pedido autenticado de room service</strong>
        <p className="guest-copy">
          Este envio usa o token do hospede e o pedido nasce no mesmo hotel da
          sessao autenticada.
        </p>
      </div>

      {orderableItems.length > 0 ? (
        <form className="guest-order-form" onSubmit={handleSubmit}>
          <label className="guest-order-field">
            <span className="guest-label">Item</span>
            <select
              className="guest-select"
              value={selectedItemId}
              onChange={(event) => setSelectedItemId(event.target.value)}
            >
              {orderableItems.map((item) => (
                <option key={item.id} value={item.id}>
                  {formatRoomServiceItemLabel(item)}
                </option>
              ))}
            </select>
          </label>

          <label className="guest-order-field">
            <span className="guest-label">Quantidade</span>
            <input
              className="guest-input"
              inputMode="numeric"
              pattern="[0-9]*"
              value={quantity}
              onChange={(event) => setQuantity(event.target.value)}
            />
          </label>

          <label className="guest-order-field guest-order-field-wide">
            <span className="guest-label">Observacao</span>
            <textarea
              className="guest-textarea"
              rows={4}
              value={note}
              onChange={(event) => setNote(event.target.value)}
              placeholder="Ex.: sem cebola, entregar apos 20h."
            />
          </label>

          <div className="guest-order-summary guest-order-field-wide">
            <strong>Resumo</strong>
            <p className="guest-copy">
              {selectedItem ? formatRoomServiceItemLabel(selectedItem) : "Nenhum item selecionado"}
            </p>
          </div>

          <div className="guest-order-actions guest-order-field-wide">
            <button
              type="submit"
              className="guest-button"
              disabled={status === "submitting" || !selectedItem}
            >
              {status === "submitting" ? "Enviando..." : "Enviar pedido"}
            </button>
            {message ? (
              <p className={status === "error" ? "guest-error" : "guest-success"}>
                {message}
              </p>
            ) : null}
          </div>
        </form>
      ) : (
        <div className="guest-order-summary">
          <strong>Pedido normal</strong>
          <p className="guest-copy">
            Este servico nao possui itens de pedido tradicional ativos no momento.
          </p>
        </div>
      )}

      {showMinibar && minibarItems.length > 0 ? (
        <div className="guest-minibar-panel">
          <div>
            <strong>Frigobar do quarto</strong>
            <p className="guest-copy">
              Estes itens usam o fluxo de consumo informado. O lancamento entra
              na conta do quarto do hospede autenticado.
            </p>
          </div>

          <div className="guest-services-list">
            {minibarItems.map((item) => (
              <div key={item.id} className="guest-service-row">
                <div>
                  <strong>{item.name}</strong>
                  <p className="guest-copy">{item.description || "Sem descricao."}</p>
                  <p className="guest-copy">{formatRoomServiceItemLabel(item)}</p>
                </div>
                <div className="guest-minibar-actions">
                  <button
                    type="button"
                    className="guest-secondary-button"
                    disabled={
                      !allowGuestConsumptionReports ||
                      (minibarState.status === "submitting" &&
                        minibarState.itemId === item.id)
                    }
                    onClick={() => void handleMinibarReport(item)}
                  >
                    {!allowGuestConsumptionReports
                      ? "Indisponivel no app"
                      : minibarState.status === "submitting" &&
                        minibarState.itemId === item.id
                      ? "Informando..."
                      : "Informar consumo"}
                  </button>
                </div>
              </div>
            ))}
          </div>

          {!allowGuestConsumptionReports ? (
            <p className="guest-copy">
              Este hotel optou por nao permitir que o hospede informe consumo
              de frigobar diretamente pelo app.
            </p>
          ) : null}

          {minibarState.message ? (
            <p
              className={
                minibarState.status === "error" ? "guest-error" : "guest-success"
              }
            >
              {minibarState.message}
            </p>
          ) : null}
        </div>
      ) : null}
    </section>
  );
}

function RestaurantReservationComposer({
  token,
  hotelId,
  service,
  moduleConfig,
  onOrderCreated,
}: RestaurantReservationComposerProps) {
  const bookingMode = moduleConfig.bookingMode ?? "party_size_only";
  const maxPartySize = moduleConfig.maxPartySize ?? 12;
  const today = new Date();
  const [partySize, setPartySize] = useState("2");
  const [dateValue, setDateValue] = useState(formatDateInputValue(today));
  const [timeValue, setTimeValue] = useState("19:00");
  const [availabilityState, setAvailabilityState] = useState<{
    status: "idle" | "loading" | "ready" | "error";
    tableTypes: GuestTableAvailabilityItem[];
    message: string | null;
  }>({
    status: "idle",
    tableTypes: [],
    message: null,
  });
  const [selectedTableTypeId, setSelectedTableTypeId] = useState("");
  const [status, setStatus] = useState<"idle" | "submitting" | "success" | "error">(
    "idle",
  );
  const [message, setMessage] = useState<string | null>(null);

  const needsExplicitTableType =
    bookingMode === "table_type_selection" || bookingMode === "hybrid";

  async function handleCheckAvailability() {
    const scheduledFor = buildScheduledForIso(dateValue, timeValue);
    if (!scheduledFor) {
      setAvailabilityState({
        status: "error",
        tableTypes: [],
        message: "Informe uma data e um horario validos para consultar.",
      });
      return;
    }

    setAvailabilityState({
      status: "loading",
      tableTypes: [],
      message: null,
    });
    setSelectedTableTypeId("");
    setMessage(null);
    setStatus("idle");

    try {
      const response = await getGuestRestaurantTableAvailability(
        hotelId,
        service.id,
        scheduledFor,
      );
      const availableTableTypes = response.tableTypes.filter(
        (tableType) => tableType.availableQuantity > 0,
      );
      setAvailabilityState({
        status: "ready",
        tableTypes: availableTableTypes,
        message:
          availableTableTypes.length > 0
            ? null
            : "Nao ha mesas disponiveis nesse horario no momento.",
      });
    } catch (error) {
      setAvailabilityState({
        status: "error",
        tableTypes: [],
        message:
          error instanceof Error
            ? error.message
            : "Nao foi possivel consultar a disponibilidade.",
      });
    }
  }

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();

    const parsedPartySize = Number.parseInt(partySize, 10);
    if (!Number.isInteger(parsedPartySize) || parsedPartySize < 1 || parsedPartySize > maxPartySize) {
      setStatus("error");
      setMessage(`Informe uma quantidade valida entre 1 e ${maxPartySize} pessoa(s).`);
      return;
    }

    const scheduledFor = buildScheduledForIso(dateValue, timeValue);
    if (!scheduledFor) {
      setStatus("error");
      setMessage("Informe uma data e um horario validos para reservar.");
      return;
    }

    let tableTypeId: string | undefined;
    if (availabilityState.status === "ready") {
      if (needsExplicitTableType) {
        if (!selectedTableTypeId) {
          setStatus("error");
          setMessage("Selecione um tipo de mesa disponivel para concluir a reserva.");
          return;
        }
        tableTypeId = selectedTableTypeId;
      } else {
        tableTypeId = inferBestTableTypeId(availabilityState.tableTypes, parsedPartySize);
        if (!tableTypeId && availabilityState.tableTypes.length > 0) {
          setStatus("error");
          setMessage("Nao encontramos uma mesa compativel com essa quantidade de pessoas.");
          return;
        }
      }
    }

    setStatus("submitting");
    setMessage(null);

    try {
      const order = await createGuestOrder({
        token,
        serviceId: service.id,
        scheduledFor,
        tableTypeId,
        quantity: 1,
      });

      onOrderCreated(order);
      setStatus("success");
      setMessage("Reserva de mesa enviada com sucesso.");
    } catch (error) {
      setStatus("error");
      setMessage(
        error instanceof Error
          ? error.message
          : "Nao foi possivel concluir a reserva agora.",
      );
    }
  }

  return (
    <section className="guest-order-panel">
      <div>
        <strong>Reserva autenticada de restaurante</strong>
        <p className="guest-copy">
          O hospede informa mesa para quantas pessoas, dia e horario. A reserva
          fica vinculada ao hotel autenticado e pode operar no modo{" "}
          <strong>{describeRestaurantBookingMode(bookingMode)}</strong>.
        </p>
        <p className="guest-copy">
          {moduleConfig.reservationExpiryMinutes
            ? `Tempo limite atual da reserva: ${moduleConfig.reservationExpiryMinutes} minuto(s) antes de expirar.`
            : "Tempo limite da reserva ainda nao configurado pelo hotel."}
        </p>
        <p className="guest-copy">
          {moduleConfig.waitlistEnabled
            ? `Fila de espera habilitada${typeof moduleConfig.waitlistCapacity === "number" ? ` (capacidade atual: ${moduleConfig.waitlistCapacity})` : ""}.`
            : "Fila de espera nao habilitada neste restaurante."}
        </p>
      </div>

      <form className="guest-order-form" onSubmit={handleSubmit}>
        <label className="guest-order-field">
          <span className="guest-label">Mesa para quantas pessoas</span>
          <input
            className="guest-input"
            inputMode="numeric"
            pattern="[0-9]*"
            value={partySize}
            onChange={(event) => setPartySize(event.target.value)}
          />
        </label>

        <label className="guest-order-field">
          <span className="guest-label">Data</span>
          <input
            className="guest-input"
            type="date"
            value={dateValue}
            min={formatDateInputValue(today)}
            onChange={(event) => setDateValue(event.target.value)}
          />
        </label>

        <label className="guest-order-field">
          <span className="guest-label">Horario</span>
          <input
            className="guest-input"
            type="time"
            value={timeValue}
            onChange={(event) => setTimeValue(event.target.value)}
          />
        </label>

        <div className="guest-order-actions">
          <button
            type="button"
            className="guest-secondary-button"
            onClick={() => void handleCheckAvailability()}
            disabled={availabilityState.status === "loading"}
          >
            {availabilityState.status === "loading"
              ? "Consultando..."
              : "Consultar disponibilidade"}
          </button>
        </div>

        {needsExplicitTableType ? (
          <label className="guest-order-field guest-order-field-wide">
            <span className="guest-label">Tipo de mesa</span>
            <select
              className="guest-select"
              value={selectedTableTypeId}
              onChange={(event) => setSelectedTableTypeId(event.target.value)}
              disabled={availabilityState.status !== "ready"}
            >
              <option value="">Selecione um tipo disponivel</option>
              {availabilityState.tableTypes.map((tableType) => (
                <option key={tableType.id} value={tableType.id}>
                  {formatTableTypeLabel(tableType)}
                </option>
              ))}
            </select>
          </label>
        ) : null}

        <div className="guest-order-summary guest-order-field-wide">
          <strong>Disponibilidade</strong>
          {availabilityState.status === "ready" && availabilityState.tableTypes.length > 0 ? (
            <div className="guest-chip-list">
              {availabilityState.tableTypes.map((tableType) => (
                <span key={tableType.id} className="guest-chip">
                  {formatTableTypeLabel(tableType)}
                </span>
              ))}
            </div>
          ) : (
            <p className="guest-copy">
              {availabilityState.message ??
                "Consulte a disponibilidade para ver as mesas ativas nesse horario."}
            </p>
          )}
          {availabilityState.status === "ready" &&
          availabilityState.tableTypes.length === 0 &&
          moduleConfig.waitlistEnabled ? (
            <p className="guest-copy">
              Sem mesa disponivel agora. O proximo passo aqui sera conectar a
              entrada do hospede na fila de espera do restaurante.
            </p>
          ) : null}
        </div>

        <div className="guest-order-actions guest-order-field-wide">
          <button type="submit" className="guest-button" disabled={status === "submitting"}>
            {status === "submitting" ? "Reservando..." : "Reservar mesa"}
          </button>
          {message ? (
            <p className={status === "error" ? "guest-error" : "guest-success"}>
              {message}
            </p>
          ) : null}
        </div>
      </form>
    </section>
  );
}

function ActivityBookingComposer({
  token,
  hotelId,
  service,
  onOrderCreated,
}: ActivityBookingComposerProps) {
  const schedulableItems = (service.items ?? []).filter(
    (item) => item.durationMinutes != null,
  );
  const [selectedItemId, setSelectedItemId] = useState(
    schedulableItems[0]?.id ?? "",
  );
  const [dateValue, setDateValue] = useState(formatDateInputValue(new Date()));
  const [selectedTime, setSelectedTime] = useState("");
  const [note, setNote] = useState("");
  const [availabilityState, setAvailabilityState] = useState<{
    status: "idle" | "loading" | "ready" | "error";
    response: GuestItemAvailabilityResponse | null;
    message: string | null;
  }>({
    status: "idle",
    response: null,
    message: null,
  });
  const [status, setStatus] = useState<"idle" | "submitting" | "success" | "error">(
    "idle",
  );
  const [message, setMessage] = useState<string | null>(null);

  useEffect(() => {
    setSelectedItemId(schedulableItems[0]?.id ?? "");
    setSelectedTime("");
    setNote("");
    setAvailabilityState({ status: "idle", response: null, message: null });
    setStatus("idle");
    setMessage(null);
  }, [service.id, schedulableItems]);

  const selectedItem =
    schedulableItems.find((item) => item.id === selectedItemId) ?? null;

  async function handleCheckAvailability() {
    if (!selectedItemId || !dateValue) {
      setAvailabilityState({
        status: "error",
        response: null,
        message: "Selecione um item e uma data para consultar.",
      });
      return;
    }

    setAvailabilityState({
      status: "loading",
      response: null,
      message: null,
    });
    setSelectedTime("");
    setStatus("idle");
    setMessage(null);

    try {
      const response = await getGuestItemAvailability(
        hotelId,
        service.id,
        selectedItemId,
        dateValue,
      );

      setAvailabilityState({
        status: "ready",
        response,
        message:
          response.schedulingEnabled && (response.slots?.length ?? 0) === 0
            ? "Nao ha horarios disponiveis nessa data."
            : null,
      });
    } catch (error) {
      setAvailabilityState({
        status: "error",
        response: null,
        message:
          error instanceof Error
            ? error.message
            : "Nao foi possivel consultar a disponibilidade.",
      });
    }
  }

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!selectedItem) {
      setStatus("error");
      setMessage("Selecione um item valido para reservar.");
      return;
    }

    if (!selectedTime) {
      setStatus("error");
      setMessage("Escolha um horario disponivel para concluir a reserva.");
      return;
    }

    const scheduledFor = buildScheduledForIso(dateValue, selectedTime);
    if (!scheduledFor) {
      setStatus("error");
      setMessage("Nao foi possivel montar a data e o horario da reserva.");
      return;
    }

    setStatus("submitting");
    setMessage(null);

    try {
      const order = await createGuestOrder({
        token,
        serviceId: service.id,
        serviceItemId: selectedItem.id,
        scheduledFor,
        quantity: 1,
        note,
      });

      onOrderCreated(order);
      setStatus("success");
      setMessage("Reserva enviada com sucesso para o hotel.");
    } catch (error) {
      setStatus("error");
      setMessage(
        error instanceof Error
          ? error.message
          : "Nao foi possivel concluir a reserva agora.",
      );
    }
  }

  return (
    <section className="guest-order-panel">
      <div>
        <strong>Reserva autenticada de passeio / atividade</strong>
        <p className="guest-copy">
          O hospede consulta os slots ativos e reserva no escopo do hotel autenticado.
        </p>
      </div>

      {schedulableItems.length > 0 ? (
        <form className="guest-order-form" onSubmit={handleSubmit}>
          <label className="guest-order-field">
            <span className="guest-label">Experiencia</span>
            <select
              className="guest-select"
              value={selectedItemId}
              onChange={(event) => setSelectedItemId(event.target.value)}
            >
              {schedulableItems.map((item) => (
                <option key={item.id} value={item.id}>
                  {item.name}
                </option>
              ))}
            </select>
          </label>

          <label className="guest-order-field">
            <span className="guest-label">Data</span>
            <input
              className="guest-input"
              type="date"
              value={dateValue}
              onChange={(event) => setDateValue(event.target.value)}
            />
          </label>

          <div className="guest-order-actions guest-order-field-wide">
            <button
              type="button"
              className="guest-secondary-button"
              onClick={() => void handleCheckAvailability()}
              disabled={availabilityState.status === "loading"}
            >
              {availabilityState.status === "loading"
                ? "Consultando..."
                : "Consultar horarios"}
            </button>
          </div>

          <label className="guest-order-field guest-order-field-wide">
            <span className="guest-label">Horario</span>
            <select
              className="guest-select"
              value={selectedTime}
              onChange={(event) => setSelectedTime(event.target.value)}
              disabled={availabilityState.status !== "ready"}
            >
              <option value="">Selecione um horario disponivel</option>
              {availabilityState.response?.slots
                ?.filter((slot) => slot.available)
                .map((slot: GuestScheduledSlot) => (
                  <option key={slot.time} value={slot.time}>
                    {slot.time}
                  </option>
                ))}
            </select>
          </label>

          <label className="guest-order-field guest-order-field-wide">
            <span className="guest-label">Observacao</span>
            <textarea
              className="guest-textarea"
              rows={4}
              value={note}
              onChange={(event) => setNote(event.target.value)}
              placeholder="Ex.: casal, nivel intermediario, levar criancas."
            />
          </label>

          <div className="guest-order-summary guest-order-field-wide">
            <strong>Disponibilidade</strong>
            {availabilityState.status === "ready" &&
            availabilityState.response?.slots?.length ? (
              <div className="guest-chip-list">
                {availabilityState.response.slots.map((slot) => (
                  <span
                    key={slot.time}
                    className={`guest-chip${slot.available ? "" : " guest-chip-disabled"}`}
                  >
                    {slot.time} {slot.available ? "• disponivel" : "• lotado"}
                  </span>
                ))}
              </div>
            ) : (
              <p className="guest-copy">
                {availabilityState.message ??
                  "Consulte os horarios para ver a grade disponivel."}
              </p>
            )}
            {selectedItem?.durationMinutes ? (
              <p className="guest-copy">
                Duracao prevista: {selectedItem.durationMinutes} minuto(s).
              </p>
            ) : null}
          </div>

          <div className="guest-order-actions guest-order-field-wide">
            <button
              type="submit"
              className="guest-button"
              disabled={status === "submitting" || !selectedItem}
            >
              {status === "submitting" ? "Reservando..." : "Reservar horario"}
            </button>
            {message ? (
              <p className={status === "error" ? "guest-error" : "guest-success"}>
                {message}
              </p>
            ) : null}
          </div>
        </form>
      ) : (
        <div className="guest-order-summary">
          <strong>Agenda do servico</strong>
          <p className="guest-copy">
            Este servico ainda nao possui itens com agenda ativa.
          </p>
        </div>
      )}
    </section>
  );
}

function formatRoomServiceItemLabel(item: ServiceItem): string {
  if (item.price == null) {
    return `${item.name} • sob consulta`;
  }

  return `${item.name} • ${new Intl.NumberFormat("pt-BR", {
    style: "currency",
    currency: "BRL",
  }).format(item.price)}`;
}

function describeGuestOrder(order: GuestOrder, services: GuestService[]): string {
  const service = services.find((entry) => entry.id === order.serviceId);
  if (!service) return "Servico do hotel";

  if (service.type === "restaurant" && order.serviceItemId == null) {
    return "Reserva de mesa";
  }

  const matchedItem =
    service.items?.find((item) => item.id === order.serviceItemId) ?? null;

  if (matchedItem?.isMinibarItem) {
    return "Consumo de frigobar";
  }

  if (service.type === "room_service") {
    return "Pedido de room service";
  }

  if (service.type === "restaurant") {
    return "Item do cardapio";
  }

  return "Reserva ou pedido";
}

function getRestaurantModuleConfig(
  enabledModules: GuestHotelConfig["enabledModules"],
): RestaurantModuleConfig {
  const moduleEntry = enabledModules?.find((entry) => entry.id === "restaurant");
  const configuration = moduleEntry?.configuration ?? {};

  return {
    bookingMode: isRestaurantBookingMode(configuration.bookingMode)
      ? configuration.bookingMode
      : undefined,
    showMenuInGuestApp:
      typeof configuration.showMenuInGuestApp === "boolean"
        ? configuration.showMenuInGuestApp
        : undefined,
    showMenuPrices:
      typeof configuration.showMenuPrices === "boolean"
        ? configuration.showMenuPrices
        : undefined,
    maxPartySize:
      typeof configuration.maxPartySize === "number"
        ? configuration.maxPartySize
        : undefined,
    waitlistEnabled:
      typeof configuration.waitlistEnabled === "boolean"
        ? configuration.waitlistEnabled
        : undefined,
    waitlistCapacity:
      typeof configuration.waitlistCapacity === "number"
        ? configuration.waitlistCapacity
        : undefined,
    reservationExpiryMinutes:
      typeof configuration.reservationExpiryMinutes === "number"
        ? configuration.reservationExpiryMinutes
        : undefined,
    tableInventorySource:
      configuration.tableInventorySource === "sevvn" ||
      configuration.tableInventorySource === "external" ||
      configuration.tableInventorySource === "hybrid"
        ? configuration.tableInventorySource
        : undefined,
  };
}

function getRoomServiceModuleConfig(
  enabledModules: GuestHotelConfig["enabledModules"],
): RoomServiceModuleConfig {
  const moduleEntry = enabledModules?.find((entry) => entry.id === "room_service");
  const configuration = moduleEntry?.configuration ?? {};

  return {
    showMinibarInGuestApp:
      typeof configuration.showMinibarInGuestApp === "boolean"
        ? configuration.showMinibarInGuestApp
        : undefined,
    allowGuestConsumptionReports:
      typeof configuration.allowGuestConsumptionReports === "boolean"
        ? configuration.allowGuestConsumptionReports
        : undefined,
    allowStaffConsumptionLaunch:
      typeof configuration.allowStaffConsumptionLaunch === "boolean"
        ? configuration.allowStaffConsumptionLaunch
        : undefined,
    fulfillmentMode:
      configuration.fulfillmentMode === "sevvn" ||
      configuration.fulfillmentMode === "external" ||
      configuration.fulfillmentMode === "hybrid"
        ? configuration.fulfillmentMode
        : undefined,
  };
}

function getConciergeModuleConfig(
  enabledModules: GuestHotelConfig["enabledModules"],
): ConciergeModuleConfig {
  const moduleEntry = enabledModules?.find((entry) => entry.id === "concierge");
  const configuration = moduleEntry?.configuration ?? {};

  return {
    title:
      typeof configuration.title === "string" ? configuration.title : undefined,
    openingHours:
      typeof configuration.openingHours === "string"
        ? configuration.openingHours
        : undefined,
    requestCategories: Array.isArray(configuration.requestCategories)
      ? configuration.requestCategories.filter(
          (value): value is string => typeof value === "string" && value.trim().length > 0,
        )
      : undefined,
    responseSlaMinutes:
      typeof configuration.responseSlaMinutes === "number"
        ? configuration.responseSlaMinutes
        : undefined,
    showEstimatedResponseTime:
      typeof configuration.showEstimatedResponseTime === "boolean"
        ? configuration.showEstimatedResponseTime
        : undefined,
    allowFileAttachments:
      typeof configuration.allowFileAttachments === "boolean"
        ? configuration.allowFileAttachments
        : undefined,
    escalationMode:
      configuration.escalationMode === "manual" ||
      configuration.escalationMode === "automatic" ||
      configuration.escalationMode === "hybrid"
        ? configuration.escalationMode
        : undefined,
  };
}

function ConciergeComposer({
  token,
  service,
  moduleConfig,
  variant = "inline",
}: ConciergeComposerProps) {
  const [messagesState, setMessagesState] = useState<{
    status: "idle" | "loading" | "ready" | "error";
    messages: GuestMessage[];
  }>({
    status: "idle",
    messages: [],
  });
  const [draft, setDraft] = useState("");
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [isSending, startSendingTransition] = useTransition();

  useEffect(() => {
    let cancelled = false;
    setMessagesState((current) => ({
      status: current.messages.length > 0 ? "ready" : "loading",
      messages: current.messages,
    }));

    void getGuestMessages(token)
      .then((messages) => {
        if (cancelled) return;
        setMessagesState({ status: "ready", messages });
      })
      .catch(() => {
        if (cancelled) return;
        setMessagesState({ status: "error", messages: [] });
      });

    return () => {
      cancelled = true;
    };
  }, [token]);

  function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const message = draft.trim();
    if (!message) return;

    setSubmitError(null);

    startSendingTransition(() => {
      void sendGuestMessage(token, message)
        .then((createdMessage) => {
          setDraft("");
          setMessagesState((current) => ({
            status: "ready",
            messages: [...current.messages, createdMessage],
          }));
        })
        .catch(() => {
          setSubmitError("Nao foi possivel enviar sua mensagem agora.");
        });
    });
  }

  return (
    <>
      <div className={variant === "page" ? "aura-chat-meta" : "guest-service-row"}>
        <div>
          <strong>{moduleConfig.title?.trim() || service.name}</strong>
          <p className="guest-copy">
            Atendimento autenticado pela estadia atual, sempre isolado no hotel
            do hospede.
          </p>
          {moduleConfig.openingHours ? (
            <p className="guest-copy">Horario: {moduleConfig.openingHours}</p>
          ) : null}
          {moduleConfig.showEstimatedResponseTime !== false &&
          moduleConfig.responseSlaMinutes ? (
            <p className="guest-copy">
              Tempo medio estimado: ate {moduleConfig.responseSlaMinutes} minuto(s).
            </p>
          ) : null}
          {moduleConfig.allowFileAttachments === false ? (
            <p className="guest-copy">
              Envio de anexos ainda nao esta habilitado para este hotel.
            </p>
          ) : null}
        </div>
        <span className="guest-service-tag">concierge</span>
      </div>

      {moduleConfig.requestCategories?.length ? (
        <div className={variant === "page" ? "aura-chat-quick-actions" : "guest-service-row"}>
          <div>
            <strong>Categorias de atendimento</strong>
            <div className="guest-chip-list">
              {moduleConfig.requestCategories.map((category) => (
                <span key={category} className="guest-chip">
                  {category}
                </span>
              ))}
            </div>
          </div>
        </div>
      ) : null}

      <div className={variant === "page" ? "aura-chat-surface" : "guest-service-row"}>
        <div style={{ width: "100%" }}>
          <strong>Conversa com a equipe</strong>
          <p className="guest-copy">
            Use este canal para pedidos personalizados, reservas externas,
            transfer, duvidas e apoio durante a estadia.
          </p>

          {messagesState.status === "loading" ? (
            <p className="guest-copy">Carregando historico da conversa...</p>
          ) : null}

          {messagesState.status === "error" ? (
            <p className="guest-error">
              Nao foi possivel carregar o historico do concierge.
            </p>
          ) : null}

          {messagesState.status === "ready" ? (
            <div className={variant === "page" ? "aura-message-thread" : "guest-services-list"}>
              {messagesState.messages.length === 0 ? (
                <p className="guest-copy">
                  Nenhuma conversa iniciada ainda. Envie a primeira mensagem.
                </p>
              ) : (
                messagesState.messages.map((message) => (
                  <div
                    key={message.id}
                    className={
                      variant === "page"
                        ? `aura-message-bubble-wrap${
                            message.senderType === "guest"
                              ? " aura-message-bubble-wrap-guest"
                              : ""
                          }`
                        : "guest-service-row"
                    }
                  >
                    <div
                      className={
                        variant === "page"
                          ? `aura-message-bubble${
                              message.senderType === "guest"
                                ? " aura-message-bubble-guest"
                                : " aura-message-bubble-staff"
                            }`
                          : ""
                      }
                    >
                      <strong>
                        {message.senderType === "guest"
                          ? "Voce"
                          : "Equipe do hotel"}
                      </strong>
                      <p className="guest-copy">{message.body}</p>
                      <p className="guest-copy">
                        {new Intl.DateTimeFormat("pt-BR", {
                          dateStyle: "short",
                          timeStyle: "short",
                        }).format(new Date(message.createdAt))}
                      </p>
                    </div>
                    {variant === "page" ? null : (
                      <span className="guest-service-tag">
                        {message.senderType === "guest" ? "enviado" : "recebido"}
                      </span>
                    )}
                  </div>
                ))
              )}
            </div>
          ) : null}

          <form
            className={variant === "page" ? "aura-chat-input-shell" : "guest-form"}
            onSubmit={handleSubmit}
          >
            <label className="guest-label" htmlFor={`concierge-message-${service.id}`}>
              Nova mensagem
            </label>
            <textarea
              id={`concierge-message-${service.id}`}
              className={variant === "page" ? "guest-input aura-chat-textarea" : "guest-input"}
              rows={4}
              value={draft}
              onChange={(event) => setDraft(event.target.value)}
              placeholder="Ex.: preciso de transfer para o aeroporto as 06:30."
            />
            <button
              type="submit"
              className="guest-button"
              disabled={isSending || !draft.trim()}
            >
              {isSending ? "Enviando..." : "Enviar para concierge"}
            </button>
          </form>

          {submitError ? <p className="guest-error">{submitError}</p> : null}
        </div>
      </div>
    </>
  );
}

function isRestaurantBookingMode(value: unknown): value is RestaurantBookingMode {
  return (
    value === "party_size_only" ||
    value === "table_type_selection" ||
    value === "hybrid"
  );
}

function describeRestaurantBookingMode(mode: RestaurantBookingMode): string {
  if (mode === "table_type_selection") return "selecao de tipo de mesa";
  if (mode === "hybrid") return "hibrido";
  return "mesa por quantidade de pessoas";
}

function formatDateInputValue(date: Date): string {
  const year = date.getFullYear();
  const month = `${date.getMonth() + 1}`.padStart(2, "0");
  const day = `${date.getDate()}`.padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function buildScheduledForIso(dateValue: string, timeValue: string): string | null {
  if (!dateValue || !timeValue) return null;
  const parsed = new Date(`${dateValue}T${timeValue}:00`);
  if (Number.isNaN(parsed.getTime())) return null;
  return parsed.toISOString();
}

function inferBestTableTypeId(
  tableTypes: GuestTableAvailabilityItem[],
  partySize: number,
): string | undefined {
  return [...tableTypes]
    .filter((tableType) => tableType.availableQuantity > 0 && tableType.seats >= partySize)
    .sort((a, b) => a.seats - b.seats || a.availableQuantity - b.availableQuantity)[0]?.id;
}

function formatTableTypeLabel(tableType: GuestTableAvailabilityItem): string {
  const label = tableType.label?.trim()
    ? tableType.label
    : `${tableType.seats} lugares`;
  return `${label} • ${tableType.availableQuantity}/${tableType.totalQuantity} disponivel(is)`;
}
