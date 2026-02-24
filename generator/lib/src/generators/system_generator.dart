import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
import 'package:source_gen/source_gen.dart';

final class ReactiveSystemGenerator extends GeneratorForAnnotation<ReactiveSystemDefinition> {
  const ReactiveSystemGenerator() : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! TopLevelFunctionElement) {
      throw InvalidGenerationSourceError(
        '@ReactiveSystemDefinition can only be applied to top-level functions.',
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
    final customName = annotation.peek('name')?.stringValue;
    final description = annotation.peek('description')?.stringValue;

    final rawName = customName ?? _capitalize(funcName);
    final className = rawName.endsWith('ReactiveSystem') ? rawName : '${rawName}ReactiveSystem';

    final reactsToNames = _extractSetIds(astNode, 'reactsTo');
    final interactsWithNames = _extractSetIds(astNode, 'interactsWith');
    final reactsIfName = _extractFuncRef(astNode, 'reactsIf');

    final reactsToTypes = reactsToNames.map((n) => _resolveGeneratedType(n, unit)).toList();
    final interactsWithTypes = interactsWithNames.map((n) => _resolveGeneratedType(n, unit)).toList();

    final reactBody = _extractBody(astNode.functionExpression.body);
    final reactsIfBody = reactsIfName != null ? _extractNamedFuncBody(reactsIfName, unit) : null;

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ReactiveSystem {');

    buffer.writeln('  @override');
    buffer.writeln('  Set<Type> get reactsTo {');
    buffer.writeln('    return {${reactsToTypes.join(', ')}};');
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
      buffer.writeln('    return {${interactsWithTypes.join(', ')}};');
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

  String _resolveGeneratedType(String varName, CompilationUnit unit) {
    for (final decl in unit.declarations) {
      if (decl is TopLevelVariableDeclaration) {
        for (final v in decl.variables.variables) {
          if (v.name.lexeme == varName) {
            for (final ann in decl.metadata) {
              final name = ann.name.name.toLowerCase();
              final raw = _capitalize(varName);
              if (name.contains('component')) {
                return raw.endsWith('Component') ? raw : '${raw}Component';
              }
              if (name.contains('event')) {
                return raw.endsWith('Event') ? raw : '${raw}Event';
              }
            }
          }
        }
      }
    }
    return _capitalize(varName);
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
    return source;
  }

  String _capitalize(String s) {
    return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  }
}
