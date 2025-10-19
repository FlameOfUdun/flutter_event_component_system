import 'package:flutter_event_component_system/flutter_event_component_system.dart';

import '../components/timer_value_component.dart';
import '../components/timer_state_component.dart';

final class UpdateTimerExecuteSystem extends ExecuteSystem {
  TimerValueComponent? timer;
  TimerStateComponent? state;

  Duration? duration;

  UpdateTimerExecuteSystem();

  @override
  Set<Type> get interactsWith {
    return const {
      TimerValueComponent,
    };
  }

  @override
  bool get executesIf {
    timer ??= manager.getEntity<TimerValueComponent>();
    state ??= manager.getEntity<TimerStateComponent>();
    return state!.value == TimerState.running;
  }

  @override
  void execute(Duration elapsed) {
    final value = timer!.value + elapsed;
    timer!.update(value);
  }
}
