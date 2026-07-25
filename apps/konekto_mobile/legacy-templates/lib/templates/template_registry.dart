import 'package:flutter/material.dart';
import 'package:konekto/l10n/app_localizations.dart';
import 'package:konekto/templates/amara_bay/home_screen.dart';
import 'package:konekto/templates/casa_marechal/home_screen.dart';
import 'package:konekto/templates/shared/guest_home_content_params.dart';
import 'package:konekto/templates/verde_pousada/home_screen.dart';
import 'package:konekto/theme/guest_infra.dart';

/// Widget de Home de um template — recebe o `context` (pra localização) e
/// os parâmetros comuns já resolvidos pelo `TenantHomePage`.
typedef GuestHomeContentBuilder = Widget Function(BuildContext context, GuestHomeContentParams params);

/// `GuestInfra` → qual widget de Home renderizar. Konekto Clássico/Noturno
/// não têm mockup próprio do Stitch — reaproveitam a Home da Amara
/// Bay/Verde Pousada (mesma decisão de sempre neste código), só trocando a
/// tag exibida sob o nome do hotel.
///
/// Fase 3 (migração dos 5 templates White Label — Aura/Bosque/Elite/Pulse/
/// Horizon) adiciona entradas aqui em vez de tocar em `tenant_home_page.dart`.
final Map<GuestInfra, GuestHomeContentBuilder> _homeContentBuilders = {
  GuestInfra.amaraBay: (context, params) =>
      AmaraBayHomeContent(params: params, heroTag: AppLocalizations.of(context)!.amaraResortTag),
  GuestInfra.konektoClassico: (context, params) =>
      AmaraBayHomeContent(params: params, heroTag: AppLocalizations.of(context)!.konektoClassicoTag),
  GuestInfra.verdePousada: (context, params) => VerdePousadaHomeContent(params: params),
  GuestInfra.konektoNoturno: (context, params) => VerdePousadaHomeContent(params: params),
  GuestInfra.casaMarechal: (context, params) => CasaMarechalHomeContent(params: params),
};

Widget buildGuestHomeContent(BuildContext context, GuestInfra infra, GuestHomeContentParams params) {
  final builder = _homeContentBuilders[infra];
  assert(builder != null, 'Nenhuma Home registrada para $infra');
  return builder!(context, params);
}
