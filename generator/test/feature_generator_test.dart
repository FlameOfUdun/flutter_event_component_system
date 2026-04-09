import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:flutter_event_component_system_generator/flutter_event_component_system_generator.dart';

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

void main() {
  group('FeatureGenerator', () {
    test('derives class name from snake_case filename', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        {
          _annotationAsset: _annotationSource,
          'flutter_event_component_system_generator|lib/timer_feature.dart': '''
            import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
            part 'timer_feature.ecs.g.dart';
            @Component() int timerValue = 0;
          ''',
        },
        outputs: {
          'flutter_event_component_system_generator|lib/timer_feature.ecs.g.dart':
              decodedMatches(contains('final class TimerFeature extends ECSFeature')),
        },
      );
    });

    test('registers all components as entities', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        {
          _annotationAsset: _annotationSource,
          'flutter_event_component_system_generator|lib/timer_feature.dart': '''
            import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
            part 'timer_feature.ecs.g.dart';
            @Component() int timerValue = 0;
            @Component() int timerState = 0;
          ''',
        },
        outputs: {
          'flutter_event_component_system_generator|lib/timer_feature.ecs.g.dart':
              decodedMatches(allOf([
            contains('addEntity(TimerValueComponent())'),
            contains('addEntity(TimerStateComponent())'),
          ])),
        },
      );
    });

    test('registers events as entities', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        {
          _annotationAsset: _annotationSource,
          'flutter_event_component_system_generator|lib/timer_feature.dart': '''
            import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
            part 'timer_feature.ecs.g.dart';
            @Event() void timerStart() {}
          ''',
        },
        outputs: {
          'flutter_event_component_system_generator|lib/timer_feature.ecs.g.dart':
              decodedMatches(contains('addEntity(TimerStartEvent())')),
        },
      );
    });

    test('registers reactive systems', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        {
          _annotationAsset: _annotationSource,
          'flutter_event_component_system_generator|lib/timer_feature.dart': '''
            import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
            part 'timer_feature.ecs.g.dart';
            @Event() void timerStart() { startTimerReactive(); }
            @ReactiveSystem()
            void startTimerReactive() {}
          ''',
        },
        outputs: {
          'flutter_event_component_system_generator|lib/timer_feature.ecs.g.dart':
              decodedMatches(contains('addSystem(StartTimerReactiveReactiveSystem())')),
        },
      );
    });

    test('registers initialize, teardown, cleanup, and execute systems', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        {
          _annotationAsset: _annotationSource,
          'flutter_event_component_system_generator|lib/timer_feature.dart': '''
            import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
            part 'timer_feature.ecs.g.dart';
            @InitializeSystem() void setupTimer() {}
            @TeardownSystem() void teardownTimer() {}
            @CleanupSystem() void cleanupTimer() {}
            @ExecuteSystem() void tickTimer(Duration elapsed) {}
          ''',
        },
        outputs: {
          'flutter_event_component_system_generator|lib/timer_feature.ecs.g.dart':
              decodedMatches(allOf([
            contains('addSystem(SetupTimerInitializeSystem())'),
            contains('addSystem(TeardownTimerTeardownSystem())'),
            contains('addSystem(CleanupTimerCleanupSystem())'),
            contains('addSystem(TickTimerExecuteSystem())'),
          ])),
        },
      );
    });

    test('derives PascalCase name from multi-word snake_case filename', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        {
          _annotationAsset: _annotationSource,
          'flutter_event_component_system_generator|lib/user_auth_feature.dart': '''
            import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
            part 'user_auth_feature.ecs.g.dart';
            @Component() int authState = 0;
          ''',
        },
        outputs: {
          'flutter_event_component_system_generator|lib/user_auth_feature.ecs.g.dart':
              decodedMatches(contains('final class UserAuthFeature extends ECSFeature')),
        },
      );
    });

    test('returns null when no annotated elements present', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        {
          _annotationAsset: _annotationSource,
          'flutter_event_component_system_generator|lib/empty_feature.dart': '''
            import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
            part 'empty_feature.ecs.g.dart';
            // No annotated elements
            int plainVariable = 0;
          ''',
        },
        outputs: {},  // no output expected
      );
    });
  });
}
