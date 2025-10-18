import 'package:flutter_event_component_system/flutter_event_component_system.dart';

import 'components/timer_state_component.dart';
import 'components/timer_value_component.dart';
import 'events/timer_reset_event.dart';
import 'events/timer_start_event.dart';
import 'events/timer_stop_event.dart';
import 'systems/reset_timer_reactive_system.dart';
import 'systems/start_timer_initialize_system.dart';
import 'systems/start_timer_reactive_system.dart';
import 'systems/stop_timer_reactive_system.dart';
import 'systems/update_timer_execute_system.dart';

export 'components/timer_value_component.dart';

final class TimerFeature extends ECSFeature {
  TimerFeature() {
    addEntity(TimerValueComponent());
    addEntity(TimerStateComponent());

    addEntity(TimerStartEvent());
    addEntity(TimerStopEvent());
    addEntity(TimerResetEvent());

    addSystem(ResetTimerReactiveSystem());
    addSystem(StartTimerReactiveSystem());
    addSystem(StopTimerReactiveSystem());
    addSystem(UpdateTimerExecuteSystem());
    addSystem(StartTimerInitializeSystem());
  }
}
