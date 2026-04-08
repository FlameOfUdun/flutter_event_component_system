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
  class ECSExecuteSystemDefinition {
    final String? description;
    final bool Function(dynamic)? executesIf;
    const ECSExecuteSystemDefinition({this.description, this.executesIf});
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
  group('ExecuteSystemGenerator', () {
    test('generates class extending ECSExecuteSystem', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @ECSComponentDefinition() const int timerMs = 0;
          @ECSExecuteSystemDefinition()
          void tickTimer(ECSSystemReference system, Duration elapsed) {
            system.getComponent(timerMs);
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class TickTimerExecuteSystem extends ECSExecuteSystem'),
            contains('void execute(Duration elapsed)'),
            contains('getEntity<TimerMsComponent>()'),
          ])),
        },
      );
    });

    test('appends ExecuteSystem suffix to class name', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @ECSExecuteSystemDefinition()
          void tick(ECSSystemReference system, Duration elapsed) {}
        '''),
        outputs: {
          _outputKey: decodedMatches(
            contains('final class TickExecuteSystem extends ECSExecuteSystem'),
          ),
        },
      );
    });

    test('generates executesIf getter when executesIf is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @ECSComponentDefinition() const bool isRunning = false;
          bool shouldTick(ECSSystemReference system) {
            return system.getComponent(isRunning).value;
          }
          @ECSExecuteSystemDefinition(executesIf: shouldTick)
          void tickTimer(ECSSystemReference system, Duration elapsed) {}
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('bool get executesIf'),
            contains('getEntity<IsRunningComponent>()'),
          ])),
        },
      );
    });

    test('elapsed parameter is available in execute body', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @ECSExecuteSystemDefinition()
          void tickTimer(ECSSystemReference system, Duration elapsed) {
            final ms = elapsed.inMilliseconds;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(contains('elapsed.inMilliseconds')),
        },
      );
    });

    test('includes doc comment when description provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @ECSExecuteSystemDefinition(description: "Ticks the timer")
          void tickTimer(ECSSystemReference system, Duration elapsed) {}
        '''),
        outputs: {
          _outputKey: decodedMatches(contains('/// Ticks the timer')),
        },
      );
    });
  });
}
