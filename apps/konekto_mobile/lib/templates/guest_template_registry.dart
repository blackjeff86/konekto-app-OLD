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
/// `apps/konekto_api/lib/feature-flags.ts` → `GuestTemplateId`). Task 14
/// (Fase 4) ligou a Home de verdade a isso em `tenant_home_page.dart`
/// quando `tenantConfig['template']` está presente — nenhum hotel real tem
/// esse campo setado ainda (a migração de dado hotel a hotel é decisão
/// separada, feita depois, não parte desta mudança), então esse caminho
/// continua inalcançável em produção por ora; só prova que o mecanismo
/// funciona. As outras abas (Serviços/Reservas/Perfil) continuam no visual
/// antigo mesmo quando `template` está presente — só a Home foi migrada
/// com dado real (Task 8/11); as demais telas dos templates novos usam
/// dado fictício (Room Service, Diretório) e não têm onde plugar dado real
/// ainda.
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

/// `null` só se um template novo for adicionado ao enum sem Home migrada
/// ainda — hoje os 5 têm Home.
Widget? buildGuestTemplateHomeContent(GuestTemplateId id, GuestTemplateContentParams params) {
  final builder = _homeContentBuilders[id];
  return builder?.call(params);
}
