import 'package:flutter/material.dart';
import 'package:konekto/templates/aura/home_screen.dart';
import 'package:konekto/templates/aura/theme.dart';
import 'package:konekto/templates/bosque/home_screen.dart';
import 'package:konekto/templates/bosque/theme.dart';
import 'package:konekto/templates/elite/home_screen.dart';
import 'package:konekto/templates/elite/theme.dart';
import 'package:konekto/templates/horizon/home_screen.dart';
import 'package:konekto/templates/horizon/theme.dart';
import 'package:konekto/templates/pulse/home_screen.dart';
import 'package:konekto/templates/pulse/theme.dart';
import 'package:konekto/templates/shared/guest_template_content_params.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Os 5 templates White Label (`template` no `Hotel.config`, ver
/// `apps/sevvn_api/lib/feature-flags.ts` → `GuestTemplateId`) — únicos
/// templates válidos do app do hóspede. `tenant_home_page.dart` sempre
/// renderiza a Home por aqui (fallback `aura` se `template` estiver
/// ausente). As demais abas (Serviços/Reservas/Perfil) usam um tema
/// compartilhado único (`GuestAppTheme`, `lib/theme/guest_app_theme.dart`)
/// — não trocam de visual por template; só a Home troca. As telas
/// específicas de cada template além da Home (Room Service, Diretório,
/// Chat, Onboarding, Loyalty/Wallet) usam dado de demonstração e ainda não
/// têm onde plugar dado real — não estão ligadas a nenhuma rota.
enum GuestTemplateId { aura, bosque, elite, pulse, horizon }

/// `null` quando `raw` é nulo/vazio/desconhecido — mesmo padrão de
/// `guestInfraFromString` (fallback silencioso, nunca lança).
GuestTemplateId? guestTemplateIdFromString(String? raw) {
  if (raw == null) return null;
  for (final id in GuestTemplateId.values) {
    if (id.name == raw) return id;
  }
  return null;
}

const Map<GuestTemplateId, GuestTemplateTheme> guestTemplateThemes = {
  GuestTemplateId.aura: auraTheme,
  GuestTemplateId.bosque: bosqueTheme,
  GuestTemplateId.elite: eliteTheme,
  GuestTemplateId.pulse: pulseTheme,
  GuestTemplateId.horizon: horizonTheme,
};

final Map<GuestTemplateId, Widget Function(GuestTemplateContentParams params)> _homeContentBuilders = {
  GuestTemplateId.aura: (params) => AuraHomeContent(params: params),
  GuestTemplateId.bosque: (params) => BosqueHomeContent(params: params),
  GuestTemplateId.elite: (params) => EliteHomeContent(params: params),
  GuestTemplateId.pulse: (params) => PulseHomeContent(params: params),
  GuestTemplateId.horizon: (params) => HorizonHomeContent(params: params),
};

Widget buildGuestTemplateHomeContent(GuestTemplateId id, GuestTemplateContentParams params) {
  final builder = _homeContentBuilders[id];
  assert(builder != null, 'Nenhuma Home registrada para $id — os 5 templates precisam de builder.');
  return builder!(params);
}

