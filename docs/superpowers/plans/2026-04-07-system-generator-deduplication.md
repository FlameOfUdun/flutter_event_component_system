# System Generator Deduplication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract the five copy-pasted private methods shared across all system generators into free functions in `_helpers.dart`, eliminating all duplication in `system_generator.dart`.

**Architecture:** The five methods (`_transform`, `_transformStatements`, `_extractBody`, `_extractFuncRef`, `_extractNamedFuncBody`) have no dependency on generator instance state — they are pure functions operating on AST types. Promoting them to top-level free functions in `_helpers.dart` is the minimal change. Each system generator class then calls the free functions directly. No new abstractions, no base classes.

**Tech Stack:** Dart, `package:analyzer` (AST types: `FunctionBody`, `BlockFunctionBody`, `NodeList`, `Statement`, `FunctionDeclaration`, `CompilationUnit`), `package:source_gen` (`InvalidGenerationSourceError`), `package:build_test` (integration tests already exist).

---

### Task 1: Verify all existing tests pass before touching anything

**Files:**
- Test: `generator/test/ecs_generator_test.dart` (entry point for all generator tests)

- [ ] **Step 1: Run the full test suite**

```bash
cd generator && dart test test/ecs_generator_test.dart
```

Expected: all tests pass (green). If any fail, stop and fix them before proceeding. Do not continue with a red baseline.

---

### Task 2: Extract `transformSource` free function into `_helpers.dart`

This is the `_transform` method duplicated across all five system generator classes. It rewrites `system.getX(varName)` calls in raw source strings to `getEntity<XClassName>()` calls.

**Files:**
- Modify: `generator/lib/src/generators/_helpers.dart`

- [ ] **Step 1: Read the current content of `_helpers.dart`**

Current content (for reference — do not re-read):
```dart
String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
```

- [ ] **Step 2: Add the `transformSource` free function**

Append to `generator/lib/src/generators/_helpers.dart`:

```dart
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Rewrites `system.getX(varName)` calls in a raw source string to
/// the generated `getEntity<XClassName>()` form.
String transformSource(String source) {
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

/// Transforms a list of statements, indenting each by 4 spaces and
/// applying [transformSource] to each statement's source text.
String transformStatements(NodeList<Statement> stmts) {
  final buffer = StringBuffer();
  for (final stmt in stmts) {
    buffer.writeln('    ${transformSource(stmt.toSource())}');
  }
  return buffer.toString();
}

/// Validates that [body] is a block body and returns [transformStatements]
/// applied to its statements. Throws [InvalidGenerationSourceError] otherwise.
String extractBlockBody(FunctionBody body, Element element) {
  if (body is! BlockFunctionBody) {
    throw InvalidGenerationSourceError(
      'System function must use a block body {}. Expression bodies => are not supported.',
      element: element,
    );
  }
  return transformStatements(body.block.statements);
}

/// Returns the name of the top-level function referenced by the named
/// annotation parameter [param], or null if absent.
String? extractFuncRef(FunctionDeclaration funcDecl, String param) {
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

/// Finds a top-level function named [name] in [unit] and returns the
/// transformed body text, or null if not found.
String? extractNamedFuncBody(String name, CompilationUnit unit) {
  for (final decl in unit.declarations) {
    if (decl is FunctionDeclaration && decl.name.lexeme == name) {
      final body = decl.functionExpression.body;
      if (body is BlockFunctionBody) {
        return transformStatements(body.block.statements);
      }
    }
  }
  return null;
}
```

- [ ] **Step 3: Run the test suite — should still be all green (no generator code changed yet)**

```bash
cd generator && dart test test/ecs_generator_test.dart
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add generator/lib/src/generators/_helpers.dart
git commit -m "refactor: extract shared system generator helpers as free functions"
```

---

### Task 3: Migrate `ECSReactiveSystemGenerator` to use free functions

**Files:**
- Modify: `generator/lib/src/generators/system_generator.dart`

- [ ] **Step 1: Replace the five private methods in `ECSReactiveSystemGenerator` with calls to the free functions**

In `system_generator.dart`, the class `ECSReactiveSystemGenerator` (lines 8–197) has these private methods to remove:
- `_extractBody` (line ~128)
- `_extractNamedFuncBody` (line ~138)
- `_transformStatements` (line ~150)
- `_transform` (line ~158)
- `_extractFuncRef` (line ~115)

And update the call sites inside `generateForAnnotatedElement`:

```dart
// Change this:
final reactBody = _extractBody(astNode.functionExpression.body, element);
final reactsIfBody = reactsIfName != null
    ? _extractNamedFuncBody(reactsIfName, unit)
        ?.split('\n')
        .map(_transform)
        .join('\n')
    : null;

// To this:
final reactBody = extractBlockBody(astNode.functionExpression.body, element);
final reactsIfBody = reactsIfName != null
    ? extractNamedFuncBody(reactsIfName, unit)
        ?.split('\n')
        .map(transformSource)
        .join('\n')
    : null;
```

Also update the call to `_extractFuncRef`:
```dart
// Change this:
final reactsIfName = _extractFuncRef(astNode, 'reactsIf');
// To this:
final reactsIfName = extractFuncRef(astNode, 'reactsIf');
```

Then **delete** the five private method definitions from `ECSReactiveSystemGenerator`.

The full updated `ECSReactiveSystemGenerator` class (everything from line 8 to the closing `}` of the class at line 197) should look like:

```dart
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
```

- [ ] **Step 2: Run reactive system tests**

```bash
cd generator && dart test test/reactive_system_generator_test.dart
```

Expected: all tests pass.

- [ ] **Step 3: Commit**

```bash
git add generator/lib/src/generators/system_generator.dart
git commit -m "refactor: migrate ECSReactiveSystemGenerator to shared helper functions"
```

---

### Task 4: Migrate `ECSInitializeSystemGenerator` to use free functions

**Files:**
- Modify: `generator/lib/src/generators/system_generator.dart`

- [ ] **Step 1: Replace private methods in `ECSInitializeSystemGenerator` with free function calls**

`ECSInitializeSystemGenerator` (lines ~199–281) has three private methods to remove: `_extractBody`, `_transformStatements`, `_transform`.

The full updated class:

```dart
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
```

- [ ] **Step 2: Run initialize system tests**

```bash
cd generator && dart test test/initialize_system_generator_test.dart
```

Expected: all tests pass.

- [ ] **Step 3: Commit**

```bash
git add generator/lib/src/generators/system_generator.dart
git commit -m "refactor: migrate ECSInitializeSystemGenerator to shared helper functions"
```

---

### Task 5: Migrate `ECSTeardownSystemGenerator` to use free functions

**Files:**
- Modify: `generator/lib/src/generators/system_generator.dart`

- [ ] **Step 1: Replace private methods in `ECSTeardownSystemGenerator` with free function calls**

`ECSTeardownSystemGenerator` (lines ~283–365) has the same three methods to remove.

The full updated class:

```dart
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
```

- [ ] **Step 2: Run teardown system tests**

```bash
cd generator && dart test test/teardown_system_generator_test.dart
```

Expected: all tests pass.

- [ ] **Step 3: Commit**

```bash
git add generator/lib/src/generators/system_generator.dart
git commit -m "refactor: migrate ECSTeardownSystemGenerator to shared helper functions"
```

---

### Task 6: Migrate `ECSCleanupSystemGenerator` to use free functions

**Files:**
- Modify: `generator/lib/src/generators/system_generator.dart`

- [ ] **Step 1: Replace private methods in `ECSCleanupSystemGenerator` with free function calls**

`ECSCleanupSystemGenerator` (lines ~367–491) has all five methods to remove. Update call sites:
- `_extractFuncRef(astNode, 'cleansIf')` → `extractFuncRef(astNode, 'cleansIf')`
- `_extractNamedFuncBody(cleansIfName, unit)?.split('\n').map(_transform).join('\n')` → `extractNamedFuncBody(cleansIfName, unit)?.split('\n').map(transformSource).join('\n')`
- `_extractBody(astNode.functionExpression.body, element)` → `extractBlockBody(astNode.functionExpression.body, element)`

The full updated class:

```dart
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
            ?.split('\n')
            .map(transformSource)
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
}
```

- [ ] **Step 2: Run cleanup system tests**

```bash
cd generator && dart test test/cleanup_system_generator_test.dart
```

Expected: all tests pass.

- [ ] **Step 3: Commit**

```bash
git add generator/lib/src/generators/system_generator.dart
git commit -m "refactor: migrate ECSCleanupSystemGenerator to shared helper functions"
```

---

### Task 7: Migrate `ECSExecuteSystemGenerator` to use free functions

**Files:**
- Modify: `generator/lib/src/generators/system_generator.dart`

- [ ] **Step 1: Replace private methods in `ECSExecuteSystemGenerator` with free function calls**

`ECSExecuteSystemGenerator` (lines ~493–617) has all five methods to remove. Update call sites:
- `_extractFuncRef(astNode, 'executesIf')` → `extractFuncRef(astNode, 'executesIf')`
- `_extractNamedFuncBody(executesIfName, unit)?.split('\n').map(_transform).join('\n')` → `extractNamedFuncBody(executesIfName, unit)?.split('\n').map(transformSource).join('\n')`
- `_extractBody(astNode.functionExpression.body, element)` → `extractBlockBody(astNode.functionExpression.body, element)`

The full updated class:

```dart
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
            ?.split('\n')
            .map(transformSource)
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
}
```

- [ ] **Step 2: Run execute system tests**

```bash
cd generator && dart test test/execute_system_generator_test.dart
```

Expected: all tests pass.

- [ ] **Step 3: Run the full test suite to confirm nothing regressed**

```bash
cd generator && dart test test/ecs_generator_test.dart
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add generator/lib/src/generators/system_generator.dart
git commit -m "refactor: migrate ECSExecuteSystemGenerator to shared helper functions"
```

---

### Task 8: Final verification

**Files:**
- No changes — verification only.

- [ ] **Step 1: Confirm `system_generator.dart` no longer contains any `_transform`, `_transformStatements`, `_extractBody`, `_extractFuncRef`, or `_extractNamedFuncBody` definitions**

```bash
grep -n "_transform\|_transformStatements\|_extractBody\|_extractFuncRef\|_extractNamedFuncBody" generator/lib/src/generators/system_generator.dart
```

Expected: no output (zero matches).

- [ ] **Step 2: Run the full test suite one final time**

```bash
cd generator && dart test test/ecs_generator_test.dart --reporter expanded
```

Expected: all tests pass with no failures or errors.
