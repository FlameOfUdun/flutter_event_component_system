# Cross-File Entity Resolution in Reactive System Generator

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix `_resolveEntityClassNameFromId` in `ECSReactiveSystemGenerator` so that `reactsTo` and `interactsWith` identifiers declared in other files are resolved to the correct generated class name instead of silently falling back to the bare capitalized name.

**Architecture:** `SimpleIdentifier.staticElement` contains the fully-resolved `Element` for the identifier, regardless of which file it was declared in. `TypeChecker.typeNamed(..., inPackage: ...)` — already used by `ECSFeatureGenerator` for the same purpose — can then match that element's annotations without scanning the local AST. Replace the local-AST scan in `_resolveEntityClassNameFromId` with a `staticElement` + `TypeChecker` lookup, keeping the existing local-scan as a fallback when `staticElement` is null. The four `TypeChecker` constants are added as statics on `ECSReactiveSystemGenerator`, mirroring the pattern already used in `ECSFeatureGenerator`.

**Tech Stack:** Dart, `package:source_gen` (`TypeChecker`), `package:analyzer` (`SimpleIdentifier.staticElement`), `package:build_test` (integration tests).

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

### Task 2: Write failing cross-file resolution test

The existing tests all declare `health` and `addHealth` in the same file as the system function. This task adds a test where the entities are declared in a separate source file and imported, proving the bug and then proving the fix.

**Files:**
- Modify: `generator/test/reactive_system_generator_test.dart`

- [ ] **Step 1: Read `reactive_system_generator_test.dart`**

File: `generator/test/reactive_system_generator_test.dart`

Note the `buildSources` helper and `_annotationSource` constant already defined at the top. You will add one new test to the existing `group('ReactiveSystemGenerator', ...)`.

- [ ] **Step 2: Add the cross-file test**

Add this test inside `group('ReactiveSystemGenerator', ...)` at the end, before the closing `});`:

```dart
    test('resolves reactsTo and interactsWith from imported file', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        {
          _annotationAsset: _annotationSource,
          'flutter_event_component_system_generator|lib/entities.dart': '''
            import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
            @ECSComponentDefinition() const String health = "";
            @ECSDataEventDefinition() const int addHealth = 0;
          ''',
          'flutter_event_component_system_generator|lib/input.dart': '''
            import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
            import 'entities.dart';
            part 'input.ecs.dart';

            @ECSReactiveSystemDefinition(reactsTo: {addHealth}, interactsWith: {health})
            void applyAddHealth(ECSSystemReference system) {
              final component = system.getComponent(health);
              final event = system.getDataEvent(addHealth);
              component.value += event.value;
            }
          ''',
        },
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('Set<Type> get reactsTo'),
            contains('AddHealthEvent'),
            contains('Set<Type> get interactsWith'),
            contains('HealthComponent'),
          ])),
        },
      );
    });
```

- [ ] **Step 3: Run the reactive system tests — expect this new test to FAIL**

```bash
cd generator && dart test test/reactive_system_generator_test.dart
```

Expected: 9 pass, 1 fails (the new cross-file test). The failure will show the generated output containing bare `AddHealth` and `Health` instead of `AddHealthEvent` and `HealthComponent`.

---

### Task 3: Fix `_resolveEntityClassNameFromId` to use `staticElement` + `TypeChecker`

**Files:**
- Modify: `generator/lib/src/generators/system_generator.dart`

- [ ] **Step 1: Read `system_generator.dart`**

Read the current content, focusing on `ECSReactiveSystemGenerator` (the class, from `final class ECSReactiveSystemGenerator` to its closing `}`).

- [ ] **Step 2: Add four `TypeChecker` static constants to `ECSReactiveSystemGenerator`**

Insert these four static constants immediately after the opening of the class (before `const ECSReactiveSystemGenerator()`):

```dart
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
```

- [ ] **Step 3: Replace `_resolveEntityClassNameFromId` with the element-model-based version**

Find and replace the existing `_resolveEntityClassNameFromId` method:

```dart
  // BEFORE:
  String _resolveEntityClassNameFromId(SimpleIdentifier id, CompilationUnit unit) {
    return _resolveEntityTypeName(id.name, unit);
  }
```

Replace with:

```dart
  // AFTER:
  String _resolveEntityClassNameFromId(SimpleIdentifier id, CompilationUnit unit) {
    final el = id.staticElement;
    if (el != null) {
      final raw = capitalize(id.name);
      if (_componentChecker.hasAnnotationOf(el)) return '${raw}Component';
      if (_dataEventChecker.hasAnnotationOf(el)) return '${raw}Event';
      if (_eventChecker.hasAnnotationOf(el)) return '${raw}Event';
      if (_dependencyChecker.hasAnnotationOf(el)) return '${raw}Dependency';
    }
    return _resolveEntityTypeName(id.name, unit);
  }
```

Note: `_dataEventChecker` is checked before `_eventChecker` because `ECSDataEventDefinition` is the more specific annotation and should win if somehow both matched (they won't in practice, but order matters for correctness).

- [ ] **Step 4: Run the reactive system tests — all 10 must now pass**

```bash
cd generator && dart test test/reactive_system_generator_test.dart
```

Expected: all 10 tests pass including the new cross-file test.

- [ ] **Step 5: Run the full test suite**

```bash
cd generator && dart test test/ecs_generator_test.dart
```

Expected: all 51 tests pass (50 original + 1 new).

- [ ] **Step 6: Commit**

```bash
git add generator/lib/src/generators/system_generator.dart generator/test/reactive_system_generator_test.dart
git commit -m "fix: resolve reactsTo/interactsWith entities from imported files using TypeChecker"
```

---

### Task 4: Final verification

- [ ] **Step 1: Confirm `_resolveEntityClassNameFromId` uses `staticElement`**

```bash
grep -n "staticElement" generator/lib/src/generators/system_generator.dart
```

Expected: at least one match inside `_resolveEntityClassNameFromId`.

- [ ] **Step 2: Run the full test suite**

```bash
cd generator && dart test test/ecs_generator_test.dart --reporter expanded
```

Expected: all 51 tests pass.
