part of '../timer_feature.dart';

final class StartTimerInitializeSystem extends ECSInitializeSystem {
  @override
  Set<Type> get interactsWith {
    return const {
      TimerStartEvent,
    };
  }

  @override
  void initialize() {
    getEntity<TimerStartEvent>().trigger();
  }
}
