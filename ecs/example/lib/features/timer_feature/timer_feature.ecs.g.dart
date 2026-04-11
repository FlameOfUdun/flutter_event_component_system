// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_feature.dart';

final class TimerStateComponent extends ECSComponent<TimerState> {
  TimerStateComponent() : super(TimerState.stopped);
}

final class TimerValueComponent extends ECSComponent<Duration> {
  TimerValueComponent() : super(Duration.zero);
}

final class ResetTimerEvent extends ECSEvent {}

final class StartTimerEvent extends ECSEvent {}

final class StopTimerEvent extends ECSEvent {}

final class HandleStartTimerReactiveSystem extends ECSReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return const {StartTimerEvent};
  }

  @override
  Set<Type> get interactsWith {
    return const {TimerStateComponent};
  }

  @override
  bool get reactsIf {
    return getEntity<TimerStateComponent>().value == TimerState.stopped;
  }

  @override
  void react() {
    getEntity<TimerStateComponent>().value = TimerState.running;
  }
}

final class HandleStopTimerReactiveSystem extends ECSReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return const {StopTimerEvent};
  }

  @override
  Set<Type> get interactsWith {
    return const {TimerStateComponent};
  }

  @override
  bool get reactsIf {
    return getEntity<TimerStateComponent>().value == TimerState.running;
  }

  @override
  void react() {
    getEntity<TimerStateComponent>().value = TimerState.stopped;
  }
}

final class HandleResetTimerReactiveSystem extends ECSReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return const {ResetTimerEvent};
  }

  @override
  Set<Type> get interactsWith {
    return const {TimerValueComponent};
  }

  @override
  void react() {
    getEntity<TimerValueComponent>().value = Duration.zero;
  }
}

final class HandleUpdateTimerExecuteSystem extends ECSExecuteSystem {
  @override
  Set<Type> get interactsWith {
    return const {TimerValueComponent};
  }

  @override
  bool get executesIf {
    return getEntity<TimerStateComponent>().value == TimerState.running;
  }

  @override
  void execute(Duration elapsed) {
    getEntity<TimerValueComponent>().value += elapsed;
  }
}

final class TimerFeature extends ECSFeature {
  TimerFeature() {
    addEntity(TimerStateComponent());
    addEntity(TimerValueComponent());
    addEntity(ResetTimerEvent());
    addEntity(StartTimerEvent());
    addEntity(StopTimerEvent());
    addSystem(HandleStartTimerReactiveSystem());
    addSystem(HandleStopTimerReactiveSystem());
    addSystem(HandleResetTimerReactiveSystem());
    addSystem(HandleUpdateTimerExecuteSystem());
  }
}
