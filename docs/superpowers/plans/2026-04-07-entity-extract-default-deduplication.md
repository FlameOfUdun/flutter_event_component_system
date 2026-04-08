# Entity Generator `_extractDefault` Deduplication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract the identically copy-pasted `_extractDefault` private method from three entity generator classes into a single free function in `_helpers.dart`.

**Architecture:** `_extractDefault` is a pure function of `TopLevelVariableElement` with no dependency on generator instance state. Promoting it to a top-level free function in `_helpers.dart` is the minimal change. All three generator classes (`ECSComponentGenerator`, `ECSDataEventGenerator`, `ECSDependencyGenerator`) then call it directly. `_helpers.dart` already imports `package:analyzer/dart/element/element.dart` from the previous refactor (Issue 1), so no new imports are needed.

**Tech Stack:** Dart, `package:analyzer` (`TopLevelVariableElement`), `package:build_test` (integration tests already exist).

---

### Task 1: Verify green baseline

**Files:**
- Test: `generator/test/ecs_generator_test.dart`

- [ ] **Step 1: Run the full test suite**

```bash
cd generator && dart test test/ecs_generator_test.dart
```

Expected: all 50 tests pass. If any fail, stop here and do not proceed.

---

### Task 2: Extract `extractDefault` into `_helpers.dart` and migrate all three generators

**Files:**
- Modify: `generator/lib/src/generators/_helpers.dart`
- Modify: `generator/lib/src/generators/entity_generator.dart`

- [ ] **Step 1: Read the current `_helpers.dart`**

File: `generator/lib/src/generators/_helpers.dart`

Confirm the file already has:
- `import 'package:analyzer/dart/element/element.dart';` (added in Issue 1 refactor)
- The 5 free functions from Issue 1 (`transformSource`, `transformStatements`, `extractBlockBody`, `extractFuncRef`, `extractNamedFuncBody`)

- [ ] **Step 2: Add `extractDefault` to `_helpers.dart`**

Append the following function to the end of `generator/lib/src/generators/_helpers.dart`:

```dart
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

- [ ] **Step 3: Read `entity_generator.dart`**

File: `generator/lib/src/generators/entity_generator.dart`

Identify the three `_extractDefault` private method definitions and their call sites:
- In `ECSComponentGenerator`: `_extractDefault` defined and called at `final defaultValue = _extractDefault(element);`
- In `ECSDataEventGenerator`: `_extractDefault` defined and called at `final defaultValue = _extractDefault(element);`
- In `ECSDependencyGenerator`: `_extractDefault` defined and called at `final defaultValue = _extractDefault(element);`

- [ ] **Step 4: Rewrite `entity_generator.dart`**

Replace the entire content of `generator/lib/src/generators/entity_generator.dart` with the following. This removes all three `_extractDefault` private methods and replaces each call with `extractDefault(element)`:

```dart
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
import '_helpers.dart';

final class ECSComponentGenerator extends GeneratorForAnnotation<ECSComponentDefinition> {
  const ECSComponentGenerator() : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! TopLevelVariableElement) {
      throw InvalidGenerationSourceError(
        '@ECSComponentDefinition can only be applied to top-level variables.',
        element: element,
      );
    }

    if (!element.isConst) {
      throw InvalidGenerationSourceError(
        '@ECSComponentDefinition variable must be const to infer a default value.',
        element: element,
      );
    }

    final varName = element.name!;
    final type = element.type.getDisplayString();
    final description = annotation.peek('description')?.stringValue;

    final className = '${capitalize(varName)}Component';
    final defaultValue = extractDefault(element);

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSComponent<$type> {');
    buffer.writeln('  $className([super.value = $defaultValue]);');
    buffer.writeln('}');
    return buffer.toString();
  }
}

final class ECSEventGenerator extends GeneratorForAnnotation<ECSEventDefinition> {
  const ECSEventGenerator() : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! TopLevelVariableElement) {
      throw InvalidGenerationSourceError(
        '@ECSEventDefinition can only be applied to top-level variables.',
        element: element,
      );
    }

    final varName = element.name!;
    final description = annotation.peek('description')?.stringValue;

    final rawName = capitalize(varName);
    final className = rawName.endsWith('Event') ? rawName : '${rawName}Event';

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSEvent {}');
    return buffer.toString();
  }
}

final class ECSDataEventGenerator extends GeneratorForAnnotation<ECSDataEventDefinition> {
  const ECSDataEventGenerator() : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! TopLevelVariableElement) {
      throw InvalidGenerationSourceError(
        '@ECSDataEventDefinition can only be applied to top-level variables.',
        element: element,
      );
    }

    if (!element.isConst) {
      throw InvalidGenerationSourceError(
        '@ECSDataEventDefinition variable must be const to infer a default value.',
        element: element,
      );
    }

    final varName = element.name!;
    final type = element.type.getDisplayString();
    final description = annotation.peek('description')?.stringValue;

    final rawName = capitalize(varName);
    final className = rawName.endsWith('Event') ? rawName : '${rawName}Event';
    final defaultValue = extractDefault(element);

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSDataEvent<$type> {');
    buffer.writeln('  @override');
    buffer.writeln('  void trigger([$type data = $defaultValue]) => super.trigger(data);');
    buffer.writeln('}');
    return buffer.toString();
  }
}

final class ECSDependencyGenerator extends GeneratorForAnnotation<ECSDependencyDefinition> {
  const ECSDependencyGenerator() : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! TopLevelVariableElement) {
      throw InvalidGenerationSourceError(
        '@ECSDependencyDefinition can only be applied to top-level variables.',
        element: element,
      );
    }

    if (!element.isConst) {
      throw InvalidGenerationSourceError(
        '@ECSDependencyDefinition variable must be const to infer a default value.',
        element: element,
      );
    }

    final varName = element.name!;
    final type = element.type.getDisplayString();
    final description = annotation.peek('description')?.stringValue;

    final className = '${capitalize(varName)}Dependency';
    final defaultValue = extractDefault(element);

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSDependency<$type> {');
    buffer.writeln('  $className([super.value = $defaultValue]);');
    buffer.writeln('}');
    return buffer.toString();
  }
}
```

- [ ] **Step 5: Run the full test suite**

```bash
cd generator && dart test test/ecs_generator_test.dart
```

Expected: all 50 tests pass.

- [ ] **Step 6: Commit**

```bash
git add generator/lib/src/generators/_helpers.dart generator/lib/src/generators/entity_generator.dart
git commit -m "refactor: extract _extractDefault as shared free function in _helpers.dart"
```

---

### Task 3: Final verification

- [ ] **Step 1: Confirm no `_extractDefault` definitions remain**

```bash
grep -n "_extractDefault" generator/lib/src/generators/entity_generator.dart
```

Expected: no output (zero matches).

- [ ] **Step 2: Run the full test suite one final time**

```bash
cd generator && dart test test/ecs_generator_test.dart --reporter expanded
```

Expected: all 50 tests pass with no failures or errors.
