import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
import 'package:source_gen/source_gen.dart';
import '_helpers.dart';

final class ComponentGenerator extends GeneratorForAnnotation<Component> {
  const ComponentGenerator()
      : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! TopLevelVariableElement) {
      throw InvalidGenerationSourceError(
        '@Component can only be applied to top-level variables.',
        element: element,
      );
    }

    final astNode = await buildStep.resolver.astNodeFor(
      element.firstFragment,
      resolve: true,
    );

    final varDecl = _findVarDecl(astNode, element.name!);
    final defaultValue = extractInitializerSource(varDecl, element);
    final varName = element.name!;
    final type = element.type.getDisplayString();
    final description = annotation.peek('description')?.stringValue;
    final className = '${capitalize(varName)}Component';

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSComponent<$type> {');
    buffer.writeln('  $className([super.value = $defaultValue]);');
    buffer.writeln('}');
    return buffer.toString();
  }
}

final class DependencyGenerator extends GeneratorForAnnotation<Dependency> {
  const DependencyGenerator()
      : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! TopLevelVariableElement) {
      throw InvalidGenerationSourceError(
        '@Dependency can only be applied to top-level variables.',
        element: element,
      );
    }

    final astNode = await buildStep.resolver.astNodeFor(
      element.firstFragment,
      resolve: true,
    );

    final varDecl = _findVarDecl(astNode, element.name!);
    final defaultValue = extractInitializerSource(varDecl, element);
    final varName = element.name!;
    final type = element.type.getDisplayString();
    final description = annotation.peek('description')?.stringValue;
    final className = '${capitalize(varName)}Dependency';

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSDependency<$type> {');
    buffer.writeln('  $className([super.value = $defaultValue]);');
    buffer.writeln('}');
    return buffer.toString();
  }
}

final class EventGenerator extends GeneratorForAnnotation<Event> {
  const EventGenerator()
      : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! TopLevelFunctionElement) {
      throw InvalidGenerationSourceError(
        '@Event can only be applied to top-level void functions.',
        element: element,
      );
    }

    final params = element.formalParameters;
    if (params.length > 1) {
      throw InvalidGenerationSourceError(
        '@Event functions must have zero or one parameter. '
        'Multi-parameter events are not supported.',
        element: element,
      );
    }

    final funcName = element.name!;
    final description = annotation.peek('description')?.stringValue;
    final raw = capitalize(funcName);
    final className = raw.endsWith('Event') ? raw : '${raw}Event';

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');

    if (params.isEmpty) {
      buffer.writeln('final class $className extends ECSEvent {}');
    } else {
      final param = params.first;
      final type = param.type.getDisplayString();
      buffer.writeln('final class $className extends ECSDataEvent<$type> {');
      buffer.writeln('  @override');
      final primitiveDefault = _primitiveDefault(type);
      if (primitiveDefault != null) {
        buffer.writeln(
            '  void trigger([$type data = $primitiveDefault]) => super.trigger(data);');
      } else {
        buffer.writeln('  void trigger($type data) => super.trigger(data);');
      }
      buffer.writeln('}');
    }

    return buffer.toString();
  }

  String? _primitiveDefault(String typeName) {
    return switch (typeName) {
      'int' => '0',
      'double' => '0.0',
      'String' => '""',
      'bool' => 'false',
      _ => null,
    };
  }
}

/// Finds the [VariableDeclaration] AST node for [varName].
/// [astNode] is the result of [resolver.astNodeFor] for a [TopLevelVariableElement].
VariableDeclaration _findVarDecl(AstNode? astNode, String varName) {
  if (astNode is VariableDeclaration && astNode.name.lexeme == varName) {
    return astNode;
  }
  if (astNode is TopLevelVariableDeclaration) {
    for (final v in astNode.variables.variables) {
      if (v.name.lexeme == varName) return v;
    }
  }
  throw StateError('Could not find VariableDeclaration for $varName');
}
