import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:flutter_event_component_system_generator/flutter_event_component_system_generator.dart';

const _outputKey = 'flutter_event_component_system_generator|lib/input.ecs.dart';

const _annotationAsset = 'flutter_event_component_system_annotations|lib/flutter_event_component_system_annotations.dart';

const _annotationSource = '''
  class ECSComponentDefinition {
    final String? description;
    const ECSComponentDefinition({this.description});
  }
  class ECSEventDefinition {
    final String? description;
    const ECSEventDefinition({this.description});
  }
  class ECSDataEventDefinition {
    final String? description;
    const ECSDataEventDefinition({this.description});
  }
  class ECSReactiveSystemDefinition {
    final String? description;
    final Set<Object> reactsTo;
    final Set<Object> interactsWith;
    final bool Function(dynamic)? reactsIf;
    const ECSReactiveSystemDefinition({
      this.description,
      required this.reactsTo,
      this.interactsWith = const {},
      this.reactsIf,
    });
  }
  class FeatureDefinition {
    final String? description;
    const FeatureDefinition({this.description});
  }
  class ECSDependencyDefinition {
    final String? description;
    const ECSDependencyDefinition({this.description});
  }
''';

Map<String, String> buildSources(String body) {
  return {
    _annotationAsset: _annotationSource,
    'flutter_event_component_system_generator|lib/input.dart': '''
        import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
        part 'input.ecs.dart';
        $body
      ''',
  };
}

void main() {
  group('EventGenerator', () {
    test('generates event class from variable name', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@ECSEventDefinition() const resetHealth = null;'),
        outputs: {
          _outputKey: decodedMatches(
            contains('final class ResetHealthEvent extends ECSEvent {}'),
          ),
        },
      );
    });

    test('includes doc comment when description is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@ECSEventDefinition(description: "Resets player health") const resetHealth = null;'),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('/// Resets player health'),
            contains('final class ResetHealthEvent extends ECSEvent {}'),
          ])),
        },
      );
    });
  });
}
