import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
import 'package:source_gen/source_gen.dart';

final class EventGenerator extends GeneratorForAnnotation<EventDefinition> {
  const EventGenerator() : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! TopLevelVariableElement) {
      throw InvalidGenerationSourceError(
        '@EventDefinition can only be applied to top-level variables.',
        element: element,
      );
    }

    final varName = element.name!;
    final customName = annotation.peek('name')?.stringValue;
    final description = annotation.peek('description')?.stringValue;

    final rawName = customName ?? _capitalize(varName);
    final className = rawName.endsWith('Event') ? rawName : '${rawName}Event';

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSEvent {}');
    return buffer.toString();
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

final class DataEventGenerator extends GeneratorForAnnotation<DataEventDefinition> {
  const DataEventGenerator() : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! TopLevelVariableElement) {
      throw InvalidGenerationSourceError(
        '@DataEventDefinition can only be applied to top-level variables.',
        element: element,
      );
    }

    if (!element.isConst) {
      throw InvalidGenerationSourceError(
        '@DataEventDefinition variable must be const to infer a default value.',
        element: element,
      );
    }

    final varName = element.name!;
    final type = element.type.getDisplayString();
    final customName = annotation.peek('name')?.stringValue;
    final description = annotation.peek('description')?.stringValue;

    final rawName = customName ?? _capitalize(varName);
    final className = rawName.endsWith('Event') ? rawName : '${rawName}Event';
    final defaultValue = _extractDefault(element);

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSDataEvent<$type> {');
    buffer.writeln('  @override');
    buffer.writeln('  void trigger([$type data = $defaultValue]) => super.trigger(data);');
    buffer.writeln('}');
    return buffer.toString();
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _extractDefault(TopLevelVariableElement element) {
    final constant = element.computeConstantValue()!;
    final t = element.type;
    if (t.isDartCoreString) return '"${constant.toStringValue() ?? ''}"';
    if (t.isDartCoreInt) return '${constant.toIntValue() ?? 0}';
    if (t.isDartCoreDouble) return '${constant.toDoubleValue() ?? 0.0}';
    if (t.isDartCoreBool) return '${constant.toBoolValue() ?? false}';
    return 'null';
  }
}
