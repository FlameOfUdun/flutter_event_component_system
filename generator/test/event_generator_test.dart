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
  final class ReactiveSystem { final String? description; const ReactiveSystem({this.description}); }
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
  group('EventGenerator', () {
    test('generates no-data event from zero-parameter void function', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@Event() void logout() {}'),
        outputs: {
          _outputKey: decodedMatches(contains(
            'final class LogoutEvent extends ECSEvent {}',
          )),
        },
      );
    });

    test('generates data event from one-parameter void function', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          class LoginCredentials {}
          @Event() void login(LoginCredentials credentials) {}
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class LoginEvent extends ECSDataEvent<LoginCredentials> {}'),
            isNot(contains('void trigger')),
          ])),
        },
      );
    });

    test('generates data event with int type', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@Event() void addHealth(int amount) {}'),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class AddHealthEvent extends ECSDataEvent<int> {}'),
            isNot(contains('void trigger')),
          ])),
        },
      );
    });

    test('includes doc comment when description is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@Event(description: "User logged out") void logout() {}'),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('/// User logged out'),
            contains('final class LogoutEvent'),
          ])),
        },
      );
    });

    test('throws for multi-parameter event function', () async {
      final logs = <String>[];
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@Event() void login(String user, String pass) {}'),
        onLog: (r) => logs.add(r.message),
      );
      expect(
        logs.any((m) => m.contains('zero or one parameter')),
        isTrue,
        reason: 'Expected build error for multi-parameter event',
      );
    });
  });
}
