import 'package:analyzer/dart/element/element.dart';

import '../helpers.dart';
import 'feature_model.dart';

sealed class EntityModel {
  final String name;
  late final String ecsType;
  final VariableElement element;

  FeatureModel? feature;

  EntityModel({
    required this.name,
    required this.element,
  });

  String generate();
}

final class ComponentModel extends EntityModel {
  final String? type;
  final String? value;

  ComponentModel({
    required super.name,
    required this.type,
    required this.value,
    required super.element,
  }) {
    final capitalized = capitalize(name);
    ecsType = capitalized.endsWith("Component") ? capitalized : "${capitalized}Component";
  }

  @override
  String generate() {
    final buffer = StringBuffer("final class $ecsType extends ECSComponent<$type> {\n");
    buffer.writeln('  $ecsType() : super($value);');
    buffer.write('}');
    return buffer.toString();
  }
}

final class EventModel extends EntityModel {
  EventModel({
    required super.name,
    required super.element,
  }) {
    final capitalized = capitalize(name);
    ecsType = capitalized.endsWith("Event") ? capitalized : "${capitalized}Event";
  }

  @override
  String generate() {
    return "final class $ecsType extends ECSEvent {}";
  }
}

final class DataEventModel extends EntityModel {
  final String? type;

  DataEventModel({
    required super.name,
    required this.type,
    required super.element,
  }) {
    final capitalized = capitalize(name);
    ecsType = capitalized.endsWith("Event") ? capitalized : "${capitalized}Event";
  }

  @override
  String generate() {
    return "final class $ecsType extends ECSDataEvent<$type> {}";
  }
}

final class DependencyModel extends EntityModel {
  final String? type;
  final String? value;

  DependencyModel({
    required super.name,
    required this.type,
    required this.value,
    required super.element,
  }) {
    final capitalized = capitalize(name);
    ecsType = capitalized.endsWith("Dependency") ? capitalized : "${capitalized}Dependency";
  }

  @override
  String generate() {
    final buffer = StringBuffer("final class $ecsType extends ECSDependency<$type> {\n");
    buffer.writeln('  $ecsType() : super($value);');
    buffer.write('}');
    return buffer.toString();
  }
}
