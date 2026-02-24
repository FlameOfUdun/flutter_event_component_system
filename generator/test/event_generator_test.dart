import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:flutter_event_component_system_generator/flutter_event_component_system_generator.dart';

const _outputKey = 'flutter_event_component_system_generator|lib/input.ecs.dart';

const _annotationAsset = 'flutter_event_component_system_annotations|lib/flutter_event_component_system_annotations.dart';

const _annotationSource = '''
  class ComponentDefinition {
    final String? name;
    final String? description;
    const ComponentDefinition({this.name, this.description});
  }
  class EventDefinition {
    final String? name;
    final String? description;
    const EventDefinition({this.name, this.description});
  }
  class DataEventDefinition {
    final String? name;
    final String? description;
    const DataEventDefinition({this.name, this.description});
  }
  class ReactiveSystemDefinition {
    final String? name;
    final String? description;
    final Set<Object> reactsTo;
    final Set<Object> interactsWith;
    final bool Function(dynamic)? reactsIf;
    const ReactiveSystemDefinition({
      this.name,
      this.description,
      required this.reactsTo,
      this.interactsWith = const {},
      this.reactsIf,
    });
  }
  class FeatureDefinition {
    final String? name;
    final String? description;
    const FeatureDefinition({this.name, this.description});
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
        buildSources('@EventDefinition() const resetHealth = null;'),
        outputs: {
          _outputKey: decodedMatches(
            contains('final class ResetHealthEvent extends ECSEvent {}'),
          ),
        },
      );
    });

    test('uses custom name from annotation', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@EventDefinition(name: "AddHealth") const resetHealth = null;'),
        outputs: {
          _outputKey: decodedMatches(
            contains('final class AddHealthEvent extends ECSEvent {}'),
          ),
        },
      );
    });

    test('includes doc comment when description is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@EventDefinition(description: "Resets player health") const resetHealth = null;'),
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
