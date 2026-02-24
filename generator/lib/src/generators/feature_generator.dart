// lib/src/generators/feature_generator.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
import 'package:source_gen/source_gen.dart';

final class FeatureGenerator extends GeneratorForAnnotation<FeatureDefinition> {
  static const _componentChecker = TypeChecker.typeNamed(
    ComponentDefinition,
    inPackage: 'flutter_event_component_system_annotations',
  );
  static const _eventChecker = TypeChecker.typeNamed(
    EventDefinition,
    inPackage: 'flutter_event_component_system_annotations',
  );
  static const _dataEventChecker = TypeChecker.typeNamed(
    DataEventDefinition,
    inPackage: 'flutter_event_component_system_annotations',
  );
  static const _reactiveSystemChecker = TypeChecker.typeNamed(
    ReactiveSystemDefinition,
    inPackage: 'flutter_event_component_system_annotations',
  );

  const FeatureGenerator() : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String?> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    // ── Case 1: @FeatureDefinition on the library directive ────────────────
    if (element is LibraryElement) {
      return _generateFromLibrary(
        LibraryReader(element),
        annotation,
      );
    }

    // ── Case 2: @FeatureDefinition on a top-level function ─────────────────
    if (element is TopLevelFunctionElement) {
      return _generateFromFunction(element, annotation, buildStep);
    }

    throw InvalidGenerationSourceError(
      '@FeatureDefinition must be on a library directive or a top-level function.',
      element: element,
    );
  }

  // ── Library-level: auto-scan all annotated elements ──────────────────────

  String? _generateFromLibrary(
    LibraryReader library,
    ConstantReader annotation,
  ) {
    final components = library.annotatedWith(_componentChecker).toList();
    final events = library.annotatedWith(_eventChecker).toList();
    final dataEvents = library.annotatedWith(_dataEventChecker).toList();
    final reactiveSystems = library.annotatedWith(_reactiveSystemChecker).toList();

    if (components.isEmpty && events.isEmpty && dataEvents.isEmpty && reactiveSystems.isEmpty) {
      return null;
    }

    final description = annotation.peek('description')?.stringValue;
    final libraryName = library.element.name ?? '';
    final rawName = libraryName.isNotEmpty ? _capitalize(libraryName) : 'Generated';
    final className = rawName.endsWith('Feature') ? rawName : '${rawName}Feature';

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSFeature {');
    buffer.writeln('  $className() {');

    for (final a in components) {
      buffer.writeln('    addEntity(${_resolveComponentName(a.element.name!, a.annotation.peek('name')?.stringValue)}());');
    }
    for (final a in events) {
      buffer.writeln('    addEntity(${_resolveEventName(a.element.name!, a.annotation.peek('name')?.stringValue)}());');
    }
    for (final a in dataEvents) {
      buffer.writeln('    addEntity(${_resolveEventName(a.element.name!, a.annotation.peek('name')?.stringValue)}());');
    }
    for (final a in reactiveSystems) {
      buffer.writeln('    addSystem(${_resolveSystemName(a.element.name!, a.annotation.peek('name')?.stringValue)}());');
    }

    buffer.writeln('  }');
    buffer.writeln('}');
    return buffer.toString();
  }

  // ── Function-level: explicit addXxx calls via AST ────────────────────────

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
    final customName = annotation.peek('name')?.stringValue;
    final description = annotation.peek('description')?.stringValue;

    final rawName = customName ?? _deriveClassName(funcName);
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

  // ── Name Helpers ──────────────────────────────────────────────────────────

  String _deriveClassName(String funcName) {
    if (funcName.startsWith('build') && funcName.length > 5) {
      return funcName.substring(5);
    }
    return _capitalize(funcName);
  }

  String _resolveComponentName(String varName, String? custom) {
    final raw = custom ?? _capitalize(varName);
    return raw.endsWith('Component') ? raw : '${raw}Component';
  }

  String _resolveEventName(String varName, String? custom) {
    final raw = custom ?? _capitalize(varName);
    return raw.endsWith('Event') ? raw : '${raw}Event';
  }

  String _resolveSystemName(String funcName, String? custom) {
    final raw = custom ?? _capitalize(funcName);
    return raw.endsWith('ReactiveSystem') ? raw : '${raw}ReactiveSystem';
  }

  // ── Constructor Params ────────────────────────────────────────────────────

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

  // ── Body Transform ────────────────────────────────────────────────────────

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
      RegExp(r'feature\.addReactiveSystem\((\w+)\)'),
      (m) => 'addSystem(${_resolveSystemVarType(m.group(1)!, unit)}())',
    );
    return source;
  }

  String _resolveVarType(String varName, CompilationUnit unit) {
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

  String _resolveSystemVarType(String funcName, CompilationUnit unit) {
    for (final decl in unit.declarations) {
      if (decl is FunctionDeclaration && decl.name.lexeme == funcName) {
        for (final ann in decl.metadata) {
          if (ann.name.name.toLowerCase().contains('reactivesystem')) {
            final raw = _capitalize(funcName);
            return raw.endsWith('ReactiveSystem') ? raw : '${raw}ReactiveSystem';
          }
        }
      }
    }
    final raw = _capitalize(funcName);
    return raw.endsWith('ReactiveSystem') ? raw : '${raw}ReactiveSystem';
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
