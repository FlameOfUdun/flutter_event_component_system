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
  class ECSCleanupSystemDefinition {
    final String? description;
    final bool Function(dynamic)? cleansIf;
    const ECSCleanupSystemDefinition({this.description, this.cleansIf});
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
  group('CleanupSystemGenerator', () {
    test('generates class extending ECSCleanupSystem', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @ECSComponentDefinition() const int health = 0;
          @ECSCleanupSystemDefinition()
          void cleanupPlayer(ECSSystemReference system) {
            system.getComponent(health);
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class CleanupPlayerCleanupSystem extends ECSCleanupSystem'),
            contains('void cleanup()'),
            contains('getEntity<HealthComponent>()'),
          ])),
        },
      );
    });

    test('appends CleanupSystem suffix to class name', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @ECSCleanupSystemDefinition()
          void clean(ECSSystemReference system) {}
        '''),
        outputs: {
          _outputKey: decodedMatches(
            contains('final class CleanCleanupSystem extends ECSCleanupSystem'),
          ),
        },
      );
    });

    test('generates cleansIf getter when cleansIf is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @ECSComponentDefinition() const int health = 0;
          bool shouldClean(ECSSystemReference system) {
            return system.getComponent(health).value <= 0;
          }
          @ECSCleanupSystemDefinition(cleansIf: shouldClean)
          void cleanupPlayer(ECSSystemReference system) {}
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('bool get cleansIf'),
            contains('getEntity<HealthComponent>()'),
            contains('<= 0'),
          ])),
        },
      );
    });

    test('includes doc comment when description provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @ECSCleanupSystemDefinition(description: "Cleans up after player dies")
          void cleanupPlayer(ECSSystemReference system) {}
        '''),
        outputs: {
          _outputKey: decodedMatches(contains('/// Cleans up after player dies')),
        },
      );
    });
  });
}
