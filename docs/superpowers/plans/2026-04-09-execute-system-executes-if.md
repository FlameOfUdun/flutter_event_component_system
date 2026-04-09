# ExecuteSystem executesIf Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an optional `executesIf` parameter to `@ExecuteSystem` that, when provided as a function reference, inlines the function's body as a `bool get executesIf { ... }` getter override on the generated execute system class.

**Architecture:** Mirrors `reactsIf` on `ReactiveSystem`. A function reference stored in the annotation is resolved at build time via `buildStep.resolver.astNodeFor`, its body is transformed using `transformDslStatements(stmts, ctx, rewriteReads: true)` (reads rewritten to `getEntity<X>().value`), and emitted as a `bool get executesIf` override. The `elapsed` parameter is NOT replaced — it is a real `Duration` param passed through unchanged.

**Tech Stack:** Dart, `source_gen`, `build_runner`, `analyzer` AST, `build_test`

---

## File Map

| File | Change |
|---|---|
| `annotations/lib/src/annotations/system_annotation.dart` | Add `Function? executesIf` to `ExecuteSystem` |
| `generator/test/execute_system_generator_test.dart` | Update annotation stub + add 2 tests |
| `generator/lib/src/generators/system_generator.dart` | Add `_resolveExecutesIfBody` + emit getter |

---

### Task 1: Add failing tests

**Files:**
- Modify: `generator/test/execute_system_generator_test.dart`

- [ ] **Step 1: Update the annotation stub** (`_annotationSource` constant in the test file)

  Find this line in `_annotationSource`:
  ```dart
  final class ExecuteSystem { final String? description; const ExecuteSystem({this.description}); }
  ```
  Replace with:
  ```dart
  final class ExecuteSystem { final String? description; final Function? executesIf; const ExecuteSystem({this.description, this.executesIf}); }
  ```

- [ ] **Step 2: Add the two new tests** inside the `ExecuteSystemGenerator` group, after the existing tests:

  ```dart
    test('generates executesIf getter when executesIf is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int timerValue = 0;

          bool shouldUpdateTimer(Duration elapsed) {
            return timerValue < 1000;
          }

          @ExecuteSystem(executesIf: shouldUpdateTimer)
          void updateTimer(Duration elapsed) {
            timerValue += elapsed.inMilliseconds;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('bool get executesIf'),
            contains('getEntity<TimerValueComponent>().value'),
            contains('elapsed'),
          ])),
        },
      );
    });

    test('does not generate executesIf getter when executesIf is not provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int timerValue = 0;

          @ExecuteSystem()
          void updateTimer(Duration elapsed) {
            timerValue += elapsed.inMilliseconds;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(isNot(contains('bool get executesIf'))),
        },
      );
    });
  ```

- [ ] **Step 3: Run the new tests to confirm they fail**

  ```bash
  cd generator && dart test test/execute_system_generator_test.dart --name "executesIf"
  ```

  Expected: both fail (annotation field missing, getter not emitted yet).

- [ ] **Step 4: Commit the failing tests**

  ```bash
  git add generator/test/execute_system_generator_test.dart
  git commit -m "test: add failing tests for ExecuteSystem executesIf"
  ```

---

### Task 2: Add `executesIf` to the annotation

**Files:**
- Modify: `annotations/lib/src/annotations/system_annotation.dart`

- [ ] **Step 1: Add the field**

  Find:
  ```dart
  /// Marks a top-level function as an execute system.
  /// The function must accept a single `Duration elapsed` parameter.
  final class ExecuteSystem {
    final String? description;
    const ExecuteSystem({this.description});
  }
  ```

  Replace with:
  ```dart
  /// Marks a top-level function as an execute system.
  /// The function must accept a single `Duration elapsed` parameter.
  /// `executesIf` is an optional reference to a `bool` function with the same
  /// `Duration elapsed` parameter; if provided, its body is inlined as the
  /// `bool get executesIf` getter override.
  final class ExecuteSystem {
    final String? description;
    final Function? executesIf;
    const ExecuteSystem({this.description, this.executesIf});
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
  git commit -m "feat: add executesIf field to ExecuteSystem annotation"
  ```

---

### Task 3: Implement `executesIf` in `ExecuteSystemGenerator`

**Files:**
- Modify: `generator/lib/src/generators/system_generator.dart`

The `ExecuteSystemGenerator.generateForAnnotatedElement` method currently looks like this (relevant excerpt):

```dart
// `elapsed` is a real Duration parameter — do NOT replace it. No paramReplacements.
final transformed = transformDslStatements(body.block.statements, ctx);
final interactsWith = detectInteractsWith(body.block.statements, unit, ctx);
final privateHelpers = collectPrivateHelpers(body.block.statements, unit);

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

buffer.writeln('  @override');
buffer.writeln('  void execute(Duration elapsed) {');
buffer.write(transformed);
buffer.writeln('  }');
```

- [ ] **Step 1: Add `_resolveExecutesIfBody` call** — add this line after `collectPrivateHelpers`:

  ```dart
  final executesIfBody = await _resolveExecutesIfBody(annotation, buildStep, ctx);
  ```

- [ ] **Step 2: Emit the `executesIf` getter** — add between the `interactsWith` block and the `void execute` override:

  ```dart
  if (executesIfBody != null) {
    buffer.writeln('  @override');
    buffer.writeln('  bool get executesIf {');
    buffer.write(executesIfBody);
    buffer.writeln('  }');
    buffer.writeln();
  }
  ```

- [ ] **Step 3: Add the `_resolveExecutesIfBody` private method** to `ExecuteSystemGenerator`:

  ```dart
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
  ```

  > **Note:** `elapsed` is a `Duration` parameter — it is NOT in `ctx.paramReplacements` and NOT in `ctx.components`, so it passes through the transform unchanged. Only component/dependency reads (e.g. `timerValue`) are rewritten to `getEntity<TimerValueComponent>().value`.

- [ ] **Step 4: Run the new tests**

  ```bash
  cd generator && dart test test/execute_system_generator_test.dart --name "executesIf"
  ```

  Expected: both pass.

- [ ] **Step 5: Run the full test suite**

  ```bash
  cd generator && dart test test/ecs_generator_test.dart
  ```

  Expected: all 40 tests pass (38 existing + 2 new).

- [ ] **Step 6: Commit**

  ```bash
  git add generator/lib/src/generators/system_generator.dart
  git commit -m "feat: add executesIf support to @ExecuteSystem annotation"
  ```

---

## Self-Review Checklist

- [x] Spec coverage: annotation field, generator implementation, and tests are all covered
- [x] No placeholders: all steps show exact code
- [x] Type consistency: `executesIfBody` (String?) used consistently; `_resolveExecutesIfBody` signature matches usage
- [x] `elapsed` param: correctly passes through without replacement (not in `paramReplacements`, not a component)
- [x] `rewriteReads: true`: used so component reads inside condition are properly rewritten
- [x] Annotation stub in test file updated to include `executesIf`
- [x] Test assertions are whitespace-tolerant (no single-line expression assertions that could be broken by dart format)
