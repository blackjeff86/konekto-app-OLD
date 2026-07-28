"use client";

import { useEffect, useMemo, useState, useTransition } from "react";
import { claimGuestAccess } from "@/lib/api/guest";
import {
  getGuestHotelConfig,
  getGuestItemAvailability,
  getGuestRestaurantTableAvailability,
  getGuestService,
  getGuestServices,
} from "@/lib/api/hotels";
import { getModulesCatalog } from "@/lib/api/modules-catalog";
import { createGuestOrder, getGuestOrders } from "@/lib/api/orders";
import { getGuestMessages, sendGuestMessage } from "@/lib/api/messages";
import type {
  ConciergeModuleConfig,
  GuestClaimResponse,
  GuestHotelConfig,
  GuestItemAvailabilityResponse,
  GuestMessage,
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

type LoadState =
  | { status: "idle" }
  | { status: "loading" }
  | {
      status: "ready";
      hotel: GuestHotelConfig;
      services: GuestService[];
      modulesCatalog: ModulesCatalogResponse;
    }
  | { status: "error"; message: string };

type ViewState =
  | { kind: "home" }
  | { kind: "services" }
  | { kind: "bookings" }
  | { kind: "profile" }
  | { kind: "service-detail"; serviceId: string };

type OrdersState = {
  status: "idle" | "loading" | "ready" | "error";
  orders: GuestOrder[];
};

type ServiceDetailState =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "ready"; service: GuestService }
  | { status: "error"; message: string };

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

  const accentColor = useMemo(() => {
    if (loadState.status !== "ready") return "var(--accent)";
    const template = loadState.hotel.template ?? "aura";
    return templateAccent[template];
  }, [loadState]);

  const resolvedModules = useResolvedModules(loadState);

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
      <main className="guest-stage">
        <section className="guest-panel">
          <p className="guest-eyebrow">Sevvn Guest Next</p>
          <h1 className="guest-title">Acesso do hospede</h1>
          <p className="guest-copy">
            O hotel exibido neste app sera sempre derivado do codigo de acesso
            validado, nunca de uma escolha manual do navegador.
          </p>

          <form className="guest-form" onSubmit={handleClaimSubmit}>
            <label className="guest-label" htmlFor="claimCode">
              Codigo de acesso
            </label>
            <input
              id="claimCode"
              value={claimCode}
              onChange={(event) => setClaimCode(event.target.value)}
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
        </section>
      </main>
    );
  }

  return (
    <main className="guest-stage">
      <section className="guest-panel">
        <div className="guest-shell-header">
          <div>
            <p className="guest-eyebrow">Sessao autenticada</p>
            <h1 className="guest-title" style={{ color: accentColor }}>
              {session.guest.firstName} {session.guest.lastName}
            </h1>
            <p className="guest-copy">
              Quarto {session.guest.roomNumber} • hotel {session.guest.hotelId}
            </p>
          </div>
          <button
            type="button"
            className="guest-secondary-button"
            onClick={handleSignOut}
          >
            Sair
          </button>
        </div>

        <section className="guest-security-note">
          <strong>Regra de seguranca ativa:</strong> o app carrega dados apenas
          para o hotel vinculado ao claim autenticado. O `hotelId` vem da
          sessao do hospede, nao de URL livre ou troca manual.
        </section>

        {loadState.status === "loading" ? (
          <p className="guest-copy">Carregando hotel e servicos...</p>
        ) : null}

        {loadState.status === "error" ? (
          <p className="guest-error">{loadState.message}</p>
        ) : null}

        {loadState.status === "ready" && resolvedModules ? (
          <>
            <nav className="guest-module-nav">
              {resolvedModules.bottomNav.map((module) => (
                <button
                  key={module.id}
                  type="button"
                  className={`guest-nav-button${
                    isModuleActive(module, view) ? " guest-nav-button-active" : ""
                  }`}
                  onClick={() => setView(viewForModule(module))}
                >
                  {module.name}
                </button>
              ))}
            </nav>

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
              onOpenService: (serviceId) => setView({ kind: "service-detail", serviceId }),
              onBackToServices: () => setView({ kind: "services" }),
            })}
          </>
        ) : null}
      </section>
    </main>
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
  onOpenService,
  onBackToServices,
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
  onOpenService: (serviceId: string) => void;
  onBackToServices: () => void;
}) {
  if (view.kind === "services") {
    return (
      <div className="guest-grid">
        <article className="guest-card guest-card-wide">
          <p className="guest-card-label">Servicos por modulo</p>
          <h2 className="guest-card-title">
            {resolvedModules.servicesMenu.length} modulo(s) de hospitalidade
          </h2>
          <div className="guest-chip-list">
            {resolvedModules.servicesMenu.map((module) => (
              <span key={module.id} className="guest-chip">
                {module.name}
              </span>
            ))}
          </div>
        </article>

        <article className="guest-card guest-card-wide">
          <p className="guest-card-label">Servicos do hotel</p>
          <h2 className="guest-card-title">
            {services.length} servico(s) disponivel(is)
          </h2>
          <div className="guest-services-groups">
            {resolvedModules.groupedServices.map((section) => (
              <section key={section.id} className="guest-services-section">
                {section.title ? (
                  <h3 className="guest-section-title">{section.title}</h3>
                ) : null}
                <div className="guest-services-list">
                  {section.services.map((service) => (
                    <button
                      key={service.id}
                      type="button"
                      className="guest-service-button"
                      onClick={() => onOpenService(service.id)}
                    >
                      <div className="guest-service-row">
                        <div>
                          <strong>{service.name}</strong>
                          <p className="guest-copy">{service.description}</p>
                        </div>
                        <span className="guest-service-tag">
                          {service.type.replaceAll("_", " ")}
                        </span>
                      </div>
                    </button>
                  ))}
                </div>
              </section>
            ))}
            {resolvedModules.groupedServices.length === 0 ? (
              <p className="guest-copy">
                Nenhum servico agrupado disponivel no momento.
              </p>
            ) : null}
          </div>
        </article>
      </div>
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
      <div className="guest-grid">
        <article className="guest-card guest-card-wide">
          <div className="guest-detail-header">
            <button
              type="button"
              className="guest-secondary-button"
              onClick={onBackToServices}
            >
              Voltar para servicos
            </button>
            <span className="guest-service-tag">
              {service.type.replaceAll("_", " ")}
            </span>
          </div>
          <p className="guest-card-label">Detalhe do servico</p>
          <h2 className="guest-card-title">{service.name}</h2>
          <p className="guest-copy">{service.description}</p>
          {service.bannerImageUrl ? (
            <div className="guest-service-row">
              <div>
                <strong>Banner carregado</strong>
                <p className="guest-copy">{service.bannerImageUrl}</p>
              </div>
            </div>
          ) : null}
          <div className="guest-services-list">
            <div className="guest-service-row">
              <div>
                <strong>Modulo vinculado</strong>
                <p className="guest-copy">{service.moduleId ?? "Nao informado"}</p>
              </div>
            </div>
            <div className="guest-service-row">
              <div>
                <strong>Itens disponiveis</strong>
                <p className="guest-copy">
                  {service.items?.length ?? 0} item(ns) carregado(s) no detalhe real.
                </p>
              </div>
            </div>
            {showRestaurantMenu ? (
              service.items?.map((item) => (
                <div key={item.id} className="guest-service-row">
                  <div>
                    <strong>{item.name}</strong>
                    <p className="guest-copy">{item.description || "Sem descricao."}</p>
                    <p className="guest-copy">
                      Preco:{" "}
                      {showRestaurantPrices
                        ? item.price != null
                          ? new Intl.NumberFormat("pt-BR", {
                              style: "currency",
                              currency: "BRL",
                            }).format(item.price)
                          : "sob consulta"
                        : "oculto pelo hotel"}
                    </p>
                    {item.durationMinutes ? (
                      <p className="guest-copy">
                        Duracao prevista: {item.durationMinutes} minuto(s)
                      </p>
                    ) : null}
                    {item.isMinibarItem ? (
                      <p className="guest-copy">Item configurado para frigobar.</p>
                    ) : null}
                  </div>
                  <span className="guest-service-tag">
                    {item.category ?? "item"}
                  </span>
                </div>
              ))
            ) : service.type === "restaurant" ? (
              <div className="guest-service-row">
                <div>
                  <strong>Cardapio oculto pelo hotel</strong>
                  <p className="guest-copy">
                    Este restaurante pode aceitar reservas mesmo sem exibir os pratos
                    dentro do app do hospede.
                  </p>
                </div>
              </div>
            ) : null}
            {service.tableTypes?.map((tableType) => (
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
                <strong>Proxima etapa</strong>
                <p className="guest-copy">
                  Aqui vamos encaixar pedido, agendamento e reserva autenticados
                  por token, sempre no escopo do hotel do hospede.
                </p>
              </div>
            </div>
          </div>
        </article>
      </div>
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

  if (view.kind === "profile") {
    return (
      <div className="guest-grid">
        <article className="guest-card">
          <p className="guest-card-label">Hospede</p>
          <h2 className="guest-card-title">
            {session.guest.firstName} {session.guest.lastName}
          </h2>
          <p className="guest-copy">Quarto {session.guest.roomNumber}</p>
        </article>
        <article className="guest-card">
          <p className="guest-card-label">Hotel</p>
          <h2 className="guest-card-title">
            {hotel.hotelInfo?.name ?? "Hotel sem nome"}
          </h2>
          <p className="guest-copy">
            Template ativo: {hotel.template ?? "aura"}
          </p>
        </article>
      </div>
    );
  }

  return (
    <div className="guest-grid">
      <article className="guest-card">
        <p className="guest-card-label">Hotel</p>
        <h2 className="guest-card-title">
          {hotel.hotelInfo?.name ?? "Hotel sem nome"}
        </h2>
        <p className="guest-copy">Template ativo: {hotel.template ?? "aura"}</p>
        <p className="guest-copy">
          Modulos resolvidos: {hotel.enabledModules?.length ?? 0}
        </p>
      </article>

      <article className="guest-card">
        <p className="guest-card-label">Wi-Fi</p>
        <h2 className="guest-card-title">
          {session.guest.wifiNetworkName ?? "Nao informado"}
        </h2>
        <p className="guest-copy">
          Senha: {session.guest.wifiPassword ?? "Nao informada"}
        </p>
      </article>

      <article className="guest-card guest-card-wide">
        <p className="guest-card-label">Modulos da Home</p>
        <h2 className="guest-card-title">
          {resolvedModules.home.length} modulo(s) na superficie Home
        </h2>
        <div className="guest-chip-list">
          {resolvedModules.home.map((module) => (
            <span key={module.id} className="guest-chip">
              {module.name}
            </span>
          ))}
        </div>
      </article>

      <article className="guest-card guest-card-wide">
        <p className="guest-card-label">Acesso rapido</p>
        <h2 className="guest-card-title">Modulos principais primeiro</h2>
        <div className="guest-quick-actions">
          <button type="button" className="guest-button" onClick={onOpenServices}>
            Abrir servicos
          </button>
        </div>
      </article>

      <article className="guest-card guest-card-wide">
        <p className="guest-card-label">Politica de isolamento</p>
        <h2 className="guest-card-title">Base pronta para endurecimento</h2>
        <div className="guest-services-list">
          <div className="guest-service-row">
            <div>
              <strong>Contexto do hotel</strong>
              <p className="guest-copy">
                O `hotelId` usado no app nasce da sessao autenticada do hospede
                e nao de parametros livres.
              </p>
            </div>
          </div>
          <div className="guest-service-row">
            <div>
              <strong>Modulos e servicos</strong>
              <p className="guest-copy">
                O shell ja foi organizado para renderizar catalogo, nav e
                agrupamento com base no hotel autenticado.
              </p>
            </div>
          </div>
          <div className="guest-service-row">
            <div>
              <strong>Modo de operacao</strong>
              <p className="guest-copy">
                A mesma estrutura vai atender hoteis standalone e hoteis
                integrados com PMS, POS, ERP ou middleware, sempre pela camada
                normalizada da Sevvn.
              </p>
            </div>
          </div>
          <div className="guest-service-row">
            <div>
              <strong>Fluxos autenticados</strong>
              <p className="guest-copy">
                `Reservas` ja usa o token do hospede no endpoint autenticado de
                pedidos. O mesmo padrao vai valer para mensagens e conta.
              </p>
            </div>
          </div>
        </div>
      </article>
    </div>
  );
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
      <div className="guest-service-row">
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
        <div className="guest-service-row">
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

      <div className="guest-service-row">
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
            <div className="guest-services-list">
              {messagesState.messages.length === 0 ? (
                <p className="guest-copy">
                  Nenhuma conversa iniciada ainda. Envie a primeira mensagem.
                </p>
              ) : (
                messagesState.messages.map((message) => (
                  <div key={message.id} className="guest-service-row">
                    <div>
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
                    <span className="guest-service-tag">
                      {message.senderType === "guest" ? "enviado" : "recebido"}
                    </span>
                  </div>
                ))
              )}
            </div>
          ) : null}

          <form className="guest-form" onSubmit={handleSubmit}>
            <label className="guest-label" htmlFor={`concierge-message-${service.id}`}>
              Nova mensagem
            </label>
            <textarea
              id={`concierge-message-${service.id}`}
              className="guest-input"
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

function viewForModule(module: ModuleDefinition): ViewState {
  const route = module.screenId ?? module.id;

  if (route === "services") return { kind: "services" };
  if (route === "bookings") return { kind: "bookings" };
  if (route === "profile") return { kind: "profile" };
  return { kind: "home" };
}

function isModuleActive(module: ModuleDefinition, view: ViewState): boolean {
  const route = module.screenId ?? module.id;

  if (view.kind === "service-detail" && route === "services") return true;
  if (view.kind === "home" && route === "home") return true;
  if (view.kind === "services" && route === "services") return true;
  if (view.kind === "bookings" && route === "bookings") return true;
  if (view.kind === "profile" && route === "profile") return true;
  return false;
}

type ResolvedModulesShape = {
  bottomNav: ModuleDefinition[];
  home: ModuleDefinition[];
  servicesMenu: ModuleDefinition[];
  groupedServices: ReturnType<typeof groupServicesByCatalog>;
};

function useResolvedModules(
  loadState: LoadState,
): ResolvedModulesShape | null {
  return useMemo(() => {
    if (loadState.status !== "ready") return null;

    const enabledModules = loadState.hotel.enabledModules ?? [];
    const catalog = loadState.modulesCatalog.modules;

    return {
      bottomNav: resolveBottomNavModules(enabledModules, catalog),
      home: resolveHomeModules(enabledModules, catalog),
      servicesMenu: resolveServicesMenuModules(enabledModules, catalog),
      groupedServices: groupServicesByCatalog({
        services: loadState.services,
        serviceGroups: loadState.modulesCatalog.serviceGroups,
        catalog,
      }),
    };
  }, [loadState]);
}
