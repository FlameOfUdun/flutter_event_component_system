import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generators/component_generator.dart';
import 'src/generators/event_generator.dart';
import 'src/generators/feature_generator.dart';
import 'src/generators/system_generator.dart';

Builder ecsBuilder(BuilderOptions options) {
  final generators = const [
    ComponentGenerator(),
    EventGenerator(),
    DataEventGenerator(),
    ReactiveSystemGenerator(),
    FeatureGenerator(),
  ];
  return PartBuilder(generators, '.ecs.dart');
}
