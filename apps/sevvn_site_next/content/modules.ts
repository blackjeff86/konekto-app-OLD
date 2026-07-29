import type { PublicFeatureStatus } from "./product-roadmap"

export interface PublicFeatureGroupEntry {
  label: string
  featureId: string
  status: PublicFeatureStatus
}

export interface PublicFeatureGroup {
  title: string
  description: string
  items: PublicFeatureGroupEntry[]
}

export const PUBLIC_FEATURE_GROUPS: PublicFeatureGroup[] = [
  {
    title: "Experiência da estadia",
    description: "O que organiza a jornada básica do hóspede do pré-check-in ao pós-estadia.",
    items: [
      { label: "Informações da hospedagem", featureId: "stay-info", status: "available" },
      { label: "Wi-Fi e orientações", featureId: "wifi-orientation", status: "available" },
      { label: "Perfil do hóspede", featureId: "guest-profile", status: "available" },
      { label: "Pedidos e reservas", featureId: "bookings-orders", status: "available" },
      { label: "Mensagens com a equipe", featureId: "guest-messages", status: "available" },
      { label: "Avisos e notificações básicas", featureId: "basic-notices", status: "available" },
    ],
  },
  {
    title: "Serviços do hotel",
    description: "Módulos ativados conforme o perfil da operação e do plano contratado.",
    items: [
      { label: "Room Service", featureId: "room-service", status: "available" },
      { label: "Restaurantes", featureId: "restaurants", status: "available" },
      { label: "Passeios", featureId: "tours", status: "available" },
      { label: "Spa", featureId: "spa", status: "available" },
      { label: "Concierge", featureId: "concierge", status: "coming-soon" },
      { label: "Eventos", featureId: "events", status: "coming-soon" },
      { label: "Lavanderia", featureId: "laundry", status: "coming-soon" },
      { label: "Transporte e transfer", featureId: "transport", status: "coming-soon" },
    ],
  },
  {
    title: "Jornada digital",
    description: "Recursos para reduzir atrito operacional e dar mais autonomia ao hóspede.",
    items: [
      { label: "Check-in digital", featureId: "digital-checkin", status: "in-development" },
      { label: "Check-out digital", featureId: "digital-checkout", status: "in-development" },
      { label: "Mapa interativo", featureId: "interactive-map", status: "coming-soon" },
      { label: "Notificações inteligentes", featureId: "smart-notifications", status: "coming-soon" },
      { label: "Chat multilíngue", featureId: "multilingual-chat", status: "coming-soon" },
    ],
  },
  {
    title: "Relacionamento e receita",
    description: "Recursos para benefícios, consumo, recorrência e maior valor por estadia.",
    items: [
      { label: "Promoções e benefícios", featureId: "promotions", status: "available" },
      { label: "Programa de fidelidade", featureId: "loyalty", status: "in-development" },
      { label: "Carteira da hospedagem", featureId: "wallet", status: "in-development" },
    ],
  },
  {
    title: "Rede e experiências",
    description: "A próxima camada da plataforma para parceiros locais e experiências confiáveis.",
    items: [
      { label: "Rede Sevvn", featureId: "partner-network", status: "in-development" },
      { label: "Ofertas e experiências parceiras", featureId: "partner-offers", status: "coming-soon" },
      { label: "Analytics para parceiros", featureId: "partner-analytics", status: "coming-soon" },
    ],
  },
]
