import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
import 'package:source_gen/source_gen.dart';

final class ECSFeatureGenerator extends GeneratorForAnnotation<FeatureDefinition> {
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
  static const _reactiveSystemChecker = TypeChecker.typeNamed(
    ECSReactiveSystemDefinition,
    inPackage: 'flutter_event_component_system_annotations',
  );

  const ECSFeatureGenerator() : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String?> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is LibraryElement) {
      return _generateFromLibrary(
        LibraryReader(element),
        annotation,
      );
    }

    if (element is TopLevelFunctionElement) {
      return _generateFromFunction(element, annotation, buildStep);
    }

    throw InvalidGenerationSourceError(
      '@FeatureDefinition must be on a library directive or a top-level function.',
      element: element,
    );
  }

  String? _generateFromLibrary(
    LibraryReader library,
    ConstantReader annotation,
  ) {
    final components = library.annotatedWith(_componentChecker).toList();
    final events = library.annotatedWith(_eventChecker).toList();
    final dataEvents = library.annotatedWith(_dataEventChecker).toList();
    final dependencies = library.annotatedWith(_dependencyChecker).toList();
    final reactiveSystems = library.annotatedWith(_reactiveSystemChecker).toList();

    if (components.isEmpty && events.isEmpty && dataEvents.isEmpty &&
        dependencies.isEmpty && reactiveSystems.isEmpty) {
      return null;
    }

    final description = annotation.peek('description')?.stringValue;
    final libraryName = library.element.name ?? '';
    final base = libraryName.isNotEmpty ? _capitalize(libraryName) : 'Generated';
    final className = base.endsWith('Feature') ? base : '${base}Feature';

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSFeature {');
    buffer.writeln('  $className() {');

    for (final a in components) {
      final raw = _capitalize(a.element.name!);
      buffer.writeln('    addEntity(${raw.endsWith('Component') ? raw : '${raw}Component'}());');
    }
    for (final a in events) {
      final raw = _capitalize(a.element.name!);
      buffer.writeln('    addEntity(${raw.endsWith('Event') ? raw : '${raw}Event'}());');
    }
    for (final a in dataEvents) {
      final raw = _capitalize(a.element.name!);
      buffer.writeln('    addEntity(${raw.endsWith('Event') ? raw : '${raw}Event'}());');
    }
    for (final a in dependencies) {
      final raw = _capitalize(a.element.name!);
      buffer.writeln('    addEntity(${raw.endsWith('Dependency') ? raw : '${raw}Dependency'}());');
    }
    for (final a in reactiveSystems) {
      final raw = _capitalize(a.element.name!);
      buffer.writeln('    addSystem(${raw.endsWith('ReactiveSystem') ? raw : '${raw}ReactiveSystem'}());');
    }

    buffer.writeln('  }');
    buffer.writeln('}');
    return buffer.toString();
  }

  Future<String?> _generateFromFunction(
    TopLevelFunctionElement element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
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

    final rawName = _deriveClassName(funcName);
    final className = rawName.endsWith('Feature') ? rawName : '${rawName}Feature';

    final allParams = astNode.functionExpression.parameters?.parameters ?? <FormalParameter>[];
    final extraParams = allParams.skip(1).toList();
    final constructorParams = _formatConstructorParams(extraParams);
    final body = _transformBody(astNode.functionExpression.body, unit);

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSFeature {');
    buffer.writeln('  $className($constructorParams) {');
    buffer.write(body);
    buffer.writeln('  }');
    buffer.writeln('}');
    return buffer.toString();
  }

  String _deriveClassName(String funcName) {
    if (funcName.startsWith('build') && funcName.length > 5) {
      return funcName.substring(5);
    }
    return _capitalize(funcName);
  }

  String _formatConstructorParams(List<FormalParameter> params) {
    if (params.isEmpty) return '';
    final named = params.whereType<DefaultFormalParameter>().where((p) => p.isNamed).toList();
    final positional = params.where((p) => p is! DefaultFormalParameter || !p.isNamed).toList();
    final parts = <String>[
      for (final p in positional) p.toSource(),
      if (named.isNotEmpty) '{\n${named.map((p) => '    ${p.toSource()}').join(',\n')},\n  }',
    ];
    return parts.join(', ');
  }

  String _transformBody(FunctionBody body, CompilationUnit unit) {
    if (body is! BlockFunctionBody) return '';
    final buffer = StringBuffer();
    for (final stmt in body.block.statements) {
      buffer.writeln('    ${_transform(stmt.toSource(), unit)}');
    }
    return buffer.toString();
  }

  String _transform(String source, CompilationUnit unit) {
    source = source.replaceAllMapped(
      RegExp(r'feature\.addComponent\((\w+)\)'),
      (m) => 'addEntity(${_resolveVarType(m.group(1)!, unit)}())',
    );
    source = source.replaceAllMapped(
      RegExp(r'feature\.addEvent\((\w+)\)'),
      (m) => 'addEntity(${_resolveVarType(m.group(1)!, unit)}())',
    );
    source = source.replaceAllMapped(
      RegExp(r'feature\.addDataEvent\((\w+)\)'),
      (m) => 'addEntity(${_resolveVarType(m.group(1)!, unit)}())',
    );
    source = source.replaceAllMapped(
      RegExp(r'feature\.addDependency\((\w+)\)'),
      (m) => 'addEntity(${_resolveVarType(m.group(1)!, unit)}())',
    );
    source = source.replaceAllMapped(
      RegExp(r'feature\.addReactiveSystem\((\w+)\)'),
      (m) => 'addSystem(${_resolveSystemType(m.group(1)!, 'ReactiveSystem')}())',
    );
    source = source.replaceAllMapped(
      RegExp(r'feature\.addInitializeSystem\((\w+)\)'),
      (m) => 'addSystem(${_resolveSystemType(m.group(1)!, 'InitializeSystem')}())',
    );
    source = source.replaceAllMapped(
      RegExp(r'feature\.addExecuteSystem\((\w+)\)'),
      (m) => 'addSystem(${_resolveSystemType(m.group(1)!, 'ExecuteSystem')}())',
    );
    source = source.replaceAllMapped(
      RegExp(r'feature\.addCleanupSystem\((\w+)\)'),
      (m) => 'addSystem(${_resolveSystemType(m.group(1)!, 'CleanupSystem')}())',
    );
    source = source.replaceAllMapped(
      RegExp(r'feature\.addTeardownSystem\((\w+)\)'),
      (m) => 'addSystem(${_resolveSystemType(m.group(1)!, 'TeardownSystem')}())',
    );
    return source;
  }

  String _resolveVarType(String varName, CompilationUnit unit) {
    for (final decl in unit.declarations) {
      if (decl is TopLevelVariableDeclaration) {
        final hasVar = decl.variables.variables.any((v) => v.name.lexeme == varName);
        if (!hasVar) continue;
        for (final ann in decl.metadata) {
          final name = ann.name.name.toLowerCase();
          final raw = _capitalize(varName);
          if (name.contains('component')) return raw.endsWith('Component') ? raw : '${raw}Component';
          if (name.contains('dataevent')) return raw.endsWith('Event') ? raw : '${raw}Event';
          if (name.contains('event')) return raw.endsWith('Event') ? raw : '${raw}Event';
          if (name.contains('dependency')) return raw.endsWith('Dependency') ? raw : '${raw}Dependency';
        }
      }
    }
    return _capitalize(varName);
  }

  String _resolveSystemType(String funcName, String suffix) {
    final raw = _capitalize(funcName);
    return raw.endsWith(suffix) ? raw : '$raw$suffix';
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
