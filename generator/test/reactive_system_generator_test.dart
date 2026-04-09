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
  final class ReactiveSystem { final String? description; final Function? reactsTo; final Function? reactsIf; const ReactiveSystem({this.description, this.reactsTo, this.reactsIf}); }
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
    test('event reactsTo populates reactsTo set', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) {}

          List applyAddHealthReactsTo() {
            return [addHealth];
          }

          @ReactiveSystem(reactsTo: applyAddHealthReactsTo)
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
          @Event() void addHealth(int amount) {}

          List applyAddHealthReactsTo() {
            return [addHealth];
          }

          @ReactiveSystem(reactsTo: applyAddHealthReactsTo)
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
          @Event() void addHealth(int amount) {}

          List applyAddHealthReactsTo() {
            return [addHealth];
          }

          @ReactiveSystem(reactsTo: applyAddHealthReactsTo)
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
          @Event() void addHealth(int amount) {}

          List applyAddHealthReactsTo() {
            return [addHealth];
          }

          @ReactiveSystem(reactsTo: applyAddHealthReactsTo)
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
          @Event() void logout() {}

          List logoutSystemReactsTo() {
            return [logout];
          }

          @ReactiveSystem(reactsTo: logoutSystemReactsTo)
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
          @Event() void addHealth(int amount) {}

          List applyAddHealthReactsTo() {
            return [addHealth];
          }

          @ReactiveSystem(reactsTo: applyAddHealthReactsTo)
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
          @Event() void addHealth(int amount) {}

          List applyAddHealthReactsTo() {
            return [addHealth];
          }

          @ReactiveSystem(reactsTo: applyAddHealthReactsTo)
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
          @Event() void checkHealth() {}

          List checkSystemReactsTo() {
            return [checkHealth];
          }

          @ReactiveSystem(reactsTo: checkSystemReactsTo)
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
          @Event() void logout() {}

          List logoutSystemReactsTo() {
            return [logout];
          }

          @ReactiveSystem(description: "Handles logout", reactsTo: logoutSystemReactsTo)
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
          @Event() void addHealth(int amount) {}

          List applyAddHealthReactsTo() {
            return [addHealth];
          }

          bool applyAddHealthIf(int amount) {
            return health + amount <= 100;
          }

          @ReactiveSystem(reactsTo: applyAddHealthReactsTo, reactsIf: applyAddHealthIf)
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
          @Event() void logout() {}

          List logoutSystemReactsTo() {
            return [logout];
          }

          @ReactiveSystem(reactsTo: logoutSystemReactsTo)
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
          @Event() void login(int id) {}

          List loginSystemReactsTo() {
            return [login];
          }

          @ReactiveSystem(reactsTo: loginSystemReactsTo)
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

    test('supports multiple events in reactsTo', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) {}
          @Event() void healFull() {}

          List applyHealReactsTo() {
            return [addHealth, healFull];
          }

          @ReactiveSystem(reactsTo: applyHealReactsTo)
          void applyHeal(int amount) {
            health += amount;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('AddHealthEvent'),
            contains('HealFullEvent'),
          ])),
        },
      );
    });

    test('component in reactsTo populates reactsTo set', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;

          List onHealthChangedReactsTo() {
            return [health];
          }

          @ReactiveSystem(reactsTo: onHealthChangedReactsTo)
          void onHealthChanged() {}
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('Set<Type> get reactsTo'),
            contains('HealthComponent'),
          ])),
        },
      );
    });

    test('mixes events and components in reactsTo', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void requestSync() {}

          List syncHealthReactsTo() {
            return [requestSync, health];
          }

          @ReactiveSystem(reactsTo: syncHealthReactsTo)
          void syncHealth() {}
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('RequestSyncEvent'),
            contains('HealthComponent'),
          ])),
        },
      );
    });

    test('reactsTo function with arrow body works', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) {}

          List applyAddHealthReactsTo() => [addHealth];

          @ReactiveSystem(reactsTo: applyAddHealthReactsTo)
          void applyAddHealth(int amount) {
            health += amount;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(contains('AddHealthEvent')),
        },
      );
    });

    test('handles try-catch in react body', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int counter = 0;
          @Event() void inc() {}

          List incReactsTo() { return [inc]; }

          @ReactiveSystem(reactsTo: incReactsTo)
          void handleInc() {
            try {
              counter += 1;
            } catch (e) {
              counter = 0;
            }
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('try {'),
            contains('getEntity<CounterComponent>().value'),
          ])),
        },
      );
    });

    test('handles nested blocks and try-catch', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int counter = 0;
          @Event() void inc() {}

          List incReactsTo() => [inc];

          @ReactiveSystem(reactsTo: incReactsTo)
          void handleIncNested() {
            if (counter < 10) {
              try {
                counter += 2;
              } catch (e) {
                counter -= 1;
              }
            } else {
              counter = 0;
            }
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('getEntity<CounterComponent>().value'),
            contains('try {'),
            contains('if ('),
          ])),
        },
      );
    });
  });
}
