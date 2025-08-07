import 'package:flutter_event_component_system/flutter_event_component_system.dart';

import '../events/timer_start_event.dart';

final class StartTimerInitializeSystem extends InitializeSystem {
  final ECSManager manager;

  StartTimerInitializeSystem(this.manager);

  @override
  Set<Type> get interactsWith {
    return const {
      TimerStartEvent,
    };
  }

  @override
  void initialize() {
    manager.getEntity<TimerStartEvent>().trigger();
  }
}
