// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nested_feature.dart';

final class CounterComponent extends ECSComponent<int> {
  CounterComponent() : super(0);
}

final class AddEvent extends ECSDataEvent<int> {}

final class DeductEvent extends ECSDataEvent<int> {}

final class HandleAddReactiveSystem extends ECSReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return const {AddEvent};
  }

  @override
  Set<Type> get interactsWith {
    return const {CounterComponent};
  }

  @override
  void react() {
    getEntity<CounterComponent>().value += getEntity<AddEvent>().data;
  }
}

final class HandleDeductReactiveSystem extends ECSReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return const {DeductEvent};
  }

  @override
  Set<Type> get interactsWith {
    return const {CounterComponent};
  }

  @override
  void react() {
    getEntity<CounterComponent>().value -= getEntity<DeductEvent>().data;
  }
}

final class NestedFeature extends ECSFeature {
  NestedFeature() {
    addEntity(CounterComponent());
    addEntity(AddEvent());
    addEntity(DeductEvent());
    addSystem(HandleAddReactiveSystem());
    addSystem(HandleDeductReactiveSystem());
  }
}
