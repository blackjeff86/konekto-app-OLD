import 'package:flutter_test/flutter_test.dart';
import 'package:konekto/events/event_bus.dart';

void main() {
  group('EventBus', () {
    test('on(type) only receives events with a matching type', () async {
      final bus = EventBus();
      final received = <DomainEvent>[];
      final subscription = bus.on(DomainEventTypes.roomServiceOrdered).listen(received.add);

      bus.publish(DomainEvent(type: DomainEventTypes.roomServiceOrdered, moduleId: 'room_service'));
      bus.publish(DomainEvent(type: DomainEventTypes.promotionViewed, moduleId: 'promotions'));
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single.moduleId, 'room_service');

      await subscription.cancel();
      bus.dispose();
    });

    test('onAll() receives every published event regardless of type', () async {
      final bus = EventBus();
      final received = <DomainEvent>[];
      final subscription = bus.onAll().listen(received.add);

      bus.publish(DomainEvent(type: DomainEventTypes.moduleOpened, moduleId: 'loyalty'));
      bus.publish(DomainEvent(type: DomainEventTypes.moduleClosed, moduleId: 'loyalty'));
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(2));

      await subscription.cancel();
      bus.dispose();
    });

    test('a module never needs to know who published an event it subscribes to', () async {
      final bus = EventBus();
      String? observedModuleId;
      final subscription = bus.on(DomainEventTypes.roomServiceOrdered).listen((event) {
        observedModuleId = event.moduleId;
      });

      // Wallet ouvindo um evento publicado pelo módulo Room Service — sem
      // nenhum import cruzado entre os dois, só o nome do evento em comum.
      bus.publish(DomainEvent(type: DomainEventTypes.roomServiceOrdered, moduleId: 'room_service', payload: {'orderId': 'abc'}));
      await Future<void>.delayed(Duration.zero);

      expect(observedModuleId, 'room_service');

      await subscription.cancel();
      bus.dispose();
    });
  });
}
