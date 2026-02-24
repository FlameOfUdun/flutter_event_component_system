import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:flutter_event_component_system_generator/flutter_event_component_system_generator.dart';

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

const _outputKey =
    'flutter_event_component_system_generator|lib/input.ecs.dart';

Map<String, String> _buildSources({
  String libraryDirective = '',
  required String body,
}) {
  return {
    _annotationAsset: _annotationSource,
    'flutter_event_component_system_generator|lib/input.dart': '''
      $libraryDirective

      import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
      part 'input.ecs.dart';

      $body
    ''',
  };
}

void main() {
  group('FeatureGenerator (library-level)', () {
    test('generates feature from library-level annotation', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        _buildSources(
          libraryDirective: '@FeatureDefinition(name: "Generated") library;',
          body: '''
            @ComponentDefinition() const String health = "";
            @DataEventDefinition() const int addHealth = 0;

            @ReactiveSystemDefinition(reactsTo: {addHealth}, interactsWith: {health})
            void applyAddHealth(SystemReference system) {
              final component = system.getComponent(health);
              final event = system.getDataEvent(addHealth);
              component.value += event.value;
            }
          ''',
        ),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class GeneratedFeature extends ECSFeature'),
            contains('addEntity(HealthComponent())'),
            contains('addEntity(AddHealthEvent())'),
            contains('addSystem(ApplyAddHealthReactiveSystem())'),
          ])),
        },
        onLog: print,
      );
    });

    test('uses custom name from annotation', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        _buildSources(
          libraryDirective: '@FeatureDefinition(name: "Combat") library;',
          body: '@ComponentDefinition() const String health = "";',
        ),
        outputs: {
          _outputKey: decodedMatches(
            contains('final class CombatFeature extends ECSFeature'),
          ),
        },
      );
    });

    test('does not double-append Feature suffix', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        _buildSources(
          libraryDirective:
              '@FeatureDefinition(name: "CombatFeature") library;',
          body: '@ComponentDefinition() const String health = "";',
        ),
        outputs: {
          _outputKey: decodedMatches(
            isNot(contains('CombatFeatureFeature')),
          ),
        },
      );
    });

    test('includes doc comment when description is set', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        _buildSources(
          libraryDirective:
              '@FeatureDefinition(description: "Handles health logic") library;',
          body: '@ComponentDefinition() const String health = "";',
        ),
        outputs: {
          _outputKey: decodedMatches(contains('/// Handles health logic')),
        },
      );
    });

    test('returns null when no @FeatureDefinition on library', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        _buildSources(
          body: '@ComponentDefinition() const String health = "";',
        ),
        outputs: {
          _outputKey: decodedMatches(
            isNot(contains('extends ECSFeature')),
          ),
        },
      );
    });
  });

  group('FeatureGenerator (function-level)', () {
    test('generates feature from annotated build function', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        _buildSources(
          body: '''
            @ComponentDefinition() const String health = "";
            @DataEventDefinition() const int addHealth = 0;

            @ReactiveSystemDefinition(reactsTo: {addHealth}, interactsWith: {health})
            void applyAddHealth(SystemReference system) {}

            @FeatureDefinition()
            void buildGeneratedFeature(FeatureReference feature) {
              feature.addComponent(health);
              feature.addDataEvent(addHealth);
              feature.addReactiveSystem(applyAddHealth);
            }
          ''',
        ),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class GeneratedFeature extends ECSFeature'),
            contains('addEntity(HealthComponent())'),
            contains('addEntity(AddHealthEvent())'),
            contains('addSystem(ApplyAddHealthReactiveSystem())'),
          ])),
        },
      );
    });

    test('strips build prefix from function name', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        _buildSources(
          body: '''
            @ComponentDefinition() const String health = "";

            @FeatureDefinition()
            void buildPlayerFeature(FeatureReference feature) {
              feature.addComponent(health);
            }
          ''',
        ),
        outputs: {
          _outputKey: decodedMatches(
            contains('final class PlayerFeature extends ECSFeature'),
          ),
        },
      );
    });

    test('preserves named constructor params', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        _buildSources(
          body: '''
            @ComponentDefinition() const String health = "";

            @FeatureDefinition()
            void buildGeneratedFeature(
              FeatureReference feature, {
              bool mock = false,
            }) {
              if (mock) return;
              feature.addComponent(health);
            }
          ''',
        ),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('bool mock = false'),
            contains('if (mock) return;'),
          ])),
        },
      );
    });
  });
}
