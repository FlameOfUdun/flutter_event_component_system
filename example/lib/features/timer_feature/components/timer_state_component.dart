import 'package:flutter_event_component_system/flutter_event_component_system.dart';

final class TimerStateComponent extends ECSComponent<TimerState> {
  TimerStateComponent([super.value = TimerState.stopped]);
}

enum TimerState {
  stopped,
  running,
}
