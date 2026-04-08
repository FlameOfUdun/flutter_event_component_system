part of '../timer_feature.dart';

final class StopTimerReactiveSystem extends ECSReactiveSystem {
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
    final state = getEntity<TimerStateComponent>();
    return state.value == TimerState.running;
  }

  @override
  void react() {
    final state = getEntity<TimerStateComponent>();
    state.update(TimerState.stopped);
  }
}
