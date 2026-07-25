/// Item de cardápio de demonstração pras telas de Room Service dos
/// templates novos (Fase 3, Task 9) — dado fictício de propósito, igual ao
/// mockup do Stitch, só pra provar o visual de cada template. **Nunca deve
/// ir pra produção assim**: a Fase 4 troca isso pelo `ServiceItem` real
/// (`konekto/data/services_repository.dart`), que já tem itens/preços de
/// verdade vindos do backend.
class GuestTemplateMenuItem {
  final String name;
  final String description;
  final String price;
  final String? tag;

  const GuestTemplateMenuItem({required this.name, required this.description, required this.price, this.tag});
}
