# Explicit reactsTo on @ReactiveSystem Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace auto-detection of `reactsTo` (scanning `@Event` function bodies) with an explicit `List<Function>? reactsTo` annotation parameter on `@ReactiveSystem`, enabling cross-library event references.

**Architecture:** Add `List<Function>? reactsTo` to the `ReactiveSystem` annotation. In `ReactiveSystemGenerator`, replace `_detectReactsTo` (AST scan of event bodies in the same compilation unit) with `_readReactsTo` (reads the annotation's list value, resolves each function reference via `toFunctionValue()`, derives event class name via `toPascalCase(name) + 'Event'`). Event functions become empty-body declarations. The `_buildParamReplacements` logic is unchanged — it still uses the resolved `reactsToClasses` list to inject event data into system parameters.

**Tech Stack:** Dart, `source_gen`, `build_runner`, `analyzer` AST, `build_test`

---

## File Map

| File | Change |
|---|---|
| `annotations/lib/src/annotations/system_annotation.dart` | Add `List<Function>? reactsTo` to `ReactiveSystem` |
| `generator/test/reactive_system_generator_test.dart` | Update annotation stub; replace auto-detection tests; add explicit `reactsTo` tests |
| `generator/lib/src/generators/system_generator.dart` | Replace `_detectReactsTo`+`_stmtCallsFunction` with `_readReactsTo`; wire up in `generateForAnnotatedElement` |

---

### Task 1: Add `List<Function>? reactsTo` to the annotation

**Files:**
- Modify: `annotations/lib/src/annotations/system_annotation.dart`

- [ ] **Step 1: Add the field**

  Find:
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

  Replace with:
  ```dart
  /// Marks a top-level function as a reactive system.
  /// `reactsTo` is a list of `@Event`-annotated function references this system reacts to.
  ///   Cross-library events are supported. Pass as a list literal: `reactsTo: [myEvent]`.
  /// `interactsWith` is auto-detected from writes in the body and its private helpers.
  /// `reactsIf` is an optional reference to a `bool` function with the same parameters
  /// as the system; if provided, its body is inlined as the `bool get reactsIf` getter.
  final class ReactiveSystem {
    final String? description;
    final List<Function>? reactsTo;
    final Function? reactsIf;
    const ReactiveSystem({this.description, this.reactsTo, this.reactsIf});
  }
  ```

- [ ] **Step 2: Run existing tests (expect failures — that's fine for now)**

  ```bash
  cd generator && dart test test/ecs_generator_test.dart 2>&1 | tail -5
  ```

  Expected: existing tests still pass (annotation change is additive — no existing test passes `reactsTo` yet).

- [ ] **Step 3: Commit**

  ```bash
  git add annotations/lib/src/annotations/system_annotation.dart
  git commit -m "feat: add reactsTo field to ReactiveSystem annotation"
  ```

---

### Task 2: Write failing tests for explicit `reactsTo`

**Files:**
- Modify: `generator/test/reactive_system_generator_test.dart`

- [ ] **Step 1: Update the annotation stub** — add `reactsTo` to `ReactiveSystem` in `_annotationSource`:

  Find:
  ```dart
  final class ReactiveSystem { final String? description; final Function? reactsIf; const ReactiveSystem({this.description, this.reactsIf}); }
  ```
  Replace with:
  ```dart
  final class ReactiveSystem { final String? description; final List<Function>? reactsTo; final Function? reactsIf; const ReactiveSystem({this.description, this.reactsTo, this.reactsIf}); }
  ```

- [ ] **Step 2: Add two new tests** inside the `ReactiveSystemGenerator` group, after the existing tests:

  ```dart
    test('uses explicit reactsTo to populate reactsTo set', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) {}

          @ReactiveSystem(reactsTo: [addHealth])
          void applyAddHealth(int amount) {
            health += amount;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('Set<Type> get reactsTo'),
            contains('AddHealthEvent'),
            contains('getEntity<AddHealthEvent>().data'),
          ])),
        },
      );
    });

    test('supports multiple events in reactsTo', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) {}
          @Event() void healFull() {}

          @ReactiveSystem(reactsTo: [addHealth, healFull])
          void applyHeal(int amount) {
            health += amount;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('AddHealthEvent'),
            contains('HealFullEvent'),
          ])),
        },
      );
    });
  ```

- [ ] **Step 3: Run only the new tests to confirm they fail**

  ```bash
  cd generator && dart test test/reactive_system_generator_test.dart --name "explicit reactsTo|multiple events" 2>&1 | tail -8
  ```

  Expected: both fail (`AddHealthEvent` not found in output, since `reactsTo` list is not yet read by the generator).

- [ ] **Step 4: Commit**

  ```bash
  git add generator/test/reactive_system_generator_test.dart
  git commit -m "test: add failing tests for explicit ReactiveSystem reactsTo"
  ```

---

### Task 3: Implement `_readReactsTo`, remove auto-detection

**Files:**
- Modify: `generator/lib/src/generators/system_generator.dart`

The current `generateForAnnotatedElement` in `ReactiveSystemGenerator` contains:
```dart
final reactsToClasses = _detectReactsTo(funcName, unit, baseCtx);
```

And the class has two private methods that must be removed: `_detectReactsTo` and `_stmtCallsFunction`.

- [ ] **Step 1: Replace the `_detectReactsTo` call**

  Find:
  ```dart
  final reactsToClasses = _detectReactsTo(funcName, unit, baseCtx);
  ```
  Replace with:
  ```dart
  final reactsToClasses = await _readReactsTo(annotation);
  ```

- [ ] **Step 2: Remove `_detectReactsTo` and `_stmtCallsFunction`**

  Delete these two methods entirely from `ReactiveSystemGenerator`:

  ```dart
  List<String> _detectReactsTo(
    String systemFuncName,
    CompilationUnit unit,
    DslContext ctx,
  ) {
    ...
  }

  bool _stmtCallsFunction(Statement stmt, String funcName) {
    ...
  }
  ```

- [ ] **Step 3: Add `_readReactsTo` method** to `ReactiveSystemGenerator`, before `_buildParamReplacements`:

  ```dart
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
  ```

  > **Note:** This works cross-library because it derives the event class name directly from the function's name — it does NOT need the function to be present in `ctx.events`. The naming convention (`toPascalCase(name) + 'Event'`) is the same one used by `EventGenerator`.

- [ ] **Step 4: Run only the two new tests to confirm they now pass**

  ```bash
  cd generator && dart test test/reactive_system_generator_test.dart --name "explicit reactsTo|multiple events" 2>&1 | tail -5
  ```

  Expected: both pass.

- [ ] **Step 5: Commit**

  ```bash
  git add generator/lib/src/generators/system_generator.dart
  git commit -m "feat: implement explicit reactsTo in ReactiveSystemGenerator"
  ```

---

### Task 4: Update all existing tests to use explicit `reactsTo`

**Files:**
- Modify: `generator/test/reactive_system_generator_test.dart`

All tests that currently rely on auto-detection (event body calling the system) must be updated. Event functions become empty-body declarations. Each `@ReactiveSystem()` that has a parameter must have `reactsTo: [eventFunc]`.

Auto-detection is now gone — tests with event bodies that called systems will no longer produce `reactsTo` results.

- [ ] **Step 1: Rewrite each affected test** — find and replace the full test bodies as shown below.

  **Test: 'auto-detects reactsTo from @Event function body'** → rename and rewrite:
  ```dart
    test('explicit reactsTo populates reactsTo set (same library)', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) {}

          @ReactiveSystem(reactsTo: [addHealth])
          void applyAddHealth(int amount) {
            health += amount;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class ApplyAddHealthReactiveSystem extends ECSReactiveSystem'),
            contains('Set<Type> get reactsTo'),
            contains('AddHealthEvent'),
          ])),
        },
      );
    });
  ```

  **Test: 'auto-detects interactsWith from writes in body'** → keep the assertion, add explicit `reactsTo`:
  ```dart
    test('auto-detects interactsWith from writes in body', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) {}

          @ReactiveSystem(reactsTo: [addHealth])
          void applyAddHealth(int amount) {
            health += amount;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('Set<Type> get interactsWith'),
            contains('HealthComponent'),
          ])),
        },
      );
    });
  ```

  **Test: 'rewrites component write in react body'** → add explicit `reactsTo`:
  ```dart
    test('rewrites component write in react body', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) {}

          @ReactiveSystem(reactsTo: [addHealth])
          void applyAddHealth(int amount) {
            health += amount;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(
            contains('getEntity<HealthComponent>().value += '),
          ),
        },
      );
    });
  ```

  **Test: 'injects event data replacing system parameter'** → add explicit `reactsTo`:
  ```dart
    test('injects event data replacing system parameter', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) {}

          @ReactiveSystem(reactsTo: [addHealth])
          void applyAddHealth(int amount) {
            health += amount;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('getEntity<AddHealthEvent>().data'),
            isNot(contains('void react(int amount)')),
          ])),
        },
      );
    });
  ```

  **Test: 'handles no-data reactive system with no parameter'** → add explicit `reactsTo`:
  ```dart
    test('handles no-data reactive system with no parameter', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 100;
          @Event() void logout() {}

          @ReactiveSystem(reactsTo: [logout])
          void logoutSystem() {
            health = 0;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('LogoutEvent'),
            contains('getEntity<HealthComponent>().value = 0'),
          ])),
        },
      );
    });
  ```

  **Test: 'private helpers become private methods on generated class'** → add explicit `reactsTo`:
  ```dart
    test('private helpers become private methods on generated class', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) {}

          @ReactiveSystem(reactsTo: [addHealth])
          void applyAddHealth(int amount) {
            _doApply(amount);
          }

          void _doApply(int amount) {
            health += amount;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('void _doApply('),
            contains('getEntity<HealthComponent>().value'),
          ])),
        },
      );
    });
  ```

  **Test: 'private helper writes are included in interactsWith'** → add explicit `reactsTo`:
  ```dart
    test('private helper writes are included in interactsWith', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) {}

          @ReactiveSystem(reactsTo: [addHealth])
          void applyAddHealth(int amount) {
            _doApply(amount);
          }

          void _doApply(int amount) {
            health += amount;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(contains('HealthComponent')),
        },
      );
    });
  ```

  **Test: 'reads are NOT included in interactsWith'** → add explicit `reactsTo`:
  ```dart
    test('reads are NOT included in interactsWith', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Component() int maxHealth = 100;
          @Event() void checkHealth() {}

          @ReactiveSystem(reactsTo: [checkHealth])
          void checkSystem() {
            if (health < maxHealth) {}
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(
            isNot(contains('Set<Type> get interactsWith')),
          ),
        },
      );
    });
  ```

  **Test: 'includes doc comment when description is provided'** → add explicit `reactsTo`:
  ```dart
    test('includes doc comment when description is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Event() void logout() {}

          @ReactiveSystem(description: "Handles logout", reactsTo: [logout])
          void logoutSystem() {}
        '''),
        outputs: {
          _outputKey: decodedMatches(contains('/// Handles logout')),
        },
      );
    });
  ```

  **Test: 'generates reactsIf getter when reactsIf is provided'** → add explicit `reactsTo`, empty event body:
  ```dart
    test('generates reactsIf getter when reactsIf is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) {}

          bool applyAddHealthIf(int amount) {
            return health + amount <= 100;
          }

          @ReactiveSystem(reactsTo: [addHealth], reactsIf: applyAddHealthIf)
          void applyAddHealth(int amount) {
            health += amount;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('bool get reactsIf'),
            contains('getEntity<HealthComponent>().value'),
            contains('getEntity<AddHealthEvent>().data'),
          ])),
        },
      );
    });
  ```

  **Test: 'does not generate reactsIf getter when reactsIf is not provided'** → empty event body:
  ```dart
    test('does not generate reactsIf getter when reactsIf is not provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Event() void logout() {}

          @ReactiveSystem(reactsTo: [logout])
          void logoutSystem() {}
        '''),
        outputs: {
          _outputKey: decodedMatches(isNot(contains('bool get reactsIf'))),
        },
      );
    });
  ```

  **Test: 'async private helpers preserve async modifier'** → add explicit `reactsTo`, empty event body:
  ```dart
    test('async private helpers preserve async modifier', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int loginProcess = 0;
          @Event() void login(int id) {}

          @ReactiveSystem(reactsTo: [login])
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

- [ ] **Step 2: Run full suite**

  ```bash
  cd generator && dart test test/ecs_generator_test.dart 2>&1 | tail -5
  ```

  Expected: all 44 tests pass (42 existing + 2 new from Task 2).

- [ ] **Step 3: Commit**

  ```bash
  git add generator/test/reactive_system_generator_test.dart
  git commit -m "refactor: migrate all reactsTo tests to explicit annotation"
  ```

---

## Self-Review Checklist

- [x] All 4 tasks covered: annotation field, failing tests, generator implementation, test migration
- [x] No placeholders: every test and code block is fully written out
- [x] Type consistency: `List<Function>? reactsTo` in annotation, `listValue` + `toFunctionValue()` in generator, `toPascalCase(name) + 'Event'` naming consistent with `EventGenerator`
- [x] `_buildParamReplacements` unchanged — still receives `reactsToClasses` list (now from annotation instead of auto-detection)
- [x] Cross-library: `_readReactsTo` derives class name from function reference directly, not from `ctx.events` — works for imported functions
- [x] Auto-detection methods `_detectReactsTo` and `_stmtCallsFunction` fully removed in Task 3
- [x] Task ordering: annotation field first (additive, no breakage) → new tests (fail) → implementation (new tests pass) → existing tests updated
- [x] `Future<List<String>> _readReactsTo` is `async` — `generateForAnnotatedElement` is already `async`, so `await _readReactsTo(annotation)` compiles correctly
