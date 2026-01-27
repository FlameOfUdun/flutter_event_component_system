part of '../timer_feature.dart';

final class ResetTimerReactiveSystem extends ReactiveSystem {
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
    final state = getEntity<TimerStateComponent>();
    return state.value == TimerState.stopped;
  }

  @override
  void react() {
    final timer = getEntity<TimerValueComponent>();
    timer.update(Duration.zero);
  }
}
