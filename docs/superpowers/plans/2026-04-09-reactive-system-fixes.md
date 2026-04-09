# Reactive System Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix two bugs in the ECS generator: (1) private helper methods lose their `async`/`async*`/`sync*` modifier when emitted; (2) `ReactiveSystem` has no `reactsIf` support — add it as an optional `Function?` param that the generator reads from the annotation and inlines as a `bool get reactsIf` getter.

**Architecture:** Task 1 is a one-line fix in `_helpers.dart::emitPrivateMethod`. Task 2 spans the annotations package (add field), generator (read annotation, resolve AST, transform body, emit getter), and tests. Both tasks are independent but small enough to do sequentially and commit together.

**Tech Stack:** Dart, `package:analyzer` (`BlockFunctionBody.keyword`, `BlockFunctionBody.star`, `DartObject.toFunctionValue()`, `ExecutableElement`), `package:source_gen` (`ConstantReader`), `package:build_test`.

---

## File Map

| File | Action |
|------|--------|
| `generator/lib/src/generators/_helpers.dart` | Fix `emitPrivateMethod` — add async modifier to emitted signature |
| `annotations/lib/src/annotations/system_annotation.dart` | Add `Function? reactsIf` to `ReactiveSystem` |
| `generator/lib/src/generators/system_generator.dart` | Read `reactsIf` from annotation, resolve AST, emit `bool get reactsIf` getter |
| `generator/test/reactive_system_generator_test.dart` | Add `reactsIf` test; update async private helper test |

---

## Task 1: Fix `async` modifier in emitted private methods

**Files:**
- Modify: `generator/lib/src/generators/_helpers.dart` (function `emitPrivateMethod`, currently line ~299)
- Modify: `generator/test/reactive_system_generator_test.dart`

### Step 1: Write a failing test

Add this test to the `ReactiveSystemGenerator` group in `generator/test/reactive_system_generator_test.dart`:

```dart
    test('async private helpers preserve async modifier', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int loginProcess = 0;
          @Event() void login(int id) { loginSystem(id); }

          @ReactiveSystem()
          void loginSystem(int id) {
            _doLogin(id).ignore();
          }

          Future<void> _doLogin(int id) async {
            await Future.delayed(const Duration(seconds: 1));
            loginProcess = id;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(contains('Future<void> _doLogin(int id) async {')),
        },
      );
    });
```

- [ ] **Step 1a: Add the test** to `generator/test/reactive_system_generator_test.dart` inside the `ReactiveSystemGenerator` group, after the existing private helper tests.

- [ ] **Step 1b: Run to confirm it fails**

```bash
cd generator && dart test test/reactive_system_generator_test.dart --name "async private helpers" 2>&1 | tail -10
```

Expected: FAIL — emitted method is `Future<void> _doLogin(int id) {` (no `async`).

### Step 2: Fix `emitPrivateMethod` in `_helpers.dart`

Current code (around line 296–302):
```dart
      if (body is BlockFunctionBody) {
        final transformed = transformDslStatements(body.block.statements, ctx);
        final buffer = StringBuffer();
        buffer.writeln('  $returnType $name$params {');
        buffer.write(transformed);
        buffer.writeln('  }');
        return buffer.toString();
      }
```

- [ ] **Step 2a: Replace that block** with:

```dart
      if (body is BlockFunctionBody) {
        final transformed = transformDslStatements(body.block.statements, ctx);
        final modifier = '${body.keyword?.lexeme ?? ''}${body.star?.lexeme ?? ''}';
        final asyncStr = modifier.isNotEmpty ? ' $modifier' : '';
        final buffer = StringBuffer();
        buffer.writeln('  $returnType $name$params$asyncStr {');
        buffer.write(transformed);
        buffer.writeln('  }');
        return buffer.toString();
      }
```

`BlockFunctionBody.keyword` holds the `async` or `sync` token; `BlockFunctionBody.star` holds `*` for `async*`/`sync*`. Concatenating both reconstructs any modifier correctly:
- `async {}` → keyword=`async`, star=null → `" async"`
- `async* {}` → keyword=`async`, star=`*` → `" async*"`
- `sync* {}` → keyword=`sync`, star=`*` → `" sync*"`
- regular `{}` → both null → `""`

- [ ] **Step 2b: Run the new test — must pass**

```bash
cd generator && dart test test/reactive_system_generator_test.dart --name "async private helpers" 2>&1 | tail -5
```

Expected: PASS.

- [ ] **Step 2c: Run the full test suite — all must still pass**

```bash
cd generator && dart test test/ecs_generator_test.dart 2>&1 | tail -5
```

Expected: all 36 tests pass.

- [ ] **Step 2d: Commit**

```bash
cd generator && git add -A && git commit -m "fix: preserve async/sync* modifier in emitted private methods"
```

---

## Task 2: Add `reactsIf` to `@ReactiveSystem`

**Files:**
- Modify: `annotations/lib/src/annotations/system_annotation.dart`
- Modify: `generator/lib/src/generators/system_generator.dart`
- Modify: `generator/test/reactive_system_generator_test.dart`

### Step 1: Write failing tests

Add these two tests to the `ReactiveSystemGenerator` group in `generator/test/reactive_system_generator_test.dart`:

```dart
    test('generates reactsIf getter when reactsIf is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) { applyAddHealth(amount); }

          bool applyAddHealthIf(int amount) {
            return health + amount <= 100;
          }

          @ReactiveSystem(reactsIf: applyAddHealthIf)
          void applyAddHealth(int amount) {
            health += amount;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('bool get reactsIf'),
            contains('getEntity<HealthComponent>().value + getEntity<AddHealthEvent>().data <= 100'),
          ])),
        },
      );
    });

    test('does not generate reactsIf getter when reactsIf is not provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Event() void logout() { logoutSystem(); }

          @ReactiveSystem()
          void logoutSystem() {}
        '''),
        outputs: {
          _outputKey: decodedMatches(isNot(contains('bool get reactsIf'))),
        },
      );
    });
```

- [ ] **Step 1a: Add both tests** to `generator/test/reactive_system_generator_test.dart` inside the `ReactiveSystemGenerator` group.

- [ ] **Step 1b: Run to confirm they fail**

```bash
cd generator && dart test test/reactive_system_generator_test.dart --name "reactsIf" 2>&1 | tail -10
```

Expected: FAIL — first test gets a compile error because `ReactiveSystem` has no `reactsIf` param yet.

### Step 2: Add `reactsIf` to the `ReactiveSystem` annotation

- [ ] **Step 2a: Update `annotations/lib/src/annotations/system_annotation.dart`**

Replace the `ReactiveSystem` class with:

```dart
/// Marks a top-level function as a reactive system.
/// `reactsTo` is auto-detected from the @Event function bodies that call this system.
/// `interactsWith` is auto-detected from writes in the body and its private helpers.
/// `reactsIf` is an optional reference to a `bool` function with the same parameters
/// as the system; if provided, its body is inlined as the `bool get reactsIf` getter.
final class ReactiveSystem {
  final String? description;
  final Function? reactsIf;
  const ReactiveSystem({this.description, this.reactsIf});
}
```

The other 4 system annotation classes (`InitializeSystem`, `TeardownSystem`, `CleanupSystem`, `ExecuteSystem`) are unchanged.

### Step 3: Implement `reactsIf` in `ReactiveSystemGenerator`

The generator already produces the class body in `generateForAnnotatedElement`. Add `reactsIf` handling **after** `interactsWith` and **before** `void react()`.

- [ ] **Step 3a: In `generator/lib/src/generators/system_generator.dart`**, update `ReactiveSystemGenerator.generateForAnnotatedElement`.

After the line:
```dart
    final reactBody = transformDslStatements(body.block.statements, ctx);
    final interactsWith = detectInteractsWith(body.block.statements, unit, ctx);
    final privateHelpers = collectPrivateHelpers(body.block.statements, unit);
```

Add:
```dart
    // Resolve reactsIf condition function from annotation if provided.
    final reactsIfBody = await _resolveReactsIfBody(annotation, buildStep, ctx);
```

Then in the buffer-building section, insert the `reactsIf` getter **between** `interactsWith` and `react()`:

```dart
    if (interactsWith.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('  @override');
      buffer.writeln('  Set<Type> get interactsWith {');
      buffer.writeln('    return const {${interactsWith.join(', ')}};');
      buffer.writeln('  }');
    }

    // NEW: emit reactsIf getter if condition function was provided.
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
```

- [ ] **Step 3b: Add the private `_resolveReactsIfBody` method** to `ReactiveSystemGenerator`:

```dart
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

    return transformDslStatements(body.block.statements, ctx);
  }
```

**How it works:**
- `annotation.peek('reactsIf')` returns null if the param was omitted → method returns null → no getter emitted.
- `reactsIfReader.objectValue.toFunctionValue()` extracts the `ExecutableElement` for the referenced function.
- `buildStep.resolver.astNodeFor(funcElement.firstFragment, resolve: true)` retrieves the function's parsed AST.
- `transformDslStatements` applies the same `ctx` (including param replacements) to the condition body — so `health + amount <= 100` becomes `getEntity<HealthComponent>().value + getEntity<AddHealthEvent>().data <= 100`.

### Step 4: Run tests and fix

- [ ] **Step 4a: Run the two new `reactsIf` tests**

```bash
cd generator && dart test test/reactive_system_generator_test.dart --name "reactsIf" 2>&1 | tail -10
```

Expected: both pass. If not, common failures:
- `toFunctionValue()` returns null for top-level functions → try `reactsIfReader.objectValue.toFunctionValue()` vs checking the DartObject type — top-level functions resolve fine via this path.
- `astNodeFor` returns something other than `FunctionDeclaration` → check the fragment type; for `TopLevelFunctionElement` use `element.firstFragment`.

- [ ] **Step 4b: Run the full test suite**

```bash
cd generator && dart test test/ecs_generator_test.dart 2>&1 | tail -5
```

Expected: all 38 tests pass (36 existing + 2 new).

- [ ] **Step 4c: Commit**

```bash
cd generator && git add -A && git commit -m "feat: add reactsIf support to @ReactiveSystem annotation"
```
