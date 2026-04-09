import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:flutter_event_component_system_generator/flutter_event_component_system_generator.dart';

const _outputKey =
    'flutter_event_component_system_generator|lib/input.ecs.g.dart';
const _annotationAsset =
    'flutter_event_component_system_annotations|lib/flutter_event_component_system_annotations.dart';
const _annotationSource = '''
  final class Component { final String? description; const Component({this.description}); }
  final class Event { final String? description; const Event({this.description}); }
  final class Dependency { final String? description; const Dependency({this.description}); }
  final class ReactiveSystem { final String? description; final Function? reactsIf; const ReactiveSystem({this.description, this.reactsIf}); }
  final class InitializeSystem { final String? description; const InitializeSystem({this.description}); }
  final class TeardownSystem { final String? description; const TeardownSystem({this.description}); }
  final class CleanupSystem { final String? description; const CleanupSystem({this.description}); }
  final class ExecuteSystem { final String? description; const ExecuteSystem({this.description}); }
''';

Map<String, String> buildSources(String body) {
  return {
    _annotationAsset: _annotationSource,
    'flutter_event_component_system_generator|lib/input.dart': '''
        import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
        part 'input.ecs.g.dart';
        $body
      ''',
  };
}

void main() {
  group('ReactiveSystemGenerator', () {
    test('auto-detects reactsTo from @Event function body', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) { applyAddHealth(amount); }

          @ReactiveSystem()
          void applyAddHealth(int amount) {
            health += amount;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class ApplyAddHealthReactiveSystem extends ECSReactiveSystem'),
            contains('Set<Type> get reactsTo'),
            contains('AddHealthEvent'),
          ])),
        },
      );
    });

    test('auto-detects interactsWith from writes in body', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) { applyAddHealth(amount); }

          @ReactiveSystem()
          void applyAddHealth(int amount) {
            health += amount;
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

    test('rewrites component write in react body', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) { applyAddHealth(amount); }

          @ReactiveSystem()
          void applyAddHealth(int amount) {
            health += amount;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(
            contains('getEntity<HealthComponent>().value += '),
          ),
        },
      );
    });

    test('injects event data replacing system parameter', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) { applyAddHealth(amount); }

          @ReactiveSystem()
          void applyAddHealth(int amount) {
            health += amount;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('getEntity<AddHealthEvent>().data'),
            isNot(contains('void react(int amount)')),
          ])),
        },
      );
    });

    test('handles no-data reactive system with no parameter', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 100;
          @Event() void logout() { logoutSystem(); }

          @ReactiveSystem()
          void logoutSystem() {
            health = 0;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('LogoutEvent'),
            contains('getEntity<HealthComponent>().value = 0'),
          ])),
        },
      );
    });

    test('private helpers become private methods on generated class', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) { applyAddHealth(amount); }

          @ReactiveSystem()
          void applyAddHealth(int amount) {
            _doApply(amount);
          }

          void _doApply(int amount) {
            health += amount;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('void _doApply('),
            contains('getEntity<HealthComponent>().value'),
          ])),
        },
      );
    });

    test('private helper writes are included in interactsWith', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) { applyAddHealth(amount); }

          @ReactiveSystem()
          void applyAddHealth(int amount) {
            _doApply(amount);
          }

          void _doApply(int amount) {
            health += amount;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(contains('HealthComponent')),
        },
      );
    });

    test('reads are NOT included in interactsWith', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Component() int maxHealth = 100;
          @Event() void checkHealth() { checkSystem(); }

          @ReactiveSystem()
          void checkSystem() {
            if (health < maxHealth) {}
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(
            isNot(contains('Set<Type> get interactsWith')),
          ),
        },
      );
    });

    test('includes doc comment when description is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Event() void logout() { logoutSystem(); }

          @ReactiveSystem(description: "Handles logout")
          void logoutSystem() {}
        '''),
        outputs: {
          _outputKey: decodedMatches(contains('/// Handles logout')),
        },
      );
    });

    test('generates reactsIf getter when reactsIf is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) { applyAddHealth(amount); }

          bool applyAddHealthIf(int amount) {
            return health + amount <= 100;
          }

          @ReactiveSystem(reactsIf: applyAddHealthIf)
          void applyAddHealth(int amount) {
            health += amount;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('bool get reactsIf'),
            contains('getEntity<HealthComponent>().value'),
            contains('getEntity<AddHealthEvent>().data'),
          ])),
        },
      );
    });

    test('does not generate reactsIf getter when reactsIf is not provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Event() void logout() { logoutSystem(); }

          @ReactiveSystem()
          void logoutSystem() {}
        '''),
        outputs: {
          _outputKey: decodedMatches(isNot(contains('bool get reactsIf'))),
        },
      );
    });

    test('async private helpers preserve async modifier', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int loginProcess = 0;
          @Event() void login(int id) { loginSystem(id); }

          @ReactiveSystem()
          void loginSystem(int id) {
            _doLogin(id).ignore();
          }

          Future<void> _doLogin(int id) async {
            await Future.delayed(const Duration(seconds: 1));
            loginProcess = id;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(contains('Future<void> _doLogin(int id) async {')),
        },
      );
    });
  });
}
