import 'package:build/build.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
import 'package:source_gen/source_gen.dart';
import '_helpers.dart';

final class FeatureGenerator extends Generator {
  const FeatureGenerator();

  static const _componentChecker = TypeChecker.typeNamed(
    Component,
    inPackage: 'flutter_event_component_system_annotations',
  );
  static const _eventChecker = TypeChecker.typeNamed(
    Event,
    inPackage: 'flutter_event_component_system_annotations',
  );
  static const _dependencyChecker = TypeChecker.typeNamed(
    Dependency,
    inPackage: 'flutter_event_component_system_annotations',
  );
  static const _reactiveSystemChecker = TypeChecker.typeNamed(
    ReactiveSystem,
    inPackage: 'flutter_event_component_system_annotations',
  );
  static const _initializeSystemChecker = TypeChecker.typeNamed(
    InitializeSystem,
    inPackage: 'flutter_event_component_system_annotations',
  );
  static const _teardownSystemChecker = TypeChecker.typeNamed(
    TeardownSystem,
    inPackage: 'flutter_event_component_system_annotations',
  );
  static const _cleanupSystemChecker = TypeChecker.typeNamed(
    CleanupSystem,
    inPackage: 'flutter_event_component_system_annotations',
  );
  static const _executeSystemChecker = TypeChecker.typeNamed(
    ExecuteSystem,
    inPackage: 'flutter_event_component_system_annotations',
  );

  @override
  String? generate(LibraryReader library, BuildStep buildStep) {
    final components = library.annotatedWith(_componentChecker).toList();
    final events = library.annotatedWith(_eventChecker).toList();
    final dependencies = library.annotatedWith(_dependencyChecker).toList();
    final reactiveSystems = library.annotatedWith(_reactiveSystemChecker).toList();
    final initializeSystems = library.annotatedWith(_initializeSystemChecker).toList();
    final teardownSystems = library.annotatedWith(_teardownSystemChecker).toList();
    final cleanupSystems = library.annotatedWith(_cleanupSystemChecker).toList();
    final executeSystems = library.annotatedWith(_executeSystemChecker).toList();

    final hasAnything = components.isNotEmpty ||
        events.isNotEmpty ||
        dependencies.isNotEmpty ||
        reactiveSystems.isNotEmpty ||
        initializeSystems.isNotEmpty ||
        teardownSystems.isNotEmpty ||
        cleanupSystems.isNotEmpty ||
        executeSystems.isNotEmpty;

    if (!hasAnything) return null;

    // Derive Feature class name from the source file path.
    // e.g. "lib/timer_feature.dart" → "TimerFeature"
    final path = buildStep.inputId.path; // e.g. "lib/timer_feature.dart"
    final filename = path.split('/').last; // "timer_feature.dart"
    final stem = filename.replaceAll('.dart', ''); // "timer_feature"
    final baseName = toPascalCase(stem); // "TimerFeature"
    final className =
        baseName.endsWith('Feature') ? baseName : '${baseName}Feature';

    final buffer = StringBuffer();
    buffer.writeln('final class $className extends ECSFeature {');
    buffer.writeln('  $className() {');

    for (final a in components) {
      final raw = toPascalCase(a.element.name!);
      final name = raw.endsWith('Component') ? raw : '${raw}Component';
      buffer.writeln('    addEntity($name());');
    }
    for (final a in events) {
      final raw = toPascalCase(a.element.name!);
      final name = raw.endsWith('Event') ? raw : '${raw}Event';
      buffer.writeln('    addEntity($name());');
    }
    for (final a in dependencies) {
      final raw = toPascalCase(a.element.name!);
      final name = raw.endsWith('Dependency') ? raw : '${raw}Dependency';
      buffer.writeln('    addEntity($name());');
    }
    for (final a in reactiveSystems) {
      final raw = toPascalCase(a.element.name!);
      final name = raw.endsWith('ReactiveSystem') ? raw : '${raw}ReactiveSystem';
      buffer.writeln('    addSystem($name());');
    }
    for (final a in initializeSystems) {
      final raw = toPascalCase(a.element.name!);
      final name = raw.endsWith('InitializeSystem') ? raw : '${raw}InitializeSystem';
      buffer.writeln('    addSystem($name());');
    }
    for (final a in teardownSystems) {
      final raw = toPascalCase(a.element.name!);
      final name = raw.endsWith('TeardownSystem') ? raw : '${raw}TeardownSystem';
      buffer.writeln('    addSystem($name());');
    }
    for (final a in cleanupSystems) {
      final raw = toPascalCase(a.element.name!);
      final name = raw.endsWith('CleanupSystem') ? raw : '${raw}CleanupSystem';
      buffer.writeln('    addSystem($name());');
    }
    for (final a in executeSystems) {
      final raw = toPascalCase(a.element.name!);
      final name = raw.endsWith('ExecuteSystem') ? raw : '${raw}ExecuteSystem';
      buffer.writeln('    addSystem($name());');
    }

    buffer.writeln('  }');
    buffer.writeln('}');
    return buffer.toString();
  }
}
