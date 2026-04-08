# AST-Based System Body Transformation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the fragile regex-based `transformSource(String)` in `_helpers.dart` with an AST-visitor-based `transformStatement(Statement)` that correctly handles whitespace variation and multiline calls, and remove the redundant double-transformation in three generator call sites.

**Architecture:** The current approach calls `.toSource()` on AST nodes back to strings and then applies regex. The fix stays at the AST level: a recursive AST visitor finds every `MethodInvocation` where `target` is the identifier `system` and the method is one of the four known accessors, computes its absolute-to-relative offset within the statement's source string, and splices in the replacement — back-to-front to preserve offsets. `extractNamedFuncBody` already returns fully-transformed strings, so the three call sites that re-apply `transformSource` via `.map()` are a no-op today and can simply be removed.

**Tech Stack:** Dart, `package:analyzer` AST (`Statement`, `MethodInvocation`, `SimpleIdentifier`, `AstNode.childEntities`), existing `build_test` integration tests.

---

### Task 1: Verify green baseline

**Files:**
- Test: `generator/test/ecs_generator_test.dart`

- [ ] **Step 1: Run the full test suite**

```bash
cd generator && dart test test/ecs_generator_test.dart
```

Expected: all 50 tests pass. Stop here if any fail.

---

### Task 2: Add `transformStatement` and update `transformStatements` in `_helpers.dart`

This task replaces the regex-based `transformSource` with an AST-visitor-based `transformStatement`, updates `transformStatements` to use it, and deletes `transformSource`.

**Files:**
- Modify: `generator/lib/src/generators/_helpers.dart`

- [ ] **Step 1: Read the current `_helpers.dart`**

File: `generator/lib/src/generators/_helpers.dart`

You will rewrite its entire content.

- [ ] **Step 2: Rewrite `_helpers.dart` with the new implementation**

Replace the entire content of `generator/lib/src/generators/_helpers.dart` with:

```dart
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Rewrites all `system.getX(varName)` method invocations in [stmt] to
/// `getEntity<XClassName>()` using AST offsets. Handles any whitespace
/// formatting and multiline calls correctly.
String transformStatement(Statement stmt) {
  final source = stmt.toSource();
  final replacements = <(int start, int end, String text)>[];

  void visit(AstNode node) {
    if (node is MethodInvocation) {
      final target = node.target;
      if (target is SimpleIdentifier && target.name == 'system') {
        final method = node.methodName.name;
        final args = node.argumentList.arguments;
        if (args.length == 1 && args.first is SimpleIdentifier) {
          final argName = (args.first as SimpleIdentifier).name;
          final suffix = switch (method) {
            'getComponent' => 'Component',
            'getDataEvent' => 'Event',
            'getEvent' => 'Event',
            'getDependency' => 'Dependency',
            _ => null,
          };
          if (suffix != null) {
            final relStart = node.offset - stmt.offset;
            final relEnd = node.end - stmt.offset;
            replacements.add((relStart, relEnd, 'getEntity<${capitalize(argName)}$suffix>()'));
          }
        }
      }
    }
    for (final child in node.childEntities) {
      if (child is AstNode) visit(child);
    }
  }

  visit(stmt);

  if (replacements.isEmpty) return source;

  // Apply back-to-front so earlier offsets remain valid after each splice.
  replacements.sort((a, b) => b.$1.compareTo(a.$1));
  var result = source;
  for (final (start, end, text) in replacements) {
    result = result.substring(0, start) + text + result.substring(end);
  }
  return result;
}

/// Transforms a list of statements, indenting each by 4 spaces and
/// applying [transformStatement] to rewrite `system.getX()` calls.
String transformStatements(NodeList<Statement> stmts) {
  final buffer = StringBuffer();
  for (final stmt in stmts) {
    buffer.writeln('    ${transformStatement(stmt)}');
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

/// Returns the Dart source literal for the constant default value of [element].
/// Handles String, int, double, and bool. Returns `'null'` for other types.
String extractDefault(TopLevelVariableElement element) {
  final constant = element.computeConstantValue()!;
  final type = element.type;
  if (type.isDartCoreString) return '"${constant.toStringValue() ?? ''}"';
  if (type.isDartCoreInt) return '${constant.toIntValue() ?? 0}';
  if (type.isDartCoreDouble) return '${constant.toDoubleValue() ?? 0.0}';
  if (type.isDartCoreBool) return '${constant.toBoolValue() ?? false}';
  return 'null';
}
```

Key changes vs the previous version:
- `transformSource(String)` is **deleted** — replaced by `transformStatement(Statement)`
- `transformStatements` now calls `transformStatement(stmt)` instead of `transformSource(stmt.toSource())`
- All other functions are **identical** to before

- [ ] **Step 3: Run the full test suite — must still be green**

```bash
cd generator && dart test test/ecs_generator_test.dart
```

Expected: all 50 tests pass.

- [ ] **Step 4: Commit**

```bash
git add generator/lib/src/generators/_helpers.dart
git commit -m "refactor: replace regex transformSource with AST-visitor-based transformStatement"
```

---

### Task 3: Remove redundant `.map(transformSource)` from three generator call sites

`extractNamedFuncBody` already returns fully-transformed strings (it calls `transformStatements` internally). The three call sites in `system_generator.dart` that do `.split('\n').map(transformSource).join('\n')` after calling `extractNamedFuncBody` are redundant — they re-apply a transformation to already-transformed output. Now that `transformSource` is deleted, these must be removed.

**Files:**
- Modify: `generator/lib/src/generators/system_generator.dart`

- [ ] **Step 1: Read `system_generator.dart`** to find the three call sites

The three patterns to fix are in `ECSReactiveSystemGenerator`, `ECSCleanupSystemGenerator`, and `ECSExecuteSystemGenerator`. Each looks like:

```dart
// BEFORE (redundant double-transform):
? extractNamedFuncBody(someName, unit)
    ?.split('\n')
    .map(transformSource)
    .join('\n')
: null;
```

- [ ] **Step 2: Fix `ECSReactiveSystemGenerator`**

Find this block (around line 47–51):
```dart
    final reactsIfBody = reactsIfName != null
        ? extractNamedFuncBody(reactsIfName, unit)
            ?.split('\n')
            .map(transformSource)
            .join('\n')
        : null;
```

Replace it with:
```dart
    final reactsIfBody = reactsIfName != null
        ? extractNamedFuncBody(reactsIfName, unit)
        : null;
```

- [ ] **Step 3: Fix `ECSCleanupSystemGenerator`**

Find this block (around line 256–260):
```dart
    final cleansIfBody = cleansIfName != null
        ? extractNamedFuncBody(cleansIfName, unit)
            ?.split('\n')
            .map(transformSource)
            .join('\n')
        : null;
```

Replace it with:
```dart
    final cleansIfBody = cleansIfName != null
        ? extractNamedFuncBody(cleansIfName, unit)
        : null;
```

- [ ] **Step 4: Fix `ECSExecuteSystemGenerator`**

Find this block (around line 320–324):
```dart
    final executesIfBody = executesIfName != null
        ? extractNamedFuncBody(executesIfName, unit)
            ?.split('\n')
            .map(transformSource)
            .join('\n')
        : null;
```

Replace it with:
```dart
    final executesIfBody = executesIfName != null
        ? extractNamedFuncBody(executesIfName, unit)
        : null;
```

- [ ] **Step 5: Run the full test suite**

```bash
cd generator && dart test test/ecs_generator_test.dart
```

Expected: all 50 tests pass.

- [ ] **Step 6: Commit**

```bash
git add generator/lib/src/generators/system_generator.dart
git commit -m "refactor: remove redundant transformSource re-application on extractNamedFuncBody results"
```

---

### Task 4: Final verification

- [ ] **Step 1: Confirm `transformSource` is gone**

```bash
grep -rn "transformSource" generator/lib/
```

Expected: no output.

- [ ] **Step 2: Confirm `.map(transformSource)` is gone from all call sites**

```bash
grep -n "map(transformSource)" generator/lib/src/generators/system_generator.dart
```

Expected: no output.

- [ ] **Step 3: Run the full test suite**

```bash
cd generator && dart test test/ecs_generator_test.dart --reporter expanded
```

Expected: all 50 tests pass with no failures or errors.
