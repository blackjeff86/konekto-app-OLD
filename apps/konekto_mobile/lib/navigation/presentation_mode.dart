/// Como uma tela de módulo é apresentada — o módulo em si só conhece um
/// `screenId` (identificador lógico, ver `ModuleDefinition.screenId`),
/// nunca uma rota ou um jeito de apresentação. Mesmo módulo pode virar
/// página hoje e bottom sheet amanhã sem tocar no módulo.
enum PresentationMode { page, modal, bottomSheet, drawer, wizard, deepLink }
