import 'dart:async';

/// Evento de domínio publicado por um módulo — pub/sub genérico de
/// propósito (não uma classe Dart por tipo de evento), pra módulo novo
/// nunca exigir mexer no Event Bus. Módulos interessados assinam pelo
/// `type` (ver [DomainEventTypes]) e nunca importam nada do módulo que
/// publicou — é assim que "nenhum módulo conhece outro diretamente" se
/// sustenta na prática.
class DomainEvent {
  final String type;
  final String? moduleId;
  final Map<String, dynamic> payload;
  final DateTime occurredAt;

  DomainEvent({required this.type, this.moduleId, this.payload = const {}, DateTime? occurredAt})
      : occurredAt = occurredAt ?? DateTime.now();
}

/// Nomes de evento como constantes compartilhadas — nunca string solta
/// espalhada pelo código, senão vira exatamente o acoplamento oculto que o
/// Event Bus deveria evitar (quem publica e quem assina precisam concordar
/// no nome, e isso só é seguro se vier de um lugar só).
abstract final class DomainEventTypes {
  static const guestCheckedIn = 'GuestCheckedIn';
  static const guestCheckedOut = 'GuestCheckedOut';
  static const moduleOpened = 'ModuleOpened';
  static const moduleClosed = 'ModuleClosed';
  static const reservationCreated = 'ReservationCreated';
  static const roomServiceOrdered = 'RoomServiceOrdered';
  static const promotionViewed = 'PromotionViewed';
  static const promotionRedeemed = 'PromotionRedeemed';
  static const notificationOpened = 'NotificationOpened';
  static const checkInCompleted = 'CheckInCompleted';
  static const checkOutCompleted = 'CheckOutCompleted';
  static const reviewSubmitted = 'ReviewSubmitted';
}

/// Pub/sub em processo — módulo publica, quem tiver interesse assina pelo
/// `type`. [AnalyticsSubscriber] assina tudo (`onAll`) e nunca é a única
/// coisa ouvindo um evento: outro módulo (ex: Wallet ouvindo
/// `RoomServiceOrdered`) pode assinar o mesmo stream sem saber nada sobre
/// quem publicou.
class EventBus {
  final _controller = StreamController<DomainEvent>.broadcast();

  void publish(DomainEvent event) => _controller.add(event);

  Stream<DomainEvent> on(String type) => _controller.stream.where((event) => event.type == type);

  Stream<DomainEvent> onAll() => _controller.stream;

  void dispose() => _controller.close();
}

/// Instância única do processo — todo módulo publica/assina através dela.
final EventBus eventBus = EventBus();
