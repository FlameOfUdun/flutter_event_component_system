import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
import 'package:source_gen/source_gen.dart';
import '_helpers.dart';

const _componentChecker = TypeChecker.typeNamed(
  Component,
  inPackage: 'flutter_event_component_system_annotations',
);
const _eventChecker = TypeChecker.typeNamed(
  Event,
  inPackage: 'flutter_event_component_system_annotations',
);
const _dependencyChecker = TypeChecker.typeNamed(
  Dependency,
  inPackage: 'flutter_event_component_system_annotations',
);

/// Builds a [DslContext] by scanning the [library] for annotated entities.
DslContext buildDslContext(LibraryReader library) {
  final components = <String, String>{};
  final events = <String, String>{};
  final dependencies = <String, String>{};

  for (final a in library.annotatedWith(_componentChecker)) {
    final name = a.element.name;
    if (name != null) components[name] = '${toPascalCase(name)}Component';
  }
  for (final a in library.annotatedWith(_eventChecker)) {
    final name = a.element.name;
    if (name != null) events[name] = '${toPascalCase(name)}Event';
  }
  for (final a in library.annotatedWith(_dependencyChecker)) {
    final name = a.element.name;
    if (name != null) dependencies[name] = '${toPascalCase(name)}Dependency';
  }

  return DslContext(
    components: components,
    events: events,
    dependencies: dependencies,
  );
}

/// Extends [ctx] with annotated entities from imported libraries.
DslContext _extendWithImports(DslContext ctx, LibraryElement libraryElement) {
  final components = Map<String, String>.of(ctx.components);
  final events = Map<String, String>.of(ctx.events);
  final dependencies = Map<String, String>.of(ctx.dependencies);

  for (final imported in libraryElement.firstFragment.importedLibraries) {
    for (final v in imported.topLevelVariables) {
      final name = v.name;
      if (name == null) continue;
      if (components.containsKey(name)) continue;
      if (dependencies.containsKey(name)) continue;
      if (_componentChecker.hasAnnotationOf(v)) {
        components[name] = '${toPascalCase(name)}Component';
      } else if (_dependencyChecker.hasAnnotationOf(v)) {
        dependencies[name] = '${toPascalCase(name)}Dependency';
      }
    }
    for (final f in imported.topLevelFunctions) {
      final name = f.name;
      if (name == null) continue;
      if (events.containsKey(name)) continue;
      if (_eventChecker.hasAnnotationOf(f)) {
        events[name] = '${toPascalCase(name)}Event';
      }
    }
  }

  return DslContext(
    components: components,
    events: events,
    dependencies: dependencies,
    paramReplacements: ctx.paramReplacements,
  );
}

final class ReactiveSystemGenerator extends GeneratorForAnnotation<ReactiveSystem> {
  const ReactiveSystemGenerator() : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@ReactiveSystem can only be applied to top-level classes.',
        element: element,
      );
    }

    final astNode = await buildStep.resolver.astNodeFor(
      element.firstFragment,
      resolve: true,
    );
    if (astNode is! ClassDeclaration) {
      throw InvalidGenerationSourceError(
        'Could not resolve AST for class.',
        element: element,
      );
    }

    final library = LibraryReader(element.library);
    final baseCtx = _extendWithImports(buildDslContext(library), element.library);
    final unit = astNode.root as CompilationUnit;
    final funcName = element.name!;
    final description = annotation.peek('description')?.stringValue;
    final raw = toPascalCase(funcName);
    final className = raw.endsWith('ReactiveSystem') ? raw : '${raw}ReactiveSystem';

    final reactsToClasses = _readReactsToFromClass(astNode, baseCtx);
    final reactsIfBody = _readReactsIfFromClass(astNode, baseCtx);

    final reactMethodDecl =
        astNode.members.whereType<MethodDeclaration>().where((m) => !m.isGetter && !m.isSetter && m.name.lexeme == 'react').firstOrNull;
    if (reactMethodDecl == null) {
      throw InvalidGenerationSourceError(
        '@ReactiveSystem class must declare a react() method.',
        element: element,
      );
    }

    final reactBody = reactMethodDecl.body;
    if (reactBody is! BlockFunctionBody) {
      throw InvalidGenerationSourceError(
        'react() must use a block body { }.',
        element: element,
      );
    }

    final reactMethodEl = element.methods.where((m) => m.name == 'react').firstOrNull;
    final params = reactMethodEl?.formalParameters ?? const <FormalParameterElement>[];
    final paramReplacements = _buildParamReplacements(params, reactsToClasses);
    final ctx = baseCtx.withParamReplacements(paramReplacements);

    final reactTransformed = transformDslStatements(reactBody.block.statements, ctx, rewriteReads: true);
    final interactsWith = detectInteractsWith(reactBody.block.statements, unit, ctx);
    final privateHelpers = collectPrivateHelpers(reactBody.block.statements, unit);

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSReactiveSystem {');

    buffer.writeln('  @override');
    buffer.writeln('  Set<Type> get reactsTo {');
    buffer.writeln('    return const {${reactsToClasses.join(', ')}};');
    buffer.writeln('  }');

    if (interactsWith.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('  @override');
      buffer.writeln('  Set<Type> get interactsWith {');
      buffer.writeln('    return const {${interactsWith.join(', ')}};');
      buffer.writeln('  }');
    }

    if (reactsIfBody != null) {
      buffer.writeln();
      buffer.writeln('  @override');
      buffer.writeln('  bool get reactsIf {');
      buffer.write(reactsIfBody);
      buffer.writeln('  }');
    }

    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  void react() {');
    buffer.write(reactTransformed);
    buffer.writeln('  }');

    for (final helperName in privateHelpers) {
      buffer.writeln();
      buffer.write(emitPrivateMethod(helperName, unit, baseCtx));
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  Map<String, String> _buildParamReplacements(
    List<FormalParameterElement> params,
    List<String> clases,
  ) {
    if (params.isEmpty || clases.isEmpty) {
      return const {};
    }

    if (params.length != clases.length) {
      throw InvalidGenerationSourceError(
        'Number of react() parameters must match the number of reactsTo classes.',
      );
    }

    final data = <String, String>{};
    for (var index = 0; index < clases.length; index++) {
      final target = clases[index];
      final param = params[index];
      if (target.endsWith("Event")) {
        data[param.name!] = 'getEntity<$target>().data';
      } else if (target.endsWith("Component")) {
        data[param.name!] = 'getEntity<$target>().value';
      }
    }
    return data;
  }

  List<String> _readReactsToFromClass(
    ClassDeclaration classDecl,
    DslContext ctx,
  ) {
    final getter = classDecl.members.whereType<MethodDeclaration>().where((m) => m.isGetter && m.name.lexeme == 'reactsTo').firstOrNull;

    if (getter == null) return const [];

    // Extract the list literal from either body style.
    ListLiteral? listLiteral;
    final body = getter.body;
    if (body is ExpressionFunctionBody) {
      if (body.expression is ListLiteral) {
        listLiteral = body.expression as ListLiteral;
      }
    } else if (body is BlockFunctionBody) {
      for (final stmt in body.block.statements) {
        if (stmt is ReturnStatement && stmt.expression is ListLiteral) {
          listLiteral = stmt.expression as ListLiteral;
          break;
        }
      }
    }

    if (listLiteral == null) return const [];

    final result = <String>[];
    for (final item in listLiteral.elements) {
      if (item is! SimpleIdentifier) continue;
      final name = item.name;

      // Same-library events take priority over components.
      final eventClass = ctx.events[name];
      if (eventClass != null) {
        result.add(eventClass);
        continue;
      }

      final componentClass = ctx.components[name];
      if (componentClass != null) {
        result.add(componentClass);
        continue;
      }

      // Cross-library: inspect the resolved element's annotation directly.
      final resolved = item.element;
      if (resolved is TopLevelFunctionElement && _eventChecker.hasAnnotationOf(resolved)) {
        final r = toPascalCase(name);
        result.add(r.endsWith('Event') ? r : '${r}Event');
      } else if (resolved is GetterElement) {
        final variable = resolved.variable;
        if (variable is TopLevelVariableElement && _componentChecker.hasAnnotationOf(variable)) {
          result.add('${toPascalCase(name)}Component');
        }
      } else if (resolved is TopLevelVariableElement && _componentChecker.hasAnnotationOf(resolved)) {
        result.add('${toPascalCase(name)}Component');
      }
    }

    return result;
  }

  String? _readReactsIfFromClass(ClassDeclaration classDecl, DslContext ctx) {
    final getter = classDecl.members.whereType<MethodDeclaration>().where((m) => m.isGetter && m.name.lexeme == 'reactsIf').firstOrNull;

    if (getter == null) return null;

    final body = getter.body;
    if (body is! BlockFunctionBody) return null;

    return transformDslStatements(
      body.block.statements,
      ctx,
      rewriteReads: true,
    );
  }
}

final class InitializeSystemGenerator extends GeneratorForAnnotation<InitializeSystem> {
  const InitializeSystemGenerator() : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@InitializeSystem can only be applied to top-level classes.',
        element: element,
      );
    }

    final astNode = await buildStep.resolver.astNodeFor(
      element.firstFragment,
      resolve: true,
    );
    if (astNode is! ClassDeclaration) {
      throw InvalidGenerationSourceError(
        'Could not resolve AST.',
        element: element,
      );
    }

    final library = LibraryReader(element.library);
    final ctx = buildDslContext(library);
    final unit = astNode.root as CompilationUnit;
    final funcName = element.name!;
    final description = annotation.peek('description')?.stringValue;
    final raw = toPascalCase(funcName);
    final className = raw.endsWith('InitializeSystem') ? raw : '${raw}InitializeSystem';

    final initMethodDecl =
        astNode.members.whereType<MethodDeclaration>().where((m) => !m.isGetter && !m.isSetter && m.name.lexeme == 'initialize').firstOrNull;
    if (initMethodDecl == null) {
      throw InvalidGenerationSourceError(
        '@InitializeSystem class must declare an initialize() method.',
        element: element,
      );
    }

    final initBody = initMethodDecl.body;
    if (initBody is! BlockFunctionBody) {
      throw InvalidGenerationSourceError(
        'initialize() must use a block body { }.',
        element: element,
      );
    }

    final transformed = transformDslStatements(initBody.block.statements, ctx, rewriteReads: true);
    final privateHelpers = collectPrivateHelpers(initBody.block.statements, unit);

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSInitializeSystem {');
    buffer.writeln('  @override');
    buffer.writeln('  void initialize() {');
    buffer.write(transformed);
    buffer.writeln('  }');
    for (final h in privateHelpers) {
      buffer.writeln();
      buffer.write(emitPrivateMethod(h, unit, ctx));
    }
    buffer.writeln('}');
    return buffer.toString();
  }
}

final class TeardownSystemGenerator extends GeneratorForAnnotation<TeardownSystem> {
  const TeardownSystemGenerator() : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! TopLevelFunctionElement) {
      throw InvalidGenerationSourceError(
        '@TeardownSystem can only be applied to top-level functions.',
        element: element,
      );
    }

    final astNode = await buildStep.resolver.astNodeFor(
      element.firstFragment,
      resolve: true,
    );
    if (astNode is! FunctionDeclaration) {
      throw InvalidGenerationSourceError(
        'Could not resolve AST.',
        element: element,
      );
    }

    final library = LibraryReader(element.library);
    final ctx = buildDslContext(library);
    final unit = astNode.root as CompilationUnit;
    final funcName = element.name!;
    final description = annotation.peek('description')?.stringValue;
    final raw = toPascalCase(funcName);
    final className = raw.endsWith('TeardownSystem') ? raw : '${raw}TeardownSystem';

    final body = astNode.functionExpression.body;
    if (body is! BlockFunctionBody) {
      throw InvalidGenerationSourceError(
        'System must use block body.',
        element: element,
      );
    }
    final transformed = transformDslStatements(body.block.statements, ctx);
    final privateHelpers = collectPrivateHelpers(body.block.statements, unit);

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSTeardownSystem {');
    buffer.writeln('  @override');
    buffer.writeln('  void teardown() {');
    buffer.write(transformed);
    buffer.writeln('  }');
    for (final h in privateHelpers) {
      buffer.writeln();
      buffer.write(emitPrivateMethod(h, unit, ctx));
    }
    buffer.writeln('}');
    return buffer.toString();
  }
}

final class CleanupSystemGenerator extends GeneratorForAnnotation<CleanupSystem> {
  const CleanupSystemGenerator() : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@CleanupSystem can only be applied to top-level classes.',
        element: element,
      );
    }

    final astNode = await buildStep.resolver.astNodeFor(
      element.firstFragment,
      resolve: true,
    );
    if (astNode is! ClassDeclaration) {
      throw InvalidGenerationSourceError(
        'Could not resolve AST for class.',
        element: element,
      );
    }

    final library = LibraryReader(element.library);
    final ctx = buildDslContext(library);
    final unit = astNode.root as CompilationUnit;
    final funcName = element.name!;
    final description = annotation.peek('description')?.stringValue;
    final raw = toPascalCase(funcName);
    final className = raw.endsWith('CleanupSystem') ? raw : '${raw}CleanupSystem';

    final cleanMethodDecl =
        astNode.members.whereType<MethodDeclaration>().where((m) => !m.isGetter && !m.isSetter && m.name.lexeme == 'cleanup').firstOrNull;
    if (cleanMethodDecl == null) {
      throw InvalidGenerationSourceError(
        '@CleanupSystem class must declare a cleanup() method.',
        element: element,
      );
    }

    final cleanBody = cleanMethodDecl.body;
    if (cleanBody is! BlockFunctionBody) {
      throw InvalidGenerationSourceError(
        'cleanup() must use a block body { }.',
        element: element,
      );
    }

    final transformed = transformDslStatements(cleanBody.block.statements, ctx, rewriteReads: true);
    final privateHelpers = collectPrivateHelpers(cleanBody.block.statements, unit);
    final cleansIfBody = _readCleansIfFromClass(astNode, ctx);

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
    buffer.write(transformed);
    buffer.writeln('  }');
    for (final h in privateHelpers) {
      buffer.writeln();
      buffer.write(emitPrivateMethod(h, unit, ctx));
    }
    buffer.writeln('}');
    return buffer.toString();
  }

  String? _readCleansIfFromClass(ClassDeclaration classDecl, DslContext ctx) {
    final getter = classDecl.members.whereType<MethodDeclaration>().where((m) => m.isGetter && m.name.lexeme == 'cleansIf').firstOrNull;

    if (getter == null) return null;

    final body = getter.body;
    if (body is! BlockFunctionBody) return null;

    return transformDslStatements(
      body.block.statements,
      ctx,
      rewriteReads: true,
    );
  }
}

final class ExecuteSystemGenerator extends GeneratorForAnnotation<ExecuteSystem> {
  const ExecuteSystemGenerator() : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@ExecuteSystem can only be applied to top-level classes.',
        element: element,
      );
    }

    final astNode = await buildStep.resolver.astNodeFor(
      element.firstFragment,
      resolve: true,
    );
    if (astNode is! ClassDeclaration) {
      throw InvalidGenerationSourceError(
        'Could not resolve AST for class.',
        element: element,
      );
    }

    final library = LibraryReader(element.library);
    final ctx = buildDslContext(library);
    final unit = astNode.root as CompilationUnit;
    final funcName = element.name!;
    final description = annotation.peek('description')?.stringValue;
    final raw = toPascalCase(funcName);
    final className = raw.endsWith('ExecuteSystem') ? raw : '${raw}ExecuteSystem';

    final executeMethodDecl =
        astNode.members.whereType<MethodDeclaration>().where((m) => !m.isGetter && !m.isSetter && m.name.lexeme == 'execute').firstOrNull;
    if (executeMethodDecl == null) {
      throw InvalidGenerationSourceError(
        '@ExecuteSystem class must declare an execute() method.',
        element: element,
      );
    }

    final executeBody = executeMethodDecl.body;
    if (executeBody is! BlockFunctionBody) {
      throw InvalidGenerationSourceError(
        'execute() must use a block body { }.',
        element: element,
      );
    }

    // `elapsed` is a real Duration parameter — do NOT replace it. No paramReplacements.
    final transformed = transformDslStatements(executeBody.block.statements, ctx);
    final interactsWith = detectInteractsWith(executeBody.block.statements, unit, ctx);
    final privateHelpers = collectPrivateHelpers(executeBody.block.statements, unit);
    final executesIfBody = _readExecutesIfFromClass(astNode, ctx);

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSExecuteSystem {');

    if (interactsWith.isNotEmpty) {
      buffer.writeln('  @override');
      buffer.writeln('  Set<Type> get interactsWith {');
      buffer.writeln('    return const {${interactsWith.join(', ')}};');
      buffer.writeln('  }');
      buffer.writeln();
    }

    if (executesIfBody != null) {
      buffer.writeln('  @override');
      buffer.writeln('  bool get executesIf {');
      buffer.write(executesIfBody);
      buffer.writeln('  }');
      buffer.writeln();
    }

    buffer.writeln('  @override');
    buffer.writeln('  void execute(Duration elapsed) {');
    buffer.write(transformed);
    buffer.writeln('  }');
    for (final h in privateHelpers) {
      buffer.writeln();
      buffer.write(emitPrivateMethod(h, unit, ctx));
    }
    buffer.writeln('}');
    return buffer.toString();
  }

  String? _readExecutesIfFromClass(ClassDeclaration classDecl, DslContext ctx) {
    final getter = classDecl.members.whereType<MethodDeclaration>().where((m) => m.isGetter && m.name.lexeme == 'executesIf').firstOrNull;

    if (getter == null) return null;

    final body = getter.body;
    if (body is! BlockFunctionBody) return null;

    return transformDslStatements(
      body.block.statements,
      ctx,
      rewriteReads: true,
    );
  }
}
