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
  final class ExecuteSystem { final String? description; final Function? executesIf; const ExecuteSystem({this.description, this.executesIf}); }
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
  group('ExecuteSystemGenerator', () {
    test('generates execute system class with elapsed parameter', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int timerValue = 0;

          @ExecuteSystem()
          void updateTimer(Duration elapsed) {
            timerValue += elapsed.inMilliseconds;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class UpdateTimerExecuteSystem extends ECSExecuteSystem'),
            contains('void execute(Duration elapsed)'),
            contains('getEntity<TimerValueComponent>().value += elapsed.inMilliseconds'),
          ])),
        },
      );
    });

    test('reads are not included in interactsWith', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int timerState = 0;
          @Component() int timerValue = 0;

          @ExecuteSystem()
          void updateTimer(Duration elapsed) {
            if (timerState != 0) return;
            timerValue += elapsed.inMilliseconds;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('TimerValueComponent'),
            // TimerStateComponent is only read (not written), so it must not
            // appear in the interactsWith getter.
            isNot(contains('return const {TimerStateComponent')),
            isNot(contains(', TimerStateComponent')),
          ])),
        },
      );
    });

    test('generates executesIf getter when executesIf is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int timerValue = 0;

          bool shouldUpdateTimer(Duration elapsed) {
            return timerValue < 1000;
          }

          @ExecuteSystem(executesIf: shouldUpdateTimer)
          void updateTimer(Duration elapsed) {
            timerValue += elapsed.inMilliseconds;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('bool get executesIf'),
            contains('getEntity<TimerValueComponent>().value'),
            contains('elapsed'),
          ])),
        },
      );
    });

    test('does not generate executesIf getter when executesIf is not provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int timerValue = 0;

          @ExecuteSystem()
          void updateTimer(Duration elapsed) {
            timerValue += elapsed.inMilliseconds;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(isNot(contains('bool get executesIf'))),
        },
      );
    });
  });
}
