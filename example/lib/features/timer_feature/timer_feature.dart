import 'package:flutter_event_component_system/flutter_event_component_system.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';

part 'models/timer_state.dart';
part 'timer_feature.ecs.g.dart';

@Component()
TimerState timerState = TimerState.stopped;

@Component()
Duration timerValue = Duration.zero;

@Event()
void resetTimer() {
  handleResetTimer();
}

@Event()
void startTimer() {
  handleStartTimer();
}

@Event()
void stopTimer() {
  handleStopTimer();
}

@ReactiveSystem(reactsIf: startTimerIf)
void handleStartTimer() {
  timerState = TimerState.running;
}

bool startTimerIf() {
  return timerState == TimerState.stopped;
}

@ReactiveSystem(reactsIf: stopTimerIf)
void handleStopTimer() {
  timerState = TimerState.stopped;
}

bool stopTimerIf() {
  return timerState == TimerState.running;
}

@ReactiveSystem()
void handleResetTimer() {
  timerValue = Duration.zero;
}

@ExecuteSystem(executesIf: updateTimerIf)
void handleUpdateTimer(Duration elapsed) {
  timerValue += elapsed;
}

bool updateTimerIf() {
  return timerState == TimerState.running;
}
