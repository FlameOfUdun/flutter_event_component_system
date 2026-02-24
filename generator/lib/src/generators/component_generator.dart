import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';

final class ComponentGenerator extends GeneratorForAnnotation<ComponentDefinition> {
  const ComponentGenerator() : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! TopLevelVariableElement) {
      throw InvalidGenerationSourceError(
        '@ComponentDefinition can only be applied to top-level variables.',
        element: element,
      );
    }

    if (!element.isConst) {
      throw InvalidGenerationSourceError(
        '@ComponentDefinition variable must be const to infer a default value.',
        element: element,
      );
    }

    final varName = element.name!;
    final type = element.type.getDisplayString();
    final description = annotation.peek('description')?.stringValue;

    final className = '${_capitalize(varName)}Component';
    final defaultValue = _extractDefault(element);

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSComponent<$type> {');
    buffer.writeln('  $className([super.value = $defaultValue]);');
    buffer.writeln('}');
    return buffer.toString();
  }

  String _capitalize(String s) {
    return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  }

  String _extractDefault(TopLevelVariableElement element) {
    final constant = element.computeConstantValue()!;
    final type = element.type;
    if (type.isDartCoreString) return '"${constant.toStringValue() ?? ''}"';
    if (type.isDartCoreInt) return '${constant.toIntValue() ?? 0}';
    if (type.isDartCoreDouble) return '${constant.toDoubleValue() ?? 0.0}';
    if (type.isDartCoreBool) return '${constant.toBoolValue() ?? false}';
    return 'null';
  }
}
