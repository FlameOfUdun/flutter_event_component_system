import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:flutter_event_component_system_generator/flutter_event_component_system_generator.dart';

const _declarations = '''
  @ComponentDefinition() const String health = "";
  @DataEventDefinition() const int addHealth = 0;
''';

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
  group('ReactiveSystemGenerator', () {
    test('generates basic reactive system with reactsTo', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          $_declarations
          @ReactiveSystemDefinition(reactsTo: {addHealth})
          void applyAddHealth(SystemReference system) {
            final event = system.getDataEvent(addHealth);
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class ApplyAddHealthReactiveSystem extends ReactiveSystem'),
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
          @ReactiveSystemDefinition(reactsTo: {addHealth}, interactsWith: {health})
          void applyAddHealth(SystemReference system) {
            final component = system.getComponent(health);
            final event = system.getDataEvent(addHealth);
            component.value += event.value;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
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
          @ReactiveSystemDefinition(reactsTo: {addHealth}, interactsWith: {health})
          void applyAddHealth(SystemReference system) {
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

    test('generates reactsIf getter when reactsIf is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          $_declarations
          bool addHealthIf(SystemReference system) {
            final component = system.getComponent(health);
            final event = system.getDataEvent(addHealth);
            return component.value + event.value <= 100;
          }

          @ReactiveSystemDefinition(
            reactsTo: {addHealth},
            interactsWith: {health},
            reactsIf: addHealthIf,
          )
          void applyAddHealth(SystemReference system) {
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

    test('uses custom name from annotation', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          $_declarations
          @ReactiveSystemDefinition(name: "HealPlayer", reactsTo: {addHealth})
          void applyAddHealth(SystemReference system) {}
        '''),
        outputs: {
          _outputKey: decodedMatches(
            contains('final class HealPlayerReactiveSystem'),
          ),
        },
      );
    });

    test('includes doc comment when description is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          $_declarations
          @ReactiveSystemDefinition(
            description: "Applies health to entity",
            reactsTo: {addHealth},
          )
          void applyAddHealth(SystemReference system) {}
        '''),
        outputs: {
          _outputKey: decodedMatches(
            contains('/// Applies health to entity'),
          ),
        },
      );
    });
  });
}
