import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
import 'package:source_gen/source_gen.dart';
import '_helpers.dart';

// TypeChecker constants for system generators.
const _componentChecker = TypeChecker.typeNamed(
  Component,
  inPackage: 'flutter_event_component_system_annotations',
);
const _eventChecker = TypeChecker.typeNamed(
  Event,
  inPackage: 'flutter_event_component_system_annotations',
);
const _dependencyChecker = TypeChecker.typeNamed(
  Dependency,
  inPackage: 'flutter_event_component_system_annotations',
);

DslContext buildDslContext(LibraryReader library) {
  final components = <String, String>{};
  final events = <String, String>{};
  final dependencies = <String, String>{};
  for (final a in library.annotatedWith(_componentChecker)) {
    final name = a.element.name;
    if (name != null) components[name] = '${capitalize(name)}Component';
  }
  for (final a in library.annotatedWith(_eventChecker)) {
    final name = a.element.name;
    if (name != null) events[name] = '${capitalize(name)}Event';
  }
  for (final a in library.annotatedWith(_dependencyChecker)) {
    final name = a.element.name;
    if (name != null) dependencies[name] = '${capitalize(name)}Dependency';
  }
  return DslContext(components: components, events: events, dependencies: dependencies);
}

final class ReactiveSystemGenerator extends GeneratorForAnnotation<ReactiveSystem> {
  const ReactiveSystemGenerator()
      : super(inPackage: 'flutter_event_component_system_annotations');
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async =>
      '';
}

final class InitializeSystemGenerator extends GeneratorForAnnotation<InitializeSystem> {
  const InitializeSystemGenerator()
      : super(inPackage: 'flutter_event_component_system_annotations');
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async =>
      '';
}

final class TeardownSystemGenerator extends GeneratorForAnnotation<TeardownSystem> {
  const TeardownSystemGenerator()
      : super(inPackage: 'flutter_event_component_system_annotations');
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async =>
      '';
}

final class CleanupSystemGenerator extends GeneratorForAnnotation<CleanupSystem> {
  const CleanupSystemGenerator()
      : super(inPackage: 'flutter_event_component_system_annotations');
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async =>
      '';
}

final class ExecuteSystemGenerator extends GeneratorForAnnotation<ExecuteSystem> {
  const ExecuteSystemGenerator()
      : super(inPackage: 'flutter_event_component_system_annotations');
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async =>
      '';
}
