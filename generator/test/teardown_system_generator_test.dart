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
  class ECSTeardownSystemDefinition {
    final String? description;
    const ECSTeardownSystemDefinition({this.description});
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
  group('TeardownSystemGenerator', () {
    test('generates class extending ECSTeardownSystem', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @ECSComponentDefinition() const int health = 0;
          @ECSTeardownSystemDefinition()
          void teardownPlayer(ECSSystemReference system) {
            system.getComponent(health);
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class TeardownPlayerTeardownSystem extends ECSTeardownSystem'),
            contains('void teardown()'),
            contains('getEntity<HealthComponent>()'),
          ])),
        },
      );
    });

    test('appends TeardownSystem suffix to class name', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @ECSTeardownSystemDefinition()
          void dispose(ECSSystemReference system) {}
        '''),
        outputs: {
          _outputKey: decodedMatches(
            contains('final class DisposeTeardownSystem extends ECSTeardownSystem'),
          ),
        },
      );
    });

    test('does not double-append TeardownSystem suffix', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @ECSTeardownSystemDefinition()
          void disposePlayerTeardownSystem(ECSSystemReference system) {}
        '''),
        outputs: {
          _outputKey: decodedMatches(
            isNot(contains('TeardownSystemTeardownSystem')),
          ),
        },
      );
    });

    test('includes doc comment when description provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @ECSTeardownSystemDefinition(description: "Tears down the player")
          void teardownPlayer(ECSSystemReference system) {}
        '''),
        outputs: {
          _outputKey: decodedMatches(contains('/// Tears down the player')),
        },
      );
    });
  });
}
