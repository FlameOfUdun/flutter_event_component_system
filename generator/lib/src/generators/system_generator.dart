import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
import 'package:source_gen/source_gen.dart';
import '_helpers.dart';

final class ECSReactiveSystemGenerator extends GeneratorForAnnotation<ECSReactiveSystemDefinition> {
  static const _componentChecker = TypeChecker.typeNamed(
    ECSComponentDefinition,
    inPackage: 'flutter_event_component_system_annotations',
  );
  static const _eventChecker = TypeChecker.typeNamed(
    ECSEventDefinition,
    inPackage: 'flutter_event_component_system_annotations',
  );
  static const _dataEventChecker = TypeChecker.typeNamed(
    ECSDataEventDefinition,
    inPackage: 'flutter_event_component_system_annotations',
  );
  static const _dependencyChecker = TypeChecker.typeNamed(
    ECSDependencyDefinition,
    inPackage: 'flutter_event_component_system_annotations',
  );

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
    final reactsToTypes = _resolveEntityNamesFromAnnotation(annotation, 'reactsTo', astNode, unit);
    final interactsWithTypes = _resolveEntityNamesFromAnnotation(annotation, 'interactsWith', astNode, unit);
    final reactsIfName = extractFuncRef(astNode, 'reactsIf');

    final reactBody = extractBlockBody(astNode.functionExpression.body, element);
    final reactsIfBody = reactsIfName != null
        ? extractNamedFuncBody(reactsIfName, unit)
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

  /// Resolves entity class names for a Set-typed annotation field (e.g. `reactsTo`, `interactsWith`).
  ///
  /// Primary path: reads the fully-evaluated [DartObject]s from [annotation] via
  /// [ConstantReader.setValue], then uses each object's [VariableElement] to check
  /// annotations with [TypeChecker] — works for entities declared in imported files.
  ///
  /// Fallback path: for any object whose [variable] is null, falls back to the local
  /// AST scan in [_resolveEntityTypeName] using the identifier name from [funcDecl].
  List<String> _resolveEntityNamesFromAnnotation(
    ConstantReader annotation,
    String param,
    FunctionDeclaration funcDecl,
    CompilationUnit unit,
  ) {
    final field = annotation.peek(param);
    if (field != null && field.isSet) {
      return field.setValue.map((obj) {
        final varEl = obj.variable;
        if (varEl != null && varEl.name != null) {
          final raw = capitalize(varEl.name!);
          if (_componentChecker.hasAnnotationOf(varEl)) return '${raw}Component';
          if (_dataEventChecker.hasAnnotationOf(varEl)) return '${raw}Event';
          if (_eventChecker.hasAnnotationOf(varEl)) return '${raw}Event';
          if (_dependencyChecker.hasAnnotationOf(varEl)) return '${raw}Dependency';
          return raw;
        }
        // Fallback: find the name via AST and scan the local unit.
        final name = _findIdentifierNameInAst(funcDecl, param, obj);
        return name != null ? _resolveEntityTypeName(name, unit) : '';
      }).toList();
    }
    return [];
  }

  /// Walks the annotation AST for [param] to find an identifier whose constant
  /// value matches [obj], returning its source name. Used only as a fallback
  /// when [DartObject.variable] is null.
  String? _findIdentifierNameInAst(FunctionDeclaration funcDecl, String param, Object obj) {
    for (final ann in funcDecl.metadata) {
      for (final arg in ann.arguments?.arguments ?? <Expression>[]) {
        if (arg is NamedExpression && arg.name.label.name == param) {
          if (arg.expression is SetOrMapLiteral) {
            for (final el in (arg.expression as SetOrMapLiteral).elements) {
              if (el is SimpleIdentifier) return el.name;
            }
          }
        }
      }
    }
    return null;
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
    final body = extractBlockBody(astNode.functionExpression.body, element);

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
    final cleansIfName = extractFuncRef(astNode, 'cleansIf');
    final body = extractBlockBody(astNode.functionExpression.body, element);
    final cleansIfBody = cleansIfName != null
        ? extractNamedFuncBody(cleansIfName, unit)
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
    final executesIfName = extractFuncRef(astNode, 'executesIf');
    final body = extractBlockBody(astNode.functionExpression.body, element);
    final executesIfBody = executesIfName != null
        ? extractNamedFuncBody(executesIfName, unit)
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
}
