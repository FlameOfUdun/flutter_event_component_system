import 'package:flutter_event_component_system/flutter_event_component_system.dart';

part 'components/timer_state_component.dart';
part 'components/timer_value_component.dart';

part 'events/timer_reset_event.dart';
part 'events/timer_start_event.dart';
part 'events/timer_stop_event.dart';

part 'systems/reset_timer_reactive_system.dart';
part 'systems/start_timer_initialize_system.dart';
part 'systems/start_timer_reactive_system.dart';
part 'systems/stop_timer_reactive_system.dart';
part 'systems/update_timer_execute_system.dart';


part 'models/timer_state.dart';

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
