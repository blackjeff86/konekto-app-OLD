export interface UseCase {
  title: string
  subtitle: string
  summary: string
  highlights: string[]
}

export const USE_CASES: UseCase[] = [
  {
    title: "Pousada boutique",
    subtitle: "Aura ou Bosque",
    summary: "Uma experiência mais acolhedora, conectada e White Label para estadias curtas e atendimento próximo.",
    highlights: ["Informações da estadia", "Wi-Fi", "Mensagens", "Restaurantes", "Passeios", "Parceiros locais"],
  },
  {
    title: "Hotel urbano",
    subtitle: "Elite ou Pulse",
    summary: "Mais agilidade operacional para uma rotina com serviços internos, comunicação e jornada digital em expansão.",
    highlights: ["Room Service", "Solicitações", "Mensagens", "Promoções", "Carteira", "Check-in digital"],
  },
  {
    title: "Resort",
    subtitle: "Horizon",
    summary: "Uma camada digital preparada para jornadas mais longas, múltiplas experiências e maior valor por hóspede.",
    highlights: ["Restaurantes", "Atividades", "Spa", "Kids Club", "Mapa", "Eventos", "Fidelidade"],
  },
  {
    title: "Rede hoteleira",
    subtitle: "Enterprise",
    summary: "Arquitetura com governança, multiunidade, integrações, analytics e espaço para módulos exclusivos.",
    highlights: ["Multiunidade", "Governança", "Integrações", "Analytics", "Templates", "Módulos exclusivos"],
  },
]
