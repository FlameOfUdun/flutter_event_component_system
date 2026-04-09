# CleanupSystem cleansIf Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an optional `cleansIf` parameter to `@CleanupSystem` that, when provided as a function reference, inlines the function's body as a `bool get cleansIf { ... }` getter override on the generated cleanup system class.

**Architecture:** Mirrors `reactsIf` on `ReactiveSystem` and `executesIf` on `ExecuteSystem`. A function reference stored in the annotation is resolved at build time via `buildStep.resolver.astNodeFor`, its body is transformed using `transformDslStatements(stmts, ctx, rewriteReads: true)` (reads rewritten to `getEntity<X>().value`), and emitted as a `bool get cleansIf` override. The condition function takes no parameters (same as `CleanupSystem` itself).

**Tech Stack:** Dart, `source_gen`, `build_runner`, `analyzer` AST, `build_test`

---

## File Map

| File | Change |
|---|---|
| `annotations/lib/src/annotations/system_annotation.dart` | Add `Function? cleansIf` to `CleanupSystem` |
| `generator/test/cleanup_system_generator_test.dart` | Update annotation stub + add 2 tests |
| `generator/lib/src/generators/system_generator.dart` | Add `_resolveCleansIfBody` + emit getter |

---

### Task 1: Add failing tests

**Files:**
- Modify: `generator/test/cleanup_system_generator_test.dart`

- [ ] **Step 1: Update the annotation stub** (`_annotationSource` constant in the test file)

  Find this line in `_annotationSource`:
  ```dart
  final class CleanupSystem { final String? description; const CleanupSystem({this.description}); }
  ```
  Replace with:
  ```dart
  final class CleanupSystem { final String? description; final Function? cleansIf; const CleanupSystem({this.description, this.cleansIf}); }
  ```

- [ ] **Step 2: Add the two new tests** inside the `CleanupSystemGenerator` group, after the existing test:

  ```dart
    test('generates cleansIf getter when cleansIf is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int loginProcess = 0;

          bool shouldCleanupLogin() {
            return loginProcess != 0;
          }

          @CleanupSystem(cleansIf: shouldCleanupLogin)
          void cleanupLogin() {
            loginProcess = 0;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('bool get cleansIf'),
            contains('getEntity<LoginProcessComponent>().value'),
          ])),
        },
      );
    });

    test('does not generate cleansIf getter when cleansIf is not provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int loginProcess = 0;

          @CleanupSystem()
          void cleanupLogin() {
            loginProcess = 0;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(isNot(contains('bool get cleansIf'))),
        },
      );
    });
  ```

- [ ] **Step 3: Run the new tests to confirm they fail**

  ```bash
  cd generator && dart test test/cleanup_system_generator_test.dart --name "cleansIf"
  ```

  Expected: both fail (annotation field missing, getter not emitted yet).

- [ ] **Step 4: Commit the failing tests**

  ```bash
  git add generator/test/cleanup_system_generator_test.dart
  git commit -m "test: add failing tests for CleanupSystem cleansIf"
  ```

---

### Task 2: Add `cleansIf` to the annotation

**Files:**
- Modify: `annotations/lib/src/annotations/system_annotation.dart`

- [ ] **Step 1: Add the field**

  Find:
  ```dart
  /// Marks a top-level function as a cleanup system.
  final class CleanupSystem {
    final String? description;
    const CleanupSystem({this.description});
  }
  ```

  Replace with:
  ```dart
  /// Marks a top-level function as a cleanup system.
  /// `cleansIf` is an optional reference to a no-parameter `bool` function;
  /// if provided, its body is inlined as the `bool get cleansIf` getter override.
  final class CleanupSystem {
    final String? description;
    final Function? cleansIf;
    const CleanupSystem({this.description, this.cleansIf});
  }
  ```

- [ ] **Step 2: Run all tests to confirm nothing broke**

  ```bash
  cd generator && dart test test/ecs_generator_test.dart
  ```

  Expected: all existing tests still pass.

- [ ] **Step 3: Commit**

  ```bash
  git add annotations/lib/src/annotations/system_annotation.dart
  git commit -m "feat: add cleansIf field to CleanupSystem annotation"
  ```

---

### Task 3: Implement `cleansIf` in `CleanupSystemGenerator`

**Files:**
- Modify: `generator/lib/src/generators/system_generator.dart`

The `CleanupSystemGenerator.generateForAnnotatedElement` method currently ends with (relevant excerpt):

```dart
final transformed = transformDslStatements(body.block.statements, ctx);
final privateHelpers = collectPrivateHelpers(body.block.statements, unit);

final buffer = StringBuffer();
if (description != null) buffer.writeln('/// $description');
buffer.writeln('final class $className extends ECSCleanupSystem {');
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
```

- [ ] **Step 1: Add `_resolveCleansIfBody` call** — add this line after `collectPrivateHelpers`:

  ```dart
  final cleansIfBody = await _resolveCleansIfBody(annotation, buildStep, ctx);
  ```

- [ ] **Step 2: Emit the `cleansIf` getter** — add between the class opening and the `void cleanup` override:

  ```dart
  if (cleansIfBody != null) {
    buffer.writeln('  @override');
    buffer.writeln('  bool get cleansIf {');
    buffer.write(cleansIfBody);
    buffer.writeln('  }');
    buffer.writeln();
  }
  ```

  The full buffer-building section becomes:
  ```dart
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
  ```

- [ ] **Step 3: Add the `_resolveCleansIfBody` private method** to `CleanupSystemGenerator`:

  ```dart
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
  ```

- [ ] **Step 4: Run the new tests**

  ```bash
  cd generator && dart test test/cleanup_system_generator_test.dart --name "cleansIf"
  ```

  Expected: both pass.

- [ ] **Step 5: Run the full test suite**

  ```bash
  cd generator && dart test test/ecs_generator_test.dart
  ```

  Expected: all 42 tests pass (40 existing + 2 new).

  > **Note:** The 40 count assumes the `executesIf` plan has already been implemented. If running this plan first, expect 40 total (38 existing + 2 new).

- [ ] **Step 6: Commit**

  ```bash
  git add generator/lib/src/generators/system_generator.dart
  git commit -m "feat: add cleansIf support to @CleanupSystem annotation"
  ```

---

## Self-Review Checklist

- [x] Spec coverage: annotation field, generator implementation, and tests are all covered
- [x] No placeholders: all steps show exact code
- [x] Type consistency: `cleansIfBody` (String?) used consistently; `_resolveCleansIfBody` signature matches usage
- [x] No params: `CleanupSystem` takes no parameters — the condition function is also no-param, so no param replacement needed
- [x] `rewriteReads: true`: used so component reads inside condition are properly rewritten
- [x] Annotation stub in test file updated to include `cleansIf`
- [x] Test assertions are whitespace-tolerant (no single-line expression assertions that could be broken by dart format)
