import 'package:analyzer/dart/element/element.dart';

import '../helpers.dart';
import 'entity_model.dart';
import 'manager_model.dart';
import 'system_model.dart';

final class FeatureModel {
  final String name;
  late final String ecsType;
  final Map<VariableElement, EntityModel> entities = {};
  final Set<SystemModel> systems = {};
  final VariableElement element;

  ManagerModel? manager;

  FeatureModel({
    required this.name,
    required this.element,
  }) {
    final capitalized = capitalize(name);
    ecsType = capitalized.endsWith("Feature") ? capitalized : "${capitalized}Feature";
  }

  EntityModel? getEntity(VariableElement element) {
    final direct = entities[element];
    if (direct != null) return direct;

    final path = element.firstFragment.libraryFragment?.source.fullName ?? '';
    final name = element.name ?? '';
    if (path.isEmpty || name.isEmpty) return null;

    for (final entry in entities.entries) {
      final k = entry.key;
      if (k.name == name && k.firstFragment.libraryFragment?.source.fullName == path) {
        return entry.value;
      }
    }

    return null;
  }

  void addEntity(EntityModel entity) {
    entities[entity.element] = entity;
    entity.feature = this;
  }

  void addSystem(SystemModel system) {
    systems.add(system);
    system.feature = this;
  }

  String generate() {
    final buffer = StringBuffer();

    final components = entities.values.whereType<ComponentModel>();
    for (final component in components) {
      buffer.writeln(component.generate());
      buffer.writeln();
    }

    final events = entities.values.whereType<EventModel>();
    for (final event in events) {
      buffer.writeln(event.generate());
      buffer.writeln();
    }

    final dataEvents = entities.values.whereType<DataEventModel>();
    for (final event in dataEvents) {
      buffer.writeln(event.generate());
      buffer.writeln();
    }

    final dependencies = entities.values.whereType<DependencyModel>();
    for (final dependency in dependencies) {
      buffer.writeln(dependency.generate());
      buffer.writeln();
    }

    for (final system in systems) {
      buffer.writeln(system.generate());
      buffer.writeln();
    }

    buffer.writeln('final class $ecsType extends ECSFeature {');
    buffer.writeln('  $ecsType() {');
    for (final component in components) {
      buffer.writeln('    addEntity(${component.ecsType}());');
    }
    for (final event in events) {
      buffer.writeln('    addEntity(${event.ecsType}());');
    }
    for (final event in dataEvents) {
      buffer.writeln('    addEntity(${event.ecsType}());');
    }
    for (final dependency in dependencies) {
      buffer.writeln('    addEntity(${dependency.ecsType}());');
    }
    for (final system in systems) {
      buffer.writeln('    addSystem(${system.ecsType}());');
    }
    buffer.writeln('  }');
    buffer.write("}");

    return buffer.toString();
  }
}
