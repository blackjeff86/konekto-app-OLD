import Anthropic from '@anthropic-ai/sdk'

export type TranslatableFields = Record<string, string | null | undefined>
export type FieldTranslations = Record<string, string>
export interface Translations {
  en?: FieldTranslations
  es?: FieldTranslations
}

function getAnthropicClient(): Anthropic {
  const apiKey = process.env.ANTHROPIC_API_KEY
  if (!apiKey) {
    throw new Error('Missing required env var: ANTHROPIC_API_KEY')
  }
  return new Anthropic({ apiKey })
}

// Modelo mais barato/rápido da família — sobra pra traduzir textos curtos
// de cardápio/serviço, sem precisar do custo de um modelo maior.
const TRANSLATION_MODEL = 'claude-haiku-4-5-20251001'

function extractJson(text: string): string {
  const fenced = text.match(/```(?:json)?\s*([\s\S]*?)```/)
  return fenced ? fenced[1].trim() : text.trim()
}

/// Traduz um conjunto de campos de texto (nome, descrição, etc.) de um
/// serviço/item de hotel do português pro inglês e espanhol numa única
/// chamada. Nomes próprios (nome de restaurante, de prato-marca, de
/// estabelecimento) devem permanecer sem tradução — isso só é confiável via
/// instrução de prompt pra um modelo de linguagem, não dá pra decidir
/// programaticamente. Retorna `null` quando não há nada traduzível ou
/// quando a resposta não pôde ser interpretada.
export async function translateFields(fields: TranslatableFields): Promise<Translations | null> {
  const entries = Object.entries(fields).filter(
    (entry): entry is [string, string] => typeof entry[1] === 'string' && entry[1].trim() !== '',
  )
  if (entries.length === 0) return null

  const source = Object.fromEntries(entries)
  const client = getAnthropicClient()

  const message = await client.messages.create({
    model: TRANSLATION_MODEL,
    max_tokens: 1024,
    messages: [
      {
        role: 'user',
        content:
          'Traduza os textos de um cardápio/serviço de hotel do português pro inglês e espanhol. ' +
          'Responda APENAS com um JSON no formato {"en": {...}, "es": {...}}, usando as mesmas chaves ' +
          'do texto original. Mantenha nomes próprios (nomes de pratos que sejam marcas, nomes de ' +
          'restaurantes, nomes de estabelecimentos) sem tradução. Traduza tudo o mais (descrições, ' +
          'nomes genéricos de item, categorias, informações extras).\n\nTextos:\n' +
          JSON.stringify(source, null, 2),
      },
    ],
  })

  const textBlock = message.content.find((block) => block.type === 'text')
  if (!textBlock || textBlock.type !== 'text') return null

  try {
    return JSON.parse(extractJson(textBlock.text)) as Translations
  } catch {
    return null
  }
}

/// Igual a [translateFields], mas nunca lança — usada nas rotas de
/// criação/edição, onde a tradução automática é "melhor esforço" e não
/// deve impedir o salvamento do serviço/item (chave da Anthropic ausente,
/// erro da API, ou resposta mal formada só resultam em `null`, e o hóspede
/// continua vendo o texto em português como fallback até uma nova tentativa).
export async function autoTranslateOrNull(fields: TranslatableFields): Promise<Translations | null> {
  try {
    return await translateFields(fields)
  } catch {
    return null
  }
}
