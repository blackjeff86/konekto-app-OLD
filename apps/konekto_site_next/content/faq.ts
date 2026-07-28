export interface FaqItem {
  question: string
  answer: string
}

export const FAQ_ITEMS: FaqItem[] = [
  {
    question: "A Sevvn é um aplicativo ou uma plataforma?",
    answer:
      "A Sevvn é uma plataforma. O aplicativo do hóspede é uma das interfaces dessa estrutura, ao lado do portal do hotel, da administração central da Sevvn e da camada de integrações e módulos.",
  },
  {
    question: "Meu hotel precisa trocar de PMS para usar a Sevvn?",
    answer:
      "Não. A proposta da Sevvn é se integrar à operação do hotel. A profundidade da integração depende do cenário e da fase do projeto, mas a base para PMS e sistemas hoteleiros já faz parte da plataforma.",
  },
  {
    question: "Os módulos podem ser ativados aos poucos?",
    answer:
      "Sim. Essa é uma das bases da Sevvn. Cada hotel ativa o que faz sentido para sua operação e expande a jornada sem precisar trocar de plataforma.",
  },
  {
    question: "Os templates são aplicativos diferentes?",
    answer:
      "Não. Os templates definem a identidade visual. Os módulos definem os recursos. Hoje, os cinco templates preservam os fluxos centrais do piloto sobre a mesma base operacional da plataforma.",
  },
  {
    question: "Já existe portal para a equipe do hotel?",
    answer:
      "Sim. A Sevvn já possui portal operacional para gestão de módulos, pedidos, serviços, hóspedes, branding e integrações.",
  },
  {
    question: "A Rede Sevvn já está lançada?",
    answer:
      "Ainda não como produto completo. A rede está em desenvolvimento e faz parte da evolução estratégica da plataforma para parceiros, experiências e novos modelos de receita.",
  },
  {
    question: "Quais recursos já podem ser demonstrados hoje?",
    answer:
      "Hoje já podemos demonstrar a base da plataforma, o portal do hotel, a camada administrativa, os cinco templates, módulos centrais da jornada e serviços como room service, restaurantes, mensagens, spa, passeios, promoções controladas e estrutura de integrações.",
  },
  {
    question: "A Sevvn serve para pousadas e também para redes?",
    answer:
      "Sim. A lógica modular permite começar com uma operação menor e evoluir para cenários mais complexos, inclusive grupos e estruturas multiunidade.",
  },
]
