import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
import 'package:source_gen/source_gen.dart';

final class ECSReactiveSystemGenerator extends GeneratorForAnnotation<ECSReactiveSystemDefinition> {
  const ECSReactiveSystemGenerator() : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! TopLevelFunctionElement) {
      throw InvalidGenerationSourceError(
        '@ECSReactiveSystemDefinition can only be applied to top-level functions.',
        element: element,
      );
    }

    final astNode = await buildStep.resolver.astNodeFor(
      element.firstFragment,
      resolve: true,
    );

    if (astNode is! FunctionDeclaration) {
      throw InvalidGenerationSourceError(
        'Could not resolve AST for function.',
        element: element,
      );
    }

    final unit = astNode.root as CompilationUnit;
    final funcName = element.name!;
    final description = annotation.peek('description')?.stringValue;

    final raw = _capitalize(funcName);
    final className = raw.endsWith('ReactiveSystem') ? raw : '${raw}ReactiveSystem';
    final reactsToTypes = _extractSetIds(astNode, 'reactsTo').map((id) => _resolveEntityTypeName(id, unit)).toList();
    final interactsWithTypes = _extractSetIds(astNode, 'interactsWith').map((id) => _resolveEntityTypeName(id, unit)).toList();
    final reactsIfName = _extractFuncRef(astNode, 'reactsIf');

    final reactBody = _extractBody(astNode.functionExpression.body);
    final reactsIfBody = reactsIfName != null
        ? _extractNamedFuncBody(reactsIfName, unit)
            ?.split('\n')
            .map(_transform)
            .join('\n')
        : null;

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSReactiveSystem {');

    buffer.writeln('  @override');
    buffer.writeln('  Set<Type> get reactsTo {');
    buffer.writeln('    return const {${reactsToTypes.join(',\n')}};');
    buffer.writeln('  }');

    if (reactsIfBody != null) {
      buffer.writeln();
      buffer.writeln('  @override');
      buffer.writeln('  bool get reactsIf {');
      buffer.write(reactsIfBody);
      buffer.writeln('  }');
    }

    if (interactsWithTypes.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('  @override');
      buffer.writeln('  Set<Type> get interactsWith {');
      buffer.writeln('    return const {${interactsWithTypes.join(',\n')}};');
      buffer.writeln('  }');
    }

    // react method
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  void react() {');
    buffer.write(reactBody);
    buffer.writeln('  }');

    buffer.writeln('}');
    return buffer.toString();
  }

  List<String> _extractSetIds(FunctionDeclaration funcDecl, String param) {
    for (final ann in funcDecl.metadata) {
      for (final arg in ann.arguments?.arguments ?? <Expression>[]) {
        if (arg is NamedExpression && arg.name.label.name == param) {
          if (arg.expression is SetOrMapLiteral) {
            return (arg.expression as SetOrMapLiteral).elements.whereType<SimpleIdentifier>().map((id) => id.name).toList();
          }
        }
      }
    }
    return [];
  }

  String? _extractFuncRef(FunctionDeclaration funcDecl, String param) {
    for (final ann in funcDecl.metadata) {
      for (final arg in ann.arguments?.arguments ?? <Expression>[]) {
        if (arg is NamedExpression && arg.name.label.name == param) {
          if (arg.expression is SimpleIdentifier) {
            return (arg.expression as SimpleIdentifier).name;
          }
        }
      }
    }
    return null;
  }

  String _extractBody(FunctionBody body) {
    if (body is! BlockFunctionBody) return '';
    return _transformStatements(body.block.statements);
  }

  String? _extractNamedFuncBody(String name, CompilationUnit unit) {
    for (final decl in unit.declarations) {
      if (decl is FunctionDeclaration && decl.name.lexeme == name) {
        final body = decl.functionExpression.body;
        if (body is BlockFunctionBody) {
          return _transformStatements(body.block.statements);
        }
      }
    }
    return null;
  }

  String _transformStatements(NodeList<Statement> stmts) {
    final buffer = StringBuffer();
    for (final stmt in stmts) {
      buffer.writeln('    ${_transform(stmt.toSource())}');
    }
    return buffer.toString();
  }

  String _transform(String source) {
    source = source.replaceAllMapped(
      RegExp(r'system\.getComponent\((\w+)\)'),
      (m) => 'getEntity<${_capitalize(m.group(1)!)}Component>()',
    );
    source = source.replaceAllMapped(
      RegExp(r'system\.getDataEvent\((\w+)\)'),
      (m) => 'getEntity<${_capitalize(m.group(1)!)}Event>()',
    );
    source = source.replaceAllMapped(
      RegExp(r'system\.getEvent\((\w+)\)'),
      (m) => 'getEntity<${_capitalize(m.group(1)!)}Event>()',
    );
    source = source.replaceAllMapped(
      RegExp(r'system\.getDependency\((\w+)\)'),
      (m) => 'getEntity<${_capitalize(m.group(1)!)}Dependency>()',
    );
    return source;
  }

  /// Resolves the generated class name for a top-level variable identifier
  /// by inspecting its annotation and appending the appropriate suffix.
  String _resolveEntityTypeName(String varName, CompilationUnit unit) {
    final raw = _capitalize(varName);
    for (final decl in unit.declarations) {
      if (decl is TopLevelVariableDeclaration) {
        final hasVar = decl.variables.variables.any((v) => v.name.lexeme == varName);
        if (!hasVar) continue;
        for (final ann in decl.metadata) {
          final name = ann.name.name;
          if (name.contains('Component')) return '${raw}Component';
          if (name.contains('DataEvent')) return '${raw}Event';
          if (name.contains('Event')) return '${raw}Event';
          if (name.contains('Dependency')) return '${raw}Dependency';
        }
      }
    }
    return raw;
  }

  String _capitalize(String s) {
    return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  }
}
