export interface FaqItem {
  question: string;
  answer: string;
}

export const FAQ_ITEMS: FaqItem[] = [
  {
    question: "Como funciona a plataforma?",
    answer:
      "Você escolhe um plano, um template visual, ativa os módulos que fazem sentido e personaliza sua marca. O app publicado é a soma dessas escolhas, rodando sobre a mesma plataforma.",
  },
  {
    question: "Posso trocar de template futuramente?",
    answer:
      "Sim, a qualquer momento. Módulos e dados permanecem intactos, só a identidade visual muda.",
  },
  {
    question: "Posso ativar novos módulos depois?",
    answer: "Sim. Sua plataforma evolui continuamente, sem reconstrução do aplicativo.",
  },
  {
    question: "Preciso trocar meu PMS?",
    answer: "Não. A Sevvn integra com os principais PMS do mercado.",
  },
  {
    question: "As integrações já estão incluídas?",
    answer:
      "As integrações padrão estão incluídas conforme o plano; integrações específicas fazem parte do plano Enterprise.",
  },
  {
    question: "Quanto tempo leva a implantação?",
    answer:
      "Times de fundadores costumam publicar o app em poucas semanas, dependendo dos módulos escolhidos.",
  },
  {
    question: "O aplicativo funciona em Android e iPhone?",
    answer: "Sim, funciona como PWA instalável nas duas plataformas, sem passar por loja de apps.",
  },
  {
    question: "O aplicativo terá minha marca?",
    answer: "Sim, 100% White Label. O hóspede não vê a marca Sevvn em nenhum momento.",
  },
  {
    question: "Meu hotel pode ativar apenas alguns módulos?",
    answer: "Sim, você ativa só o que faz sentido para sua operação hoje, e expande quando quiser.",
  },
  {
    question: "É possível crescer sem trocar de aplicativo?",
    answer:
      "Sim. Essa é a base da nossa arquitetura: evolução contínua sobre o mesmo aplicativo publicado.",
  },
];
