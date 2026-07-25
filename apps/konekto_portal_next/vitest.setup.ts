import '@testing-library/jest-dom/vitest'

// jsdom não implementa scrollIntoView (Element.prototype não tem o método) —
// stub global pra qualquer componente que dependa disso (ex: auto-scroll de chat).
if (typeof Element !== 'undefined' && !Element.prototype.scrollIntoView) {
  Element.prototype.scrollIntoView = () => {}
}
