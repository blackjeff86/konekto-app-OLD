# Konekto

Monorepo do ecossistema Konekto.

- [`apps/konekto_mobile`](apps/konekto_mobile) — app mobile multi-tenant usado pelo hóspede do hotel (login, check-in, eventos, spa, restaurantes, passeios, room service, mapa, promoções, etc). É a implementação mais madura da experiência de hóspede; versões anteriores desse mesmo conceito foram descontinuadas. Obs: o pacote Dart interno se chama `konekto` (declarado em `pubspec.yaml`), então os imports no código usam `package:konekto/...` mesmo a pasta se chamando `konekto_mobile`.

Próximos apps planejados (ainda não implementados): site institucional e painel de staff/gestão do hotel.

## Rodando o app

```bash
cd apps/konekto_mobile
flutter pub get
flutter run
```
