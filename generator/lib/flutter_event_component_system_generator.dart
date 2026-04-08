import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generators/entity_generator.dart';
import 'src/generators/feature_generator.dart';
import 'src/generators/system_generator.dart';

Builder ecsBuilder(BuilderOptions options) {
  final generators = [
    const ComponentGenerator(),
    const EventGenerator(),
    const DependencyGenerator(),
    const ReactiveSystemGenerator(),
    const InitializeSystemGenerator(),
    const TeardownSystemGenerator(),
    const CleanupSystemGenerator(),
    const ExecuteSystemGenerator(),
    const FeatureGenerator(),
  ];
  return PartBuilder(generators, '.ecs.g.dart');
}
