part of '../timer_feature.dart';

final class UpdateTimerExecuteSystem extends ECSExecuteSystem {
  Duration? duration;

  @override
  Set<Type> get interactsWith {
    return const {
      TimerValueComponent,
    };
  }

  @override
  bool get executesIf {
    final state = getEntity<TimerStateComponent>();
    return state.value == TimerState.running;
  }

  @override
  void execute(Duration elapsed) {
    final timer = getEntity<TimerValueComponent>();
    timer.value = timer.value + elapsed;
  }
}
