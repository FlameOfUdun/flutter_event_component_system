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

final class ReactiveSystemGenerator
    extends GeneratorForAnnotation<ReactiveSystem> {
  const ReactiveSystemGenerator()
      : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! TopLevelFunctionElement) {
      throw InvalidGenerationSourceError(
        '@ReactiveSystem can only be applied to top-level functions.',
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

    final library = LibraryReader(element.library);
    final baseCtx = buildDslContext(library);
    final unit = astNode.root as CompilationUnit;
    final funcName = element.name!;
    final description = annotation.peek('description')?.stringValue;
    final raw = toPascalCase(funcName);
    final className =
        raw.endsWith('ReactiveSystem') ? raw : '${raw}ReactiveSystem';

    final reactsToClasses = await _readReactsTo(annotation);

    final params = element.formalParameters;
    final paramReplacements = _buildParamReplacements(params, reactsToClasses);
    final ctx = baseCtx.withParamReplacements(paramReplacements);

    final body = astNode.functionExpression.body;
    if (body is! BlockFunctionBody) {
      throw InvalidGenerationSourceError(
        'System function must use a block body {}.',
        element: element,
      );
    }

    final reactBody = transformDslStatements(body.block.statements, ctx);
    final interactsWith = detectInteractsWith(body.block.statements, unit, ctx);
    final privateHelpers = collectPrivateHelpers(body.block.statements, unit);
    final reactsIfBody = await _resolveReactsIfBody(annotation, buildStep, ctx);

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
    buffer.write(reactBody);
    buffer.writeln('  }');

    for (final helperName in privateHelpers) {
      buffer.writeln();
      buffer.write(emitPrivateMethod(helperName, unit, ctx));
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  /// Reads the `reactsTo` list from [annotation], resolves each function reference,
  /// and derives the generated event class name via toPascalCase + 'Event'.
  /// Returns an empty list if `reactsTo` was not provided.
  Future<List<String>> _readReactsTo(ConstantReader annotation) async {
    final reactsToReader = annotation.peek('reactsTo');
    if (reactsToReader == null || reactsToReader.isNull) return const [];

    final result = <String>[];
    for (final item in reactsToReader.listValue) {
      final funcElement = item.toFunctionValue();
      if (funcElement == null) continue;
      final name = funcElement.name;
      if (name == null) continue;
      final raw = toPascalCase(name);
      result.add(raw.endsWith('Event') ? raw : '${raw}Event');
    }
    return result;
  }

  Map<String, String> _buildParamReplacements(
    List<FormalParameterElement> params,
    List<String> reactsToClasses,
  ) {
    if (params.isEmpty || reactsToClasses.isEmpty) return const {};
    final eventClass = reactsToClasses.first;
    return {
      for (final p in params) p.name!: 'getEntity<$eventClass>().data',
    };
  }

  /// Reads the `reactsIf` function reference from [annotation], resolves its AST,
  /// transforms its body using [ctx], and returns the indented body string.
  /// Returns null if `reactsIf` was not provided.
  Future<String?> _resolveReactsIfBody(
    ConstantReader annotation,
    BuildStep buildStep,
    DslContext ctx,
  ) async {
    final reactsIfReader = annotation.peek('reactsIf');
    if (reactsIfReader == null || reactsIfReader.isNull) return null;

    final funcElement = reactsIfReader.objectValue.toFunctionValue();
    if (funcElement == null) return null;

    final astNode = await buildStep.resolver.astNodeFor(
      funcElement.firstFragment,
      resolve: true,
    );
    if (astNode is! FunctionDeclaration) return null;

    final body = astNode.functionExpression.body;
    if (body is! BlockFunctionBody) return null;

    return transformDslStatements(body.block.statements, ctx, rewriteReads: true);
  }
}

final class InitializeSystemGenerator
    extends GeneratorForAnnotation<InitializeSystem> {
  const InitializeSystemGenerator()
      : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! TopLevelFunctionElement) {
      throw InvalidGenerationSourceError(
        '@InitializeSystem can only be applied to top-level functions.',
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
    final className =
        raw.endsWith('InitializeSystem') ? raw : '${raw}InitializeSystem';

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

final class TeardownSystemGenerator
    extends GeneratorForAnnotation<TeardownSystem> {
  const TeardownSystemGenerator()
      : super(inPackage: 'flutter_event_component_system_annotations');

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
    final className =
        raw.endsWith('TeardownSystem') ? raw : '${raw}TeardownSystem';

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

final class CleanupSystemGenerator
    extends GeneratorForAnnotation<CleanupSystem> {
  const CleanupSystemGenerator()
      : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! TopLevelFunctionElement) {
      throw InvalidGenerationSourceError(
        '@CleanupSystem can only be applied to top-level functions.',
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
    final className =
        raw.endsWith('CleanupSystem') ? raw : '${raw}CleanupSystem';

    final body = astNode.functionExpression.body;
    if (body is! BlockFunctionBody) {
      throw InvalidGenerationSourceError(
        'System must use block body.',
        element: element,
      );
    }
    final transformed = transformDslStatements(body.block.statements, ctx);
    final privateHelpers = collectPrivateHelpers(body.block.statements, unit);
    final cleansIfBody = await _resolveCleansIfBody(annotation, buildStep, ctx);

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

  /// Reads the `cleansIf` function reference from [annotation], resolves its AST,
  /// transforms its body using [ctx] with reads rewritten, and returns the indented
  /// body string. Returns null if `cleansIf` was not provided.
  Future<String?> _resolveCleansIfBody(
    ConstantReader annotation,
    BuildStep buildStep,
    DslContext ctx,
  ) async {
    final cleansIfReader = annotation.peek('cleansIf');
    if (cleansIfReader == null || cleansIfReader.isNull) return null;

    final funcElement = cleansIfReader.objectValue.toFunctionValue();
    if (funcElement == null) return null;

    final astNode = await buildStep.resolver.astNodeFor(
      funcElement.firstFragment,
      resolve: true,
    );
    if (astNode is! FunctionDeclaration) return null;

    final body = astNode.functionExpression.body;
    if (body is! BlockFunctionBody) return null;

    return transformDslStatements(body.block.statements, ctx, rewriteReads: true);
  }
}

final class ExecuteSystemGenerator
    extends GeneratorForAnnotation<ExecuteSystem> {
  const ExecuteSystemGenerator()
      : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! TopLevelFunctionElement) {
      throw InvalidGenerationSourceError(
        '@ExecuteSystem can only be applied to top-level functions.',
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
    final className =
        raw.endsWith('ExecuteSystem') ? raw : '${raw}ExecuteSystem';

    final body = astNode.functionExpression.body;
    if (body is! BlockFunctionBody) {
      throw InvalidGenerationSourceError(
        'System must use block body.',
        element: element,
      );
    }

    // `elapsed` is a real Duration parameter — do NOT replace it. No paramReplacements.
    final transformed = transformDslStatements(body.block.statements, ctx);
    final interactsWith = detectInteractsWith(body.block.statements, unit, ctx);
    final privateHelpers = collectPrivateHelpers(body.block.statements, unit);
    final executesIfBody = await _resolveExecutesIfBody(annotation, buildStep, ctx);

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

  /// Reads the `executesIf` function reference from [annotation], resolves its AST,
  /// transforms its body using [ctx] with reads rewritten, and returns the indented
  /// body string. Returns null if `executesIf` was not provided.
  Future<String?> _resolveExecutesIfBody(
    ConstantReader annotation,
    BuildStep buildStep,
    DslContext ctx,
  ) async {
    final executesIfReader = annotation.peek('executesIf');
    if (executesIfReader == null || executesIfReader.isNull) return null;

    final funcElement = executesIfReader.objectValue.toFunctionValue();
    if (funcElement == null) return null;

    final astNode = await buildStep.resolver.astNodeFor(
      funcElement.firstFragment,
      resolve: true,
    );
    if (astNode is! FunctionDeclaration) return null;

    final body = astNode.functionExpression.body;
    if (body is! BlockFunctionBody) return null;

    return transformDslStatements(body.block.statements, ctx, rewriteReads: true);
  }
}
