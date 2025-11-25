import 'package:flutter_event_component_system/flutter_event_component_system.dart';

import '../components/timer_state_component.dart';
import '../events/timer_start_event.dart';

final class StartTimerReactiveSystem extends ReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return const {
      TimerStartEvent,
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
    final state = getEntity<TimerStateComponent>();
    return state.value == TimerState.stopped;
  }

  @override
  void react() {
    final state = getEntity<TimerStateComponent>();
    state.update(TimerState.running);
  }
}
