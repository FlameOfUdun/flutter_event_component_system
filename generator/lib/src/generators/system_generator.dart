import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
import 'package:source_gen/source_gen.dart';
import '_helpers.dart';

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

    final raw = capitalize(funcName);
    final className = raw.endsWith('ReactiveSystem') ? raw : '${raw}ReactiveSystem';
    final reactsToTypes = _extractSetEntityClassNames(astNode, 'reactsTo', unit);
    final interactsWithTypes = _extractSetEntityClassNames(astNode, 'interactsWith', unit);
    final reactsIfName = extractFuncRef(astNode, 'reactsIf');

    final reactBody = extractBlockBody(astNode.functionExpression.body, element);
    final reactsIfBody = reactsIfName != null
        ? extractNamedFuncBody(reactsIfName, unit)
            ?.split('\n')
            .map(transformSource)
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

    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  void react() {');
    buffer.write(reactBody);
    buffer.writeln('  }');

    buffer.writeln('}');
    return buffer.toString();
  }

  List<String> _extractSetEntityClassNames(FunctionDeclaration funcDecl, String param, CompilationUnit unit) {
    for (final ann in funcDecl.metadata) {
      for (final arg in ann.arguments?.arguments ?? <Expression>[]) {
        if (arg is NamedExpression && arg.name.label.name == param) {
          if (arg.expression is SetOrMapLiteral) {
            return (arg.expression as SetOrMapLiteral)
                .elements
                .whereType<SimpleIdentifier>()
                .map((id) => _resolveEntityClassNameFromId(id, unit))
                .toList();
          }
        }
      }
    }
    return [];
  }

  String _resolveEntityClassNameFromId(SimpleIdentifier id, CompilationUnit unit) {
    return _resolveEntityTypeName(id.name, unit);
  }

  String _resolveEntityTypeName(String varName, CompilationUnit unit) {
    final raw = capitalize(varName);
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
}

final class ECSInitializeSystemGenerator extends GeneratorForAnnotation<ECSInitializeSystemDefinition> {
  const ECSInitializeSystemGenerator() : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! TopLevelFunctionElement) {
      throw InvalidGenerationSourceError(
        '@ECSInitializeSystemDefinition can only be applied to top-level functions.',
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

    final funcName = element.name!;
    final description = annotation.peek('description')?.stringValue;
    final raw = capitalize(funcName);
    final className = raw.endsWith('InitializeSystem') ? raw : '${raw}InitializeSystem';
    final body = extractBlockBody(astNode.functionExpression.body, element);

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSInitializeSystem {');
    buffer.writeln('  @override');
    buffer.writeln('  void initialize() {');
    buffer.write(body);
    buffer.writeln('  }');
    buffer.writeln('}');
    return buffer.toString();
  }
}

final class ECSTeardownSystemGenerator extends GeneratorForAnnotation<ECSTeardownSystemDefinition> {
  const ECSTeardownSystemGenerator() : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! TopLevelFunctionElement) {
      throw InvalidGenerationSourceError(
        '@ECSTeardownSystemDefinition can only be applied to top-level functions.',
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

    final funcName = element.name!;
    final description = annotation.peek('description')?.stringValue;
    final raw = capitalize(funcName);
    final className = raw.endsWith('TeardownSystem') ? raw : '${raw}TeardownSystem';
    final body = _extractBody(astNode.functionExpression.body, element);

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSTeardownSystem {');
    buffer.writeln('  @override');
    buffer.writeln('  void teardown() {');
    buffer.write(body);
    buffer.writeln('  }');
    buffer.writeln('}');
    return buffer.toString();
  }

  String _extractBody(FunctionBody body, Element element) {
    if (body is! BlockFunctionBody) {
      throw InvalidGenerationSourceError(
        'System function must use a block body {}. Expression bodies => are not supported.',
        element: element,
      );
    }
    return _transformStatements(body.block.statements);
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
      (m) => 'getEntity<${capitalize(m.group(1)!)}Component>()',
    );
    source = source.replaceAllMapped(
      RegExp(r'system\.getDataEvent\((\w+)\)'),
      (m) => 'getEntity<${capitalize(m.group(1)!)}Event>()',
    );
    source = source.replaceAllMapped(
      RegExp(r'system\.getEvent\((\w+)\)'),
      (m) => 'getEntity<${capitalize(m.group(1)!)}Event>()',
    );
    source = source.replaceAllMapped(
      RegExp(r'system\.getDependency\((\w+)\)'),
      (m) => 'getEntity<${capitalize(m.group(1)!)}Dependency>()',
    );
    return source;
  }
}

final class ECSCleanupSystemGenerator extends GeneratorForAnnotation<ECSCleanupSystemDefinition> {
  const ECSCleanupSystemGenerator() : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! TopLevelFunctionElement) {
      throw InvalidGenerationSourceError(
        '@ECSCleanupSystemDefinition can only be applied to top-level functions.',
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
    final raw = capitalize(funcName);
    final className = raw.endsWith('CleanupSystem') ? raw : '${raw}CleanupSystem';
    final cleansIfName = _extractFuncRef(astNode, 'cleansIf');
    final body = _extractBody(astNode.functionExpression.body, element);
    final cleansIfBody = cleansIfName != null
        ? _extractNamedFuncBody(cleansIfName, unit)
            ?.split('\n')
            .map(_transform)
            .join('\n')
        : null;

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSCleanupSystem {');

    if (cleansIfBody != null) {
      buffer.writeln('  @override');
      buffer.writeln('  bool get cleansIf {');
      buffer.write(cleansIfBody);
      buffer.writeln('  }');
      buffer.writeln();
    }

    buffer.writeln('  @override');
    buffer.writeln('  void cleanup() {');
    buffer.write(body);
    buffer.writeln('  }');
    buffer.writeln('}');
    return buffer.toString();
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

  String _extractBody(FunctionBody body, Element element) {
    if (body is! BlockFunctionBody) {
      throw InvalidGenerationSourceError(
        'System function must use a block body {}. Expression bodies => are not supported.',
        element: element,
      );
    }
    return _transformStatements(body.block.statements);
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
      (m) => 'getEntity<${capitalize(m.group(1)!)}Component>()',
    );
    source = source.replaceAllMapped(
      RegExp(r'system\.getDataEvent\((\w+)\)'),
      (m) => 'getEntity<${capitalize(m.group(1)!)}Event>()',
    );
    source = source.replaceAllMapped(
      RegExp(r'system\.getEvent\((\w+)\)'),
      (m) => 'getEntity<${capitalize(m.group(1)!)}Event>()',
    );
    source = source.replaceAllMapped(
      RegExp(r'system\.getDependency\((\w+)\)'),
      (m) => 'getEntity<${capitalize(m.group(1)!)}Dependency>()',
    );
    return source;
  }
}

final class ECSExecuteSystemGenerator extends GeneratorForAnnotation<ECSExecuteSystemDefinition> {
  const ECSExecuteSystemGenerator() : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! TopLevelFunctionElement) {
      throw InvalidGenerationSourceError(
        '@ECSExecuteSystemDefinition can only be applied to top-level functions.',
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
    final raw = capitalize(funcName);
    final className = raw.endsWith('ExecuteSystem') ? raw : '${raw}ExecuteSystem';
    final executesIfName = _extractFuncRef(astNode, 'executesIf');
    final body = _extractBody(astNode.functionExpression.body, element);
    final executesIfBody = executesIfName != null
        ? _extractNamedFuncBody(executesIfName, unit)
            ?.split('\n')
            .map(_transform)
            .join('\n')
        : null;

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSExecuteSystem {');

    if (executesIfBody != null) {
      buffer.writeln('  @override');
      buffer.writeln('  bool get executesIf {');
      buffer.write(executesIfBody);
      buffer.writeln('  }');
      buffer.writeln();
    }

    buffer.writeln('  @override');
    buffer.writeln('  void execute(Duration elapsed) {');
    buffer.write(body);
    buffer.writeln('  }');
    buffer.writeln('}');
    return buffer.toString();
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

  String _extractBody(FunctionBody body, Element element) {
    if (body is! BlockFunctionBody) {
      throw InvalidGenerationSourceError(
        'System function must use a block body {}. Expression bodies => are not supported.',
        element: element,
      );
    }
    return _transformStatements(body.block.statements);
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
      (m) => 'getEntity<${capitalize(m.group(1)!)}Component>()',
    );
    source = source.replaceAllMapped(
      RegExp(r'system\.getDataEvent\((\w+)\)'),
      (m) => 'getEntity<${capitalize(m.group(1)!)}Event>()',
    );
    source = source.replaceAllMapped(
      RegExp(r'system\.getEvent\((\w+)\)'),
      (m) => 'getEntity<${capitalize(m.group(1)!)}Event>()',
    );
    source = source.replaceAllMapped(
      RegExp(r'system\.getDependency\((\w+)\)'),
      (m) => 'getEntity<${capitalize(m.group(1)!)}Dependency>()',
    );
    return source;
  }
}
