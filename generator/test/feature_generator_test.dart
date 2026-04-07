import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:flutter_event_component_system_generator/flutter_event_component_system_generator.dart';

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
          libraryDirective: '@FeatureDefinition() library;',
          body: '''
            @ECSComponentDefinition() const String health = "";
            @ECSDataEventDefinition() const int addHealth = 0;

            @ECSReactiveSystemDefinition(reactsTo: {addHealth}, interactsWith: {health})
            void applyAddHealth(ECSSystemReference system) {
              final component = system.getComponent(health);
              final event = system.getDataEvent(addHealth);
              component.value += event.value;
            }
          ''',
        ),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('extends ECSFeature'),
            contains('addEntity(HealthComponent())'),
            contains('addEntity(AddHealthEvent())'),
            contains('addSystem(ApplyAddHealthReactiveSystem())'),
          ])),
        },
        onLog: print,
      );
    });

    test('includes ECSDependencyDefinition entities in library-mode feature', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        _buildSources(
          libraryDirective: '@FeatureDefinition(description: "Player feature") library;',
          body: '''
            @ECSComponentDefinition() const int health = 0;
            @ECSDependencyDefinition() const String repo = "";
          ''',
        ),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('addEntity(HealthComponent())'),
            contains('addEntity(RepoDependency())'),
          ])),
        },
      );
    });

    test('includes doc comment when description is set', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        _buildSources(
          libraryDirective:
              '@FeatureDefinition(description: "Handles health logic") library;',
          body: '@ECSComponentDefinition() const String health = "";',
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
          body: '@ECSComponentDefinition() const String health = "";',
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
            @ECSComponentDefinition() const String health = "";
            @ECSDataEventDefinition() const int addHealth = 0;

            @ECSReactiveSystemDefinition(reactsTo: {addHealth}, interactsWith: {health})
            void applyAddHealth(ECSSystemReference system) {}

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
            @ECSComponentDefinition() const String health = "";

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
            @ECSComponentDefinition() const String health = "";

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

    test('transforms feature.addDependency call', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        _buildSources(
          body: '''
            @ECSDependencyDefinition() const String repo = "";

            @FeatureDefinition()
            void buildPlayerFeature(FeatureReference feature) {
              feature.addDependency(repo);
            }
          ''',
        ),
        outputs: {
          _outputKey: decodedMatches(contains('addEntity(RepoDependency())')),
        },
      );
    });

    test('transforms feature.addInitializeSystem call', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        _buildSources(
          body: '''
            @FeatureDefinition()
            void buildPlayerFeature(FeatureReference feature) {
              feature.addInitializeSystem(setupPlayer);
            }
            void setupPlayer() {}
          ''',
        ),
        outputs: {
          _outputKey: decodedMatches(contains('addSystem(SetupPlayerInitializeSystem())')),
        },
      );
    });

    test('transforms feature.addExecuteSystem call', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        _buildSources(
          body: '''
            @FeatureDefinition()
            void buildPlayerFeature(FeatureReference feature) {
              feature.addExecuteSystem(tickPlayer);
            }
            void tickPlayer() {}
          ''',
        ),
        outputs: {
          _outputKey: decodedMatches(contains('addSystem(TickPlayerExecuteSystem())')),
        },
      );
    });

    test('transforms feature.addCleanupSystem call', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        _buildSources(
          body: '''
            @FeatureDefinition()
            void buildPlayerFeature(FeatureReference feature) {
              feature.addCleanupSystem(cleanPlayer);
            }
            void cleanPlayer() {}
          ''',
        ),
        outputs: {
          _outputKey: decodedMatches(contains('addSystem(CleanPlayerCleanupSystem())')),
        },
      );
    });

    test('transforms feature.addTeardownSystem call', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        _buildSources(
          body: '''
            @FeatureDefinition()
            void buildPlayerFeature(FeatureReference feature) {
              feature.addTeardownSystem(disposePlayer);
            }
            void disposePlayer() {}
          ''',
        ),
        outputs: {
          _outputKey: decodedMatches(contains('addSystem(DisposePlayerTeardownSystem())')),
        },
      );
    });
  });
}
