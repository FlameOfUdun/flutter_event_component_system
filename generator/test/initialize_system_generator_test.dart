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
  class ECSInitializeSystemDefinition {
    final String? description;
    const ECSInitializeSystemDefinition({this.description});
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
  group('InitializeSystemGenerator', () {
    test('generates class extending ECSInitializeSystem', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @ECSComponentDefinition() const int health = 0;
          @ECSInitializeSystemDefinition()
          void setupPlayer(ECSSystemReference system) {
            system.getComponent(health);
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class SetupPlayerInitializeSystem extends ECSInitializeSystem'),
            contains('void initialize()'),
            contains('getEntity<HealthComponent>()'),
          ])),
        },
      );
    });

    test('appends InitializeSystem suffix to class name', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @ECSInitializeSystemDefinition()
          void setup(ECSSystemReference system) {}
        '''),
        outputs: {
          _outputKey: decodedMatches(
            contains('final class SetupInitializeSystem extends ECSInitializeSystem'),
          ),
        },
      );
    });

    test('does not double-append InitializeSystem suffix', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @ECSInitializeSystemDefinition()
          void setupPlayerInitializeSystem(ECSSystemReference system) {}
        '''),
        outputs: {
          _outputKey: decodedMatches(
            isNot(contains('InitializeSystemInitializeSystem')),
          ),
        },
      );
    });

    test('includes doc comment when description provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @ECSInitializeSystemDefinition(description: "Sets up the player")
          void setupPlayer(ECSSystemReference system) {}
        '''),
        outputs: {
          _outputKey: decodedMatches(contains('/// Sets up the player')),
        },
      );
    });

  });
}
