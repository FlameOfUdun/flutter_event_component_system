import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
import '_helpers.dart';

final class ECSComponentGenerator extends GeneratorForAnnotation<ECSComponentDefinition> {
  const ECSComponentGenerator() : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! TopLevelVariableElement) {
      throw InvalidGenerationSourceError(
        '@ECSComponentDefinition can only be applied to top-level variables.',
        element: element,
      );
    }

    if (!element.isConst) {
      throw InvalidGenerationSourceError(
        '@ECSComponentDefinition variable must be const to infer a default value.',
        element: element,
      );
    }

    final varName = element.name!;
    final type = element.type.getDisplayString();
    final description = annotation.peek('description')?.stringValue;

    final className = '${capitalize(varName)}Component';
    final defaultValue = extractDefault(element);

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSComponent<$type> {');
    buffer.writeln('  $className([super.value = $defaultValue]);');
    buffer.writeln('}');
    return buffer.toString();
  }
}

final class ECSEventGenerator extends GeneratorForAnnotation<ECSEventDefinition> {
  const ECSEventGenerator() : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! TopLevelVariableElement) {
      throw InvalidGenerationSourceError(
        '@ECSEventDefinition can only be applied to top-level variables.',
        element: element,
      );
    }

    final varName = element.name!;
    final description = annotation.peek('description')?.stringValue;

    final rawName = capitalize(varName);
    final className = rawName.endsWith('Event') ? rawName : '${rawName}Event';

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSEvent {}');
    return buffer.toString();
  }
}

final class ECSDataEventGenerator extends GeneratorForAnnotation<ECSDataEventDefinition> {
  const ECSDataEventGenerator() : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! TopLevelVariableElement) {
      throw InvalidGenerationSourceError(
        '@ECSDataEventDefinition can only be applied to top-level variables.',
        element: element,
      );
    }

    if (!element.isConst) {
      throw InvalidGenerationSourceError(
        '@ECSDataEventDefinition variable must be const to infer a default value.',
        element: element,
      );
    }

    final varName = element.name!;
    final type = element.type.getDisplayString();
    final description = annotation.peek('description')?.stringValue;

    final rawName = capitalize(varName);
    final className = rawName.endsWith('Event') ? rawName : '${rawName}Event';
    final defaultValue = extractDefault(element);

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSDataEvent<$type> {');
    buffer.writeln('  @override');
    buffer.writeln('  void trigger([$type data = $defaultValue]) => super.trigger(data);');
    buffer.writeln('}');
    return buffer.toString();
  }
}

final class ECSDependencyGenerator extends GeneratorForAnnotation<ECSDependencyDefinition> {
  const ECSDependencyGenerator() : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! TopLevelVariableElement) {
      throw InvalidGenerationSourceError(
        '@ECSDependencyDefinition can only be applied to top-level variables.',
        element: element,
      );
    }

    if (!element.isConst) {
      throw InvalidGenerationSourceError(
        '@ECSDependencyDefinition variable must be const to infer a default value.',
        element: element,
      );
    }

    final varName = element.name!;
    final type = element.type.getDisplayString();
    final description = annotation.peek('description')?.stringValue;

    final className = '${capitalize(varName)}Dependency';
    final defaultValue = extractDefault(element);

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSDependency<$type> {');
    buffer.writeln('  $className([super.value = $defaultValue]);');
    buffer.writeln('}');
    return buffer.toString();
  }
}
