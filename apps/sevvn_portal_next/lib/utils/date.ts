/**
 * Formata datas em UTC, não no fuso do navegador — espelha o comportamento
 * do Dart: `DateTime.parse(json['x'])` numa string com 'Z' produz um
 * DateTime com `isUtc: true`, e `.day`/`.month`/`.hour` etc. acessam os
 * componentes UTC diretamente (nenhum `.toLocal()` é chamado em nenhum
 * `_formatDate`/`_formatDateTime` do app original). Usar getters locais
 * (`getDate()`, `getHours()`...) faria a data mostrada variar conforme o
 * fuso do navegador do staff — inconsistente com o app Flutter atual.
 */
export function formatDate(iso: string): string {
  const date = new Date(iso)
  const day = date.getUTCDate().toString().padStart(2, '0')
  const month = (date.getUTCMonth() + 1).toString().padStart(2, '0')
  return `${day}/${month}/${date.getUTCFullYear()}`
}

export function formatDateTime(iso: string): string {
  const hour = new Date(iso).getUTCHours().toString().padStart(2, '0')
  const minute = new Date(iso).getUTCMinutes().toString().padStart(2, '0')
  return `${formatDate(iso)} ${hour}:${minute}`
}

/** "dd/MM" — usado no dashboard (série de receita, chegadas/saídas próximas). */
export function formatShortDate(iso: string): string {
  const date = new Date(iso)
  const day = date.getUTCDate().toString().padStart(2, '0')
  const month = (date.getUTCMonth() + 1).toString().padStart(2, '0')
  return `${day}/${month}`
}
