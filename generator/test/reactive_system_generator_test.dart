import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:flutter_event_component_system_generator/flutter_event_component_system_generator.dart';

const _declarations = '''
  @ECSComponentDefinition() const String health = "";
  @ECSDataEventDefinition() const int addHealth = 0;
''';

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
  class ECSFeatureDefinition {
    final String? description;
    const ECSFeatureDefinition({this.description});
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
  group('ReactiveSystemGenerator', () {
    test('generates basic reactive system with reactsTo', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          $_declarations
          @ECSReactiveSystemDefinition(reactsTo: {addHealth})
          void applyAddHealth(ECSSystemReference system) {
            final event = system.getDataEvent(addHealth);
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class ApplyAddHealthReactiveSystem extends ECSReactiveSystem'),
            contains('Set<Type> get reactsTo'),
            contains('AddHealthEvent'),
            contains('void react()'),
          ])),
        },
        onLog: print,
      );
    });

    test('generates interactsWith getter when provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          $_declarations
          @ECSReactiveSystemDefinition(reactsTo: {addHealth}, interactsWith: {health})
          void applyAddHealth(ECSSystemReference system) {
            final component = system.getComponent(health);
            final event = system.getDataEvent(addHealth);
            component.value += event.value;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('extends ECSReactiveSystem'),
            contains('Set<Type> get interactsWith'),
            contains('HealthComponent'),
          ])),
        },
      );
    });

    test('transforms system.getComponent calls in react body', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          $_declarations
          @ECSReactiveSystemDefinition(reactsTo: {addHealth}, interactsWith: {health})
          void applyAddHealth(ECSSystemReference system) {
            final component = system.getComponent(health);
            final event = system.getDataEvent(addHealth);
            component.value += event.value;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('getEntity<HealthComponent>()'),
            contains('getEntity<AddHealthEvent>()'),
          ])),
        },
      );
    });

    test('appends Component suffix in react body', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          $_declarations
          @ECSReactiveSystemDefinition(reactsTo: {addHealth}, interactsWith: {health})
          void applyAddHealth(ECSSystemReference system) {
            final c = system.getComponent(health);
            final e = system.getDataEvent(addHealth);
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('getEntity<HealthComponent>()'),
            contains('getEntity<AddHealthEvent>()'),
            isNot(contains('getEntity<Health>()')),
            isNot(contains('getEntity<AddHealth>()')),
          ])),
        },
      );
    });

    test('appends Event suffix for getEvent in react body', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @ECSEventDefinition() const reset = null;
          @ECSReactiveSystemDefinition(reactsTo: {reset})
          void onReset(ECSSystemReference system) {
            system.getEvent(reset);
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(contains('getEntity<ResetEvent>()')),
        },
      );
    });

    test('appends Dependency suffix in react body', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @ECSDependencyDefinition() const String repo = "";
          @ECSReactiveSystemDefinition(reactsTo: {})
          void onTick(ECSSystemReference system) {
            system.getDependency(repo);
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(contains('getEntity<RepoDependency>()')),
        },
      );
    });

    test('generates reactsIf getter when reactsIf is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          $_declarations
          bool addHealthIf(ECSSystemReference system) {
            final component = system.getComponent(health);
            final event = system.getDataEvent(addHealth);
            return component.value + event.value <= 100;
          }

          @ECSReactiveSystemDefinition(
            reactsTo: {addHealth},
            interactsWith: {health},
            reactsIf: addHealthIf,
          )
          void applyAddHealth(ECSSystemReference system) {
            final component = system.getComponent(health);
            final event = system.getDataEvent(addHealth);
            component.value += event.value;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('bool get reactsIf'),
            contains('getEntity<HealthComponent>()'),
            contains('getEntity<AddHealthEvent>()'),
            contains('<= 100'),
          ])),
        },
      );
    });

    test('transforms system calls inside reactsIf body', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          $_declarations
          bool canApply(ECSSystemReference system) {
            return system.getComponent(health).value < 100;
          }
          @ECSReactiveSystemDefinition(
            reactsTo: {addHealth},
            interactsWith: {health},
            reactsIf: canApply,
          )
          void applyAddHealth(ECSSystemReference system) {}
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('bool get reactsIf'),
            contains('getEntity<HealthComponent>()'),
            isNot(contains('system.getComponent(health)')),
          ])),
        },
      );
    });

    test('includes doc comment when description is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          $_declarations
          @ECSReactiveSystemDefinition(
            description: "Applies health to entity",
            reactsTo: {addHealth},
          )
          void applyAddHealth(ECSSystemReference system) {}
        '''),
        outputs: {
          _outputKey: decodedMatches(
            contains('/// Applies health to entity'),
          ),
        },
      );
    });

    test('resolves reactsTo and interactsWith from imported file', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        {
          _annotationAsset: _annotationSource,
          'flutter_event_component_system_generator|lib/entities.dart': '''
            import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
            @ECSComponentDefinition() const String health = "";
            @ECSDataEventDefinition() const int addHealth = 0;
          ''',
          'flutter_event_component_system_generator|lib/input.dart': '''
            import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
            import 'entities.dart';
            part 'input.ecs.dart';

            @ECSReactiveSystemDefinition(reactsTo: {addHealth}, interactsWith: {health})
            void applyAddHealth(ECSSystemReference system) {
              final component = system.getComponent(health);
              final event = system.getDataEvent(addHealth);
              component.value += event.value;
            }
          ''',
        },
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('return const {AddHealthEvent'),
            contains('return const {HealthComponent'),
          ])),
        },
      );
    });
  });
}
