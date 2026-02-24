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
  group('ComponentGenerator', () {
    test('generates component class from const String variable', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@ComponentDefinition() const String name = "";'),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class NameComponent extends ECSComponent<String>'),
            contains('NameComponent([super.value = ""])'),
          ])),
        },
      );
    });

    test('generates component class from const int variable', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@ComponentDefinition() const int health = 100;'),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class HealthComponent extends ECSComponent<int>'),
            contains('HealthComponent([super.value = 100])'),
          ])),
        },
      );
    });

    test('generates component class from const bool variable', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@ComponentDefinition() const bool isActive = false;'),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class IsActiveComponent extends ECSComponent<bool>'),
            contains('IsActiveComponent([super.value = false])'),
          ])),
        },
      );
    });

    test('uses custom name from annotation', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@ComponentDefinition(name: "PlayerName") const String name = "";'),
        outputs: {
          _outputKey: decodedMatches(contains('final class PlayerName')),
        },
      );
    });

    test('includes doc comment when description is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@ComponentDefinition(description: "Player score") const int score = 0;'),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('/// Player score'),
            contains('final class ScoreComponent'),
          ])),
        },
      );
    });
  });
}
