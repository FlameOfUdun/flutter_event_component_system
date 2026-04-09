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
  final class CleanupSystem { final String? description; final Function? cleansIf; const CleanupSystem({this.description, this.cleansIf}); }
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
  group('CleanupSystemGenerator', () {
    test('generates cleanup system class', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int loginProcess = 0;

          @CleanupSystem()
          void cleanupLogin() {
            loginProcess = 0;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class CleanupLoginCleanupSystem extends ECSCleanupSystem'),
            contains('void cleanup()'),
            contains('getEntity<LoginProcessComponent>().value = 0'),
          ])),
        },
      );
    });

    test('generates cleansIf getter when cleansIf is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int loginProcess = 0;

          bool shouldCleanupLogin() {
            return loginProcess != 0;
          }

          @CleanupSystem(cleansIf: shouldCleanupLogin)
          void cleanupLogin() {
            loginProcess = 0;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('bool get cleansIf'),
            contains('getEntity<LoginProcessComponent>().value'),
          ])),
        },
      );
    });

    test('does not generate cleansIf getter when cleansIf is not provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int loginProcess = 0;

          @CleanupSystem()
          void cleanupLogin() {
            loginProcess = 0;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(isNot(contains('bool get cleansIf'))),
        },
      );
    });
  });
}
