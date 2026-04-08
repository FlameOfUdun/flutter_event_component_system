part of '../timer_feature.dart';

final class StartTimerReactiveSystem extends ECSReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return const {
      TimerStartEvent,
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
    return state.value == TimerState.stopped;
  }

  @override
  void react() {
    final state = getEntity<TimerStateComponent>();
    state.update(TimerState.running);
  }
}
