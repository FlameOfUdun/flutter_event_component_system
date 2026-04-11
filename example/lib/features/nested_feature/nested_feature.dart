import 'package:flutter_event_component_system/flutter_event_component_system.dart';

part 'nested_feature.ecs.g.dart';

final nestedFeature = ECS.createFeature();

final counter = nestedFeature.addComponent(0);

final add = nestedFeature.addDataEvent<int>();

final deduct = nestedFeature.addDataEvent<int>();

final handleAdd = nestedFeature.addReactiveSystem(
  reactsTo: {add},
  react: () {
    counter.value += add.data;
  },
);

final handleDeduct = nestedFeature.addReactiveSystem(
  reactsTo: {deduct},
  react: () {
    counter.value -= deduct.data;
  },
);
