import 'package:flutter_event_component_system/flutter_event_component_system.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';

part 'models/timer_state.dart';
part 'timer_feature.ecs.g.dart';

@Component()
TimerState timerState = TimerState.stopped;

@Component()
Duration timerValue = Duration.zero;

@Event()
void resetTimer() {}

@Event()
void startTimer() {}

@Event()
void stopTimer() {}

@ReactiveSystem()
class HandleStartTimer {
  List get reactsTo {
    return [startTimer];
  }

  bool get reactsIf {
    return timerState == TimerState.stopped;
  }

  void react() {
    timerState = TimerState.running;
  }
}

@ReactiveSystem()
class HandleStopTimer {
  List get reactsTo {
    return [stopTimer];
  }

  bool get reactsIf {
    return timerState == TimerState.running;
  }

  void react() {
    timerState = TimerState.stopped;
  }
}

@ReactiveSystem()
class HandleResetTimer {
  List get reactsTo {
    return [resetTimer];
  }

  bool get reactsIf {
    return true;
  }

  void react() {
    timerValue = Duration.zero;
  }
}

@ExecuteSystem()
class HandleUpdateTimer {
  bool get executesIf {
    return timerState == TimerState.running;
  }

  void execute(Duration elapsed) {
    timerValue += elapsed;
  }
}
