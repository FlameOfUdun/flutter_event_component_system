import 'package:flutter_event_component_system/flutter_event_component_system.dart';

import '../components/timer_state_component.dart';
import '../events/timer_stop_event.dart';

final class StopTimerReactiveSystem extends ReactiveSystem {
  StopTimerReactiveSystem();

  @override
  Set<Type> get reactsTo {
    return const {
      TimerStopEvent,
    };
  }

  @override
  Set<Type> get interactsWith {
    return const {
      TimerStateComponent,
    };
  }

  @override
  bool get reactsIf {
    final state = manager.getEntity<TimerStateComponent>();
    return state.value == TimerState.running;
  }

  @override
  void react() {
    final state = manager.getEntity<TimerStateComponent>();
    state.update(TimerState.stopped);
  }
}
