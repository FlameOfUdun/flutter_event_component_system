import 'package:flutter_event_component_system/flutter_event_component_system.dart';

import '../components/timer_value_component.dart';
import '../components/timer_state_component.dart';
import '../events/timer_reset_event.dart';

final class ResetTimerReactiveSystem extends ReactiveSystem {
  ResetTimerReactiveSystem();

  @override
  Set<Type> get reactsTo {
    return const {
      TimerResetEvent,
    };
  }

  @override
  Set<Type> get interactsWith {
    return const {
      TimerValueComponent,
    };
  }

  @override
  bool get reactsIf {
    final state = manager.getEntity<TimerStateComponent>();
    return state.value == TimerState.stopped;
  }

  @override
  void react() {
    final timer = manager.getEntity<TimerValueComponent>();
    timer.update(Duration.zero);
  }
}
