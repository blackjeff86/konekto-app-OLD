import type { PublicFeatureStatus } from "./product-roadmap"

export interface ProductSurface {
  id: string
  name: string
  status: PublicFeatureStatus
  title: string
  description: string
  bullets: string[]
}

export const PRODUCT_SURFACES: ProductSurface[] = [
  {
    id: "guest",
    name: "Sevvn Guest",
    status: "available",
    title: "A interface do hóspede, com a identidade do hotel.",
    description:
      "É a camada visível da experiência: branded, White Label e configurada para cada operação, com os fluxos centrais do piloto preservados nos cinco templates atuais.",
    bullets: [
      "Informações da hospedagem",
      "Serviços e pedidos",
      "Reservas e experiências",
      "Mensagens e avisos",
    ],
  },
  {
    id: "hotel",
    name: "Sevvn Hotel",
    status: "available",
    title: "O portal que organiza a operação do hotel.",
    description:
      "Equipe, módulos, serviços, pedidos, reservas, branding e integrações em uma mesma camada de gestão.",
    bullets: [
      "Configuração da operação",
      "Gestão de módulos",
      "Pedidos, hóspedes e estadias",
      "Integrações e conteúdo",
    ],
  },
  {
    id: "platform",
    name: "Sevvn Platform",
    status: "available",
    title: "A infraestrutura central da plataforma.",
    description:
      "Multi-tenant, modular e preparada para planos, integrações, regras comerciais e evolução contínua, sem depender de um app isolado para provar valor.",
    bullets: [
      "Módulos e regras por plano",
      "Integrações PMS / ERP",
      "Segurança e escalabilidade",
      "Evolução contínua",
    ],
  },
  {
    id: "network",
    name: "Sevvn Network",
    status: "in-development",
    title: "A rede de parceiros e experiências em construção.",
    description:
      "A próxima camada da Sevvn para conectar parceiros locais, ofertas e experiências confiáveis à jornada do hóspede de forma progressiva.",
    bullets: [
      "Parceiros próprios do hotel",
      "Parceiros homologados pela Sevvn",
      "Modelo híbrido",
      "Novas oportunidades de receita",
    ],
  },
]
