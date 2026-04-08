# `extractDefault` Non-Primitive Type Error Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the silent `return 'null'` fallback in `extractDefault` with an `InvalidGenerationSourceError` that gives the user a clear build-time error when they annotate a non-primitive const variable.

**Architecture:** `extractDefault` in `_helpers.dart` already receives a `TopLevelVariableElement`, which is an `Element` — sufficient to construct `InvalidGenerationSourceError`. No signature change needed; just replace the final `return 'null'` with a throw. The three call sites in `entity_generator.dart` (`ECSComponentGenerator`, `ECSDataEventGenerator`, `ECSDependencyGenerator`) are unaffected — they already require `isConst` before calling `extractDefault`, so the new throw is the natural next guard. Add a test first (TDD).

**Tech Stack:** Dart, `package:source_gen` (`InvalidGenerationSourceError`), `package:build_test` (integration tests — errors from `InvalidGenerationSourceError` appear as SEVERE log entries captured via `onLog`).

---

### Task 1: Verify green baseline

**Files:**
- Test: `generator/test/ecs_generator_test.dart`

- [ ] **Step 1: Run the full test suite**

```bash
cd generator && dart test test/ecs_generator_test.dart
```

Expected: all 51 tests pass. Stop if any fail.

---

### Task 2: Write failing test for non-primitive default

**Files:**
- Modify: `generator/test/component_generator_test.dart`

- [ ] **Step 1: Read `component_generator_test.dart`**

File: `generator/test/component_generator_test.dart`

Locate the end of `group('ComponentGenerator', ...)` — you will add one test before the closing `});`.

- [ ] **Step 2: Add the failing test**

Add this test inside `group('ComponentGenerator', ...)`, immediately before the closing `});`:

```dart
    test('throws for non-primitive const type', () async {
      final logs = <String>[];
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@ECSComponentDefinition() const items = [1, 2, 3];'),
        outputs: {},
        onLog: (record) => logs.add(record.message),
      );
      expect(
        logs.any((m) => m.contains('Only primitive types')),
        isTrue,
        reason: 'Expected a build error for non-primitive const type',
      );
    });
```

- [ ] **Step 3: Run component tests — the new test must FAIL**

```bash
cd generator && dart test test/component_generator_test.dart
```

Expected: 4 pass, 1 fails. The failure will show `logs` is empty or doesn't contain `'Only primitive types'` — because currently `extractDefault` silently returns `'null'` instead of throwing.

---

### Task 3: Fix `extractDefault` to throw for non-primitive types

**Files:**
- Modify: `generator/lib/src/generators/_helpers.dart`

- [ ] **Step 1: Read `_helpers.dart`**

Read `generator/lib/src/generators/_helpers.dart` and locate `extractDefault` at the bottom of the file.

Current implementation:

```dart
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

- [ ] **Step 2: Replace the final `return 'null'` with a throw**

Edit only the `extractDefault` function. Replace it with:

```dart
/// Returns the Dart source literal for the constant default value of [element].
/// Handles String, int, double, and bool.
/// Throws [InvalidGenerationSourceError] for any other type.
String extractDefault(TopLevelVariableElement element) {
  final constant = element.computeConstantValue()!;
  final type = element.type;
  if (type.isDartCoreString) return '"${constant.toStringValue() ?? ''}"';
  if (type.isDartCoreInt) return '${constant.toIntValue() ?? 0}';
  if (type.isDartCoreDouble) return '${constant.toDoubleValue() ?? 0.0}';
  if (type.isDartCoreBool) return '${constant.toBoolValue() ?? false}';
  throw InvalidGenerationSourceError(
    'Only primitive types (String, int, double, bool) are supported as default values. '
    'Found: ${type.getDisplayString()}',
    element: element,
  );
}
```

The only change is the last line: `return 'null'` → `throw InvalidGenerationSourceError(...)`. The doc comment is also updated to reflect the new behaviour.

- [ ] **Step 3: Run component tests — all 5 must now pass**

```bash
cd generator && dart test test/component_generator_test.dart
```

Expected: all 5 tests pass.

- [ ] **Step 4: Run the full test suite**

```bash
cd generator && dart test test/ecs_generator_test.dart
```

Expected: all 52 tests pass (51 previous + 1 new).

- [ ] **Step 5: Commit**

```bash
git add generator/lib/src/generators/_helpers.dart generator/test/component_generator_test.dart
git commit -m "fix: throw InvalidGenerationSourceError for non-primitive types in extractDefault"
```

---

### Task 4: Final verification

- [ ] **Step 1: Confirm `return 'null'` is gone from `extractDefault`**

```bash
grep -n "return 'null'" generator/lib/src/generators/_helpers.dart
```

Expected: no output.

- [ ] **Step 2: Run the full test suite**

```bash
cd generator && dart test test/ecs_generator_test.dart --reporter expanded
```

Expected: all 52 tests pass.
