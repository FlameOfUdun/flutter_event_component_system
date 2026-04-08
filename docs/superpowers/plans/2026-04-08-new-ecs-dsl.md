# New ECS DSL Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the annotation-heavy const-variable DSL with a natural Dart DSL where `@Component`/`@Dependency` are typed variables, `@Event` is a void function, and system bodies are plain code with auto-detected `reactsTo` and `interactsWith`.

**Architecture:** This is a full breaking rewrite in 6 sequential tasks. Tasks 1–2 set up the new annotations and build infrastructure. Tasks 3–5 rewrite each generator group with TDD (write failing tests first, then implement). Task 6 updates the example files. Every task except Task 1 should leave the test suite fully green before committing.

**Tech Stack:** Dart, `package:source_gen` (`GeneratorForAnnotation`, `Generator`, `PartBuilder`, `TypeChecker`, `InvalidGenerationSourceError`), `package:analyzer` (AST visitor, `AssignmentExpression`, `MethodInvocation`, `SimpleIdentifier`), `package:build_test` (integration tests).

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `annotations/lib/src/annotations/entity_annotation.dart` | Rewrite | `Component`, `Event`, `Dependency` |
| `annotations/lib/src/annotations/system_annotation.dart` | Rewrite | 5 system annotations, remove all reference stubs |
| `annotations/lib/src/annotations/feature_annotation.dart` | Delete | No longer needed |
| `annotations/lib/flutter_event_component_system_annotations.dart` | Update | Remove feature_annotation export |
| `generator/build.yaml` | Update | Change `.ecs.dart` → `.ecs.g.dart` |
| `generator/lib/flutter_event_component_system_generator.dart` | Rewrite | New builder factory with new generators |
| `generator/lib/src/generators/_helpers.dart` | Rewrite | New DSL body transformer replaces old `transformStatement` |
| `generator/lib/src/generators/entity_generator.dart` | Rewrite | `ComponentGenerator`, `EventGenerator`, `DependencyGenerator` |
| `generator/lib/src/generators/system_generator.dart` | Rewrite | 5 system generators with auto-detection |
| `generator/lib/src/generators/feature_generator.dart` | Rewrite | Filename-based `Generator` (not `GeneratorForAnnotation`) |
| `generator/test/component_generator_test.dart` | Rewrite | New annotation stubs and new DSL test cases |
| `generator/test/event_generator_test.dart` | Rewrite | New DSL event tests |
| `generator/test/dependency_generator_test.dart` | Rewrite | New DSL dependency tests |
| `generator/test/reactive_system_generator_test.dart` | Rewrite | Auto-detection tests |
| `generator/test/initialize_system_generator_test.dart` | Rewrite | New DSL tests |
| `generator/test/teardown_system_generator_test.dart` | Rewrite | New DSL tests |
| `generator/test/cleanup_system_generator_test.dart` | Rewrite | New DSL tests |
| `generator/test/execute_system_generator_test.dart` | Rewrite | New DSL tests |
| `generator/test/feature_generator_test.dart` | Rewrite | Filename-derived class name tests |
| `generator/test/ecs_generator_test.dart` | Rewrite | Update test suite entry point |
| `example/lib/features/**/*.dart` | Update | Rewrite to new DSL |

---

## Shared test infrastructure (used in all generator tests)

Every test file uses this `_annotationSource` and `buildSources` helper. They are **duplicated** across all test files (follow the existing pattern — do NOT extract a shared file).

**New `_annotationSource`** (replace the old one in every test file):

```dart
const _annotationAsset =
    'flutter_event_component_system_annotations|lib/flutter_event_component_system_annotations.dart';

const _annotationSource = '''
  final class Component {
    final String? description;
    const Component({this.description});
  }
  final class Event {
    final String? description;
    const Event({this.description});
  }
  final class Dependency {
    final String? description;
    const Dependency({this.description});
  }
  final class ReactiveSystem {
    final String? description;
    const ReactiveSystem({this.description});
  }
  final class InitializeSystem {
    final String? description;
    const InitializeSystem({this.description});
  }
  final class TeardownSystem {
    final String? description;
    const TeardownSystem({this.description});
  }
  final class CleanupSystem {
    final String? description;
    const CleanupSystem({this.description});
  }
  final class ExecuteSystem {
    final String? description;
    const ExecuteSystem({this.description});
  }
''';
```

**New output key** (part extension changed):
```dart
const _outputKey =
    'flutter_event_component_system_generator|lib/input.ecs.g.dart';
```

**New `buildSources` helper** (part directive updated):
```dart
Map<String, String> buildSources(String body) {
  return {
    _annotationAsset: _annotationSource,
    'flutter_event_component_system_generator|lib/input.dart': '''
        import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
        part 'input.ecs.g.dart';
        $body
      ''',
  };
}
```

---

## Task 1: Rewrite annotations package

**Files:**
- Rewrite: `annotations/lib/src/annotations/entity_annotation.dart`
- Rewrite: `annotations/lib/src/annotations/system_annotation.dart`
- Delete: `annotations/lib/src/annotations/feature_annotation.dart`
- Modify: `annotations/lib/flutter_event_component_system_annotations.dart`

> **Note:** After this task, the generator package will fail to compile because it still references old class names. This is expected — do NOT run tests yet.

- [ ] **Step 1: Rewrite `entity_annotation.dart`**

Replace the entire file with:

```dart
/// Marks a top-level variable as an ECS component.
/// The variable's type is the component's value type.
/// The variable's initializer is the default value.
final class Component {
  final String? description;
  const Component({this.description});
}

/// Marks a top-level variable as an ECS dependency.
/// The variable's type is the dependency's value type.
/// The variable's initializer is the default value.
final class Dependency {
  final String? description;
  const Dependency({this.description});
}

/// Marks a top-level void function as an ECS event.
/// - Zero parameters → no-data event (ECSEvent)
/// - One parameter → data event (ECSDataEvent<T>) where T is the parameter type
/// The function body lists the systems that react to this event (declaration only).
final class Event {
  final String? description;
  const Event({this.description});
}
```

- [ ] **Step 2: Rewrite `system_annotation.dart`**

Replace the entire file with:

```dart
/// Marks a top-level function as a reactive system.
/// `reactsTo` is auto-detected from the @Event function bodies that call this system.
/// `interactsWith` is auto-detected from writes in the body and its private helpers.
final class ReactiveSystem {
  final String? description;
  const ReactiveSystem({this.description});
}

/// Marks a top-level function as an initialize system.
final class InitializeSystem {
  final String? description;
  const InitializeSystem({this.description});
}

/// Marks a top-level function as a teardown system.
final class TeardownSystem {
  final String? description;
  const TeardownSystem({this.description});
}

/// Marks a top-level function as a cleanup system.
final class CleanupSystem {
  final String? description;
  const CleanupSystem({this.description});
}

/// Marks a top-level function as an execute system.
/// The function must accept a single `Duration elapsed` parameter.
final class ExecuteSystem {
  final String? description;
  const ExecuteSystem({this.description});
}
```

- [ ] **Step 3: Delete `feature_annotation.dart`**

Delete the file `annotations/lib/src/annotations/feature_annotation.dart` — it is no longer needed.

- [ ] **Step 4: Update the library export file**

Replace `annotations/lib/flutter_event_component_system_annotations.dart` with:

```dart
library;

export 'src/annotations/entity_annotation.dart';
export 'src/annotations/system_annotation.dart';
```

---

## Task 2: Update build infrastructure

**Files:**
- Modify: `generator/build.yaml`
- Rewrite: `generator/lib/flutter_event_component_system_generator.dart`

After this task the generator still won't compile (old generator files reference old classes). That is expected — keep going.

- [ ] **Step 1: Update `build.yaml`**

Replace the entire `build.yaml` with:

```yaml
builders:
  ecs_builder:
    import: "package:flutter_event_component_system_generator/flutter_event_component_system_generator.dart"
    builder_factories: ["ecsBuilder"]
    build_extensions: {".dart": [".ecs.g.dart"]}
    auto_apply: dependents
    build_to: source
```

- [ ] **Step 2: Update the builder factory**

Replace `generator/lib/flutter_event_component_system_generator.dart` with:

```dart
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generators/entity_generator.dart';
import 'src/generators/feature_generator.dart';
import 'src/generators/system_generator.dart';

Builder ecsBuilder(BuilderOptions options) {
  final generators = [
    const ComponentGenerator(),
    const EventGenerator(),
    const DependencyGenerator(),
    const ReactiveSystemGenerator(),
    const InitializeSystemGenerator(),
    const TeardownSystemGenerator(),
    const CleanupSystemGenerator(),
    const ExecuteSystemGenerator(),
    const FeatureGenerator(),
  ];
  return PartBuilder(generators, '.ecs.g.dart');
}
```

---

## Task 3: Rewrite `_helpers.dart` and entity generators

**Files:**
- Rewrite: `generator/lib/src/generators/_helpers.dart`
- Rewrite: `generator/lib/src/generators/entity_generator.dart`
- Rewrite: `generator/test/component_generator_test.dart`
- Rewrite: `generator/test/event_generator_test.dart`
- Rewrite: `generator/test/dependency_generator_test.dart`

The `_helpers.dart` file provides all shared utilities. We replace the old `transformStatement` (which handled `system.getX()` calls) with a new `DslRewriter` that handles the new DSL's component reads/writes and event calls.

### Step 1: Write failing tests first

- [ ] **Step 1a: Rewrite `component_generator_test.dart`**

```dart
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:flutter_event_component_system_generator/flutter_event_component_system_generator.dart';

const _outputKey =
    'flutter_event_component_system_generator|lib/input.ecs.g.dart';
const _annotationAsset =
    'flutter_event_component_system_annotations|lib/flutter_event_component_system_annotations.dart';
const _annotationSource = '''
  final class Component {
    final String? description;
    const Component({this.description});
  }
  final class Event {
    final String? description;
    const Event({this.description});
  }
  final class Dependency {
    final String? description;
    const Dependency({this.description});
  }
  final class ReactiveSystem {
    final String? description;
    const ReactiveSystem({this.description});
  }
  final class InitializeSystem {
    final String? description;
    const InitializeSystem({this.description});
  }
  final class TeardownSystem {
    final String? description;
    const TeardownSystem({this.description});
  }
  final class CleanupSystem {
    final String? description;
    const CleanupSystem({this.description});
  }
  final class ExecuteSystem {
    final String? description;
    const ExecuteSystem({this.description});
  }
''';

Map<String, String> buildSources(String body) {
  return {
    _annotationAsset: _annotationSource,
    'flutter_event_component_system_generator|lib/input.dart': '''
        import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
        part 'input.ecs.g.dart';
        $body
      ''',
  };
}

void main() {
  group('ComponentGenerator', () {
    test('generates component class for int variable', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@Component() int health = 0;'),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class HealthComponent extends ECSComponent<int>'),
            contains('HealthComponent([super.value = 0])'),
          ])),
        },
      );
    });

    test('generates component class for String variable', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@Component() String playerName = "";'),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class PlayerNameComponent extends ECSComponent<String>'),
            contains('PlayerNameComponent([super.value = ""])'),
          ])),
        },
      );
    });

    test('generates component class for enum-typed variable', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          enum AuthState { unknown, loggedIn }
          @Component() AuthState authState = AuthState.unknown;
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class AuthStateComponent extends ECSComponent<AuthState>'),
            contains('AuthStateComponent([super.value = AuthState.unknown])'),
          ])),
        },
      );
    });

    test('includes doc comment when description is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@Component(description: "Player health") int health = 0;'),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('/// Player health'),
            contains('final class HealthComponent'),
          ])),
        },
      );
    });

    test('throws error for variable without initializer', () async {
      final logs = <String>[];
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@Component() int health;'),
        onLog: (r) => logs.add(r.message),
      );
      expect(
        logs.any((m) => m.contains('must have an initializer')),
        isTrue,
        reason: 'Expected a build error for missing initializer',
      );
    });
  });
}
```

- [ ] **Step 1b: Rewrite `event_generator_test.dart`**

```dart
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:flutter_event_component_system_generator/flutter_event_component_system_generator.dart';

const _outputKey =
    'flutter_event_component_system_generator|lib/input.ecs.g.dart';
const _annotationAsset =
    'flutter_event_component_system_annotations|lib/flutter_event_component_system_annotations.dart';
const _annotationSource = '''
  final class Component { final String? description; const Component({this.description}); }
  final class Event { final String? description; const Event({this.description}); }
  final class Dependency { final String? description; const Dependency({this.description}); }
  final class ReactiveSystem { final String? description; const ReactiveSystem({this.description}); }
  final class InitializeSystem { final String? description; const InitializeSystem({this.description}); }
  final class TeardownSystem { final String? description; const TeardownSystem({this.description}); }
  final class CleanupSystem { final String? description; const CleanupSystem({this.description}); }
  final class ExecuteSystem { final String? description; const ExecuteSystem({this.description}); }
''';

Map<String, String> buildSources(String body) {
  return {
    _annotationAsset: _annotationSource,
    'flutter_event_component_system_generator|lib/input.dart': '''
        import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
        part 'input.ecs.g.dart';
        $body
      ''',
  };
}

void main() {
  group('EventGenerator', () {
    test('generates no-data event from zero-parameter void function', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@Event() void logout() {}'),
        outputs: {
          _outputKey: decodedMatches(contains(
            'final class LogoutEvent extends ECSEvent {}',
          )),
        },
      );
    });

    test('generates data event from one-parameter void function', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          class LoginCredentials {}
          @Event() void login(LoginCredentials credentials) {}
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class LoginEvent extends ECSDataEvent<LoginCredentials>'),
            contains('void trigger(LoginCredentials data)'),
          ])),
        },
      );
    });

    test('generates data event with int type', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@Event() void addHealth(int amount) {}'),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class AddHealthEvent extends ECSDataEvent<int>'),
            contains('void trigger([int data = 0])'),
          ])),
        },
      );
    });

    test('includes doc comment when description is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@Event(description: "User logged out") void logout() {}'),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('/// User logged out'),
            contains('final class LogoutEvent'),
          ])),
        },
      );
    });

    test('throws for multi-parameter event function', () async {
      final logs = <String>[];
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('@Event() void login(String user, String pass) {}'),
        onLog: (r) => logs.add(r.message),
      );
      expect(
        logs.any((m) => m.contains('zero or one parameter')),
        isTrue,
        reason: 'Expected build error for multi-parameter event',
      );
    });
  });
}
```

- [ ] **Step 1c: Rewrite `dependency_generator_test.dart`**

```dart
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:flutter_event_component_system_generator/flutter_event_component_system_generator.dart';

const _outputKey =
    'flutter_event_component_system_generator|lib/input.ecs.g.dart';
const _annotationAsset =
    'flutter_event_component_system_annotations|lib/flutter_event_component_system_annotations.dart';
const _annotationSource = '''
  final class Component { final String? description; const Component({this.description}); }
  final class Event { final String? description; const Event({this.description}); }
  final class Dependency { final String? description; const Dependency({this.description}); }
  final class ReactiveSystem { final String? description; const ReactiveSystem({this.description}); }
  final class InitializeSystem { final String? description; const InitializeSystem({this.description}); }
  final class TeardownSystem { final String? description; const TeardownSystem({this.description}); }
  final class CleanupSystem { final String? description; const CleanupSystem({this.description}); }
  final class ExecuteSystem { final String? description; const ExecuteSystem({this.description}); }
''';

Map<String, String> buildSources(String body) {
  return {
    _annotationAsset: _annotationSource,
    'flutter_event_component_system_generator|lib/input.dart': '''
        import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
        part 'input.ecs.g.dart';
        $body
      ''',
  };
}

void main() {
  group('DependencyGenerator', () {
    test('generates dependency class for typed variable', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          class AuthRepository {}
          @Dependency() AuthRepository authRepo = AuthRepository();
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class AuthRepoDependency extends ECSDependency<AuthRepository>'),
            contains('AuthRepoDependency([super.value = AuthRepository()])'),
          ])),
        },
      );
    });

    test('includes doc comment when description is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          class AuthRepository {}
          @Dependency(description: "Auth repo") AuthRepository authRepo = AuthRepository();
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('/// Auth repo'),
            contains('final class AuthRepoDependency'),
          ])),
        },
      );
    });
  });
}
```

- [ ] **Step 1d: Run component, event, dependency tests — all must FAIL**

```bash
cd generator && dart test test/component_generator_test.dart test/event_generator_test.dart test/dependency_generator_test.dart
```

Expected: compile errors or test failures (generators still use old class names).

### Step 2: Rewrite `_helpers.dart`

- [ ] **Step 2a: Rewrite `generator/lib/src/generators/_helpers.dart`**

Replace the entire file with:

```dart
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Converts a snake_case or lower_camel_case filename stem to PascalCase.
/// e.g. "timer_feature" → "TimerFeature", "userAuth" → "UserAuth"
String toPascalCase(String stem) {
  if (stem.contains('_')) {
    return stem.split('_').map(capitalize).join();
  }
  return capitalize(stem);
}

/// Holds the rewriting maps for a single source file.
/// Built once per generator invocation and shared across all body rewrites.
class DslContext {
  /// varName → generated component class name, e.g. "health" → "HealthComponent"
  final Map<String, String> components;
  /// funcName → generated event class name, e.g. "logout" → "LogoutEvent"
  final Map<String, String> events;
  /// varName → generated dependency class name, e.g. "authRepo" → "AuthRepoDependency"
  final Map<String, String> dependencies;
  /// paramName → replacement expression, e.g. "credentials" → "getEntity<LoginEvent>().data"
  final Map<String, String> paramReplacements;

  const DslContext({
    this.components = const {},
    this.events = const {},
    this.dependencies = const {},
    this.paramReplacements = const {},
  });

  DslContext withParamReplacements(Map<String, String> replacements) {
    return DslContext(
      components: components,
      events: events,
      dependencies: dependencies,
      paramReplacements: {...paramReplacements, ...replacements},
    );
  }
}

/// Collects all `@Component`-annotated variable names and maps them to their
/// generated class names. Resolves via element annotation checking.
///
/// This uses the [LibraryReader]-equivalent element scan: pass the list of
/// annotated [AnnotatedElement]s that the generator collected.
Map<String, String> buildComponentMap(
  Iterable<String> componentVarNames,
) {
  return {
    for (final name in componentVarNames)
      name: '${capitalize(name)}Component',
  };
}

Map<String, String> buildEventMap(Iterable<String> eventFuncNames) {
  return {
    for (final name in eventFuncNames) name: '${capitalize(name)}Event',
  };
}

Map<String, String> buildDependencyMap(Iterable<String> depVarNames) {
  return {
    for (final name in depVarNames)
      name: '${capitalize(name)}Dependency',
  };
}

/// Transforms a single statement using offset-based replacement.
/// Handles:
///   - Reads of annotated vars: `health` → `getEntity<HealthComponent>().value`
///   - Writes to annotated vars: `health = x` → `getEntity<HealthComponent>().value = x`
///   - Compound writes: `health += x` → `getEntity<HealthComponent>().value += x`
///   - No-data event calls: `logout()` → `getEntity<LogoutEvent>().trigger()`
///   - Data event calls: `login(creds)` → `getEntity<LoginEvent>().trigger(creds)`
///   - Param replacements: `credentials` → `getEntity<LoginEvent>().data`
String transformDslStatement(Statement stmt, DslContext ctx) {
  final source = stmt.toSource();
  final replacements = <(int start, int end, String text)>[];
  final assignmentLeftEnds = <int>{}; // end offsets of assignment left-hand sides

  // First pass: collect assignment left-hand side ranges so reads on lhs
  // are handled as .value assignments rather than .value reads.
  void collectAssignments(AstNode node) {
    if (node is AssignmentExpression) {
      final lhs = node.leftHandSide;
      assignmentLeftEnds.add(lhs.end);
    }
    for (final child in node.childEntities) {
      if (child is AstNode) collectAssignments(child);
    }
  }

  collectAssignments(stmt);

  // Second pass: collect replacements.
  void visit(AstNode node) {
    // Handle assignment expressions: rewrite lhs identifier only.
    if (node is AssignmentExpression) {
      final lhs = node.leftHandSide;
      if (lhs is SimpleIdentifier) {
        final name = lhs.name;
        final className = ctx.components[name] ?? ctx.dependencies[name];
        if (className != null) {
          final relStart = lhs.offset - stmt.offset;
          final relEnd = lhs.end - stmt.offset;
          replacements.add((relStart, relEnd, 'getEntity<$className>().value'));
        }
      }
      // Still visit the rhs.
      visit(node.rightHandSide);
      return;
    }

    // Handle no-target method invocations: event calls like logout() or login(creds).
    if (node is MethodInvocation && node.target == null) {
      final name = node.methodName.name;
      final className = ctx.events[name];
      if (className != null) {
        final args = node.argumentList.arguments;
        final relStart = node.offset - stmt.offset;
        final relEnd = node.end - stmt.offset;
        if (args.isEmpty) {
          replacements.add((relStart, relEnd, 'getEntity<$className>().trigger()'));
        } else {
          // Transform each argument, then rebuild the call.
          // We do NOT recurse into args here — we let the identifier visitor below
          // handle inner reads within arguments.
          final argSources = args.map((a) => transformDslStatement(
                ExpressionStatement2(a, stmt.offset),
                ctx,
              ) ?? a.toSource()).toList();
          // Fall through: we replace args inline. Actually simpler approach:
          // replace only the method name + target part, keep the argument list
          // but apply ctx transforms to the args individually.
          // Simplest: replace entire invocation.
          final transformedArgs = args.map((a) => _transformExpr(a, stmt.offset, ctx)).join(', ');
          replacements.add((relStart, relEnd, 'getEntity<$className>().trigger($transformedArgs)'));
        }
        return;
      }
    }

    // Handle simple identifier reads (not on lhs of assignment, not a method name).
    if (node is SimpleIdentifier) {
      final name = node.name;
      // Skip if this identifier is itself the method name of an invocation.
      if (node.parent is MethodInvocation &&
          (node.parent as MethodInvocation).methodName == node) {
        for (final child in node.childEntities) {
          if (child is AstNode) visit(child);
        }
        return;
      }
      // Param replacement (event data) — highest priority.
      final paramReplacement = ctx.paramReplacements[name];
      if (paramReplacement != null) {
        final relStart = node.offset - stmt.offset;
        final relEnd = node.end - stmt.offset;
        replacements.add((relStart, relEnd, paramReplacement));
        return;
      }
      // Component / dependency read.
      final className = ctx.components[name] ?? ctx.dependencies[name];
      if (className != null) {
        final relStart = node.offset - stmt.offset;
        final relEnd = node.end - stmt.offset;
        replacements.add((relStart, relEnd, 'getEntity<$className>().value'));
        return;
      }
    }

    for (final child in node.childEntities) {
      if (child is AstNode) visit(child);
    }
  }

  visit(stmt);

  if (replacements.isEmpty) return source;

  // Apply back-to-front so earlier offsets stay valid.
  replacements.sort((a, b) => b.$1.compareTo(a.$1));
  var result = source;
  for (final (start, end, text) in replacements) {
    result = result.substring(0, start) + text + result.substring(end);
  }
  return result;
}

/// Transforms a single expression [expr] with [ctx], returning the rewritten source.
/// Used for transforming individual arguments in event calls.
String _transformExpr(Expression expr, int baseOffset, DslContext ctx) {
  final source = expr.toSource();
  final replacements = <(int start, int end, String text)>[];

  void visit(AstNode node) {
    if (node is SimpleIdentifier) {
      final name = node.name;
      if (node.parent is MethodInvocation &&
          (node.parent as MethodInvocation).methodName == node) return;
      final paramReplacement = ctx.paramReplacements[name];
      if (paramReplacement != null) {
        replacements.add((node.offset - expr.offset, node.end - expr.offset, paramReplacement));
        return;
      }
      final className = ctx.components[name] ?? ctx.dependencies[name];
      if (className != null) {
        replacements.add((node.offset - expr.offset, node.end - expr.offset, 'getEntity<$className>().value'));
        return;
      }
    }
    for (final child in node.childEntities) {
      if (child is AstNode) visit(child);
    }
  }

  visit(expr);
  if (replacements.isEmpty) return source;
  replacements.sort((a, b) => b.$1.compareTo(a.$1));
  var result = source;
  for (final (start, end, text) in replacements) {
    result = result.substring(0, start) + text + result.substring(end);
  }
  return result;
}

/// Transforms a block of statements and returns the indented body string.
String transformDslStatements(NodeList<Statement> stmts, DslContext ctx) {
  final buffer = StringBuffer();
  for (final stmt in stmts) {
    buffer.writeln('    ${transformDslStatement(stmt, ctx)}');
  }
  return buffer.toString();
}

/// Validates that [body] is a block body and returns the transformed source.
String extractAndTransformBody(FunctionBody body, Element element, DslContext ctx) {
  if (body is! BlockFunctionBody) {
    throw InvalidGenerationSourceError(
      'System function must use a block body {}. Expression bodies => are not supported.',
      element: element,
    );
  }
  return transformDslStatements(body.block.statements, ctx);
}

/// Finds and transforms a named private helper function in [unit],
/// returning its transformed body text, or null if not found.
String? extractPrivateHelperBody(String name, CompilationUnit unit, DslContext ctx) {
  for (final decl in unit.declarations) {
    if (decl is FunctionDeclaration && decl.name.lexeme == name) {
      final body = decl.functionExpression.body;
      if (body is BlockFunctionBody) {
        return transformDslStatements(body.block.statements, ctx);
      }
    }
  }
  return null;
}

/// Collects all private helper function names transitively called
/// from [stmts] that are defined in [unit].
Set<String> collectPrivateHelpers(
  NodeList<Statement> stmts,
  CompilationUnit unit, {
  Set<String>? visited,
}) {
  final result = <String>{};
  final toVisit = visited ?? <String>{};

  void collect(AstNode node) {
    if (node is MethodInvocation && node.target == null) {
      final name = node.methodName.name;
      if (name.startsWith('_') && !toVisit.contains(name)) {
        // Verify it's a top-level function in this unit.
        for (final decl in unit.declarations) {
          if (decl is FunctionDeclaration && decl.name.lexeme == name) {
            result.add(name);
            toVisit.add(name);
            // Recurse into helper's body.
            final body = decl.functionExpression.body;
            if (body is BlockFunctionBody) {
              final nested = collectPrivateHelpers(
                body.block.statements,
                unit,
                visited: toVisit,
              );
              result.addAll(nested);
            }
            break;
          }
        }
      }
    }
    for (final child in node.childEntities) {
      if (child is AstNode) collect(child);
    }
  }

  for (final stmt in stmts) {
    collect(stmt);
  }
  return result;
}

/// Returns the Dart source literal for the constant default value of [element].
/// Handles String, int, double, and bool primitives with computed constant values.
/// For other types, returns null (caller emits the initializer from AST source).
String? extractPrimitiveDefault(TopLevelVariableElement element) {
  final constant = element.computeConstantValue();
  if (constant == null) return null;
  final type = element.type;
  if (type.isDartCoreString) return '"${constant.toStringValue() ?? ''}"';
  if (type.isDartCoreInt) return '${constant.toIntValue() ?? 0}';
  if (type.isDartCoreDouble) return '${constant.toDoubleValue() ?? 0.0}';
  if (type.isDartCoreBool) return '${constant.toBoolValue() ?? false}';
  return null;
}

/// Extracts the initializer source string from the AST for a variable declaration.
/// Returns the raw Dart source text of the initializer expression.
/// Throws [InvalidGenerationSourceError] if no initializer is present.
String extractInitializerSource(
  VariableDeclaration varDecl,
  Element element,
) {
  final initializer = varDecl.initializer;
  if (initializer == null) {
    throw InvalidGenerationSourceError(
      '@Component / @Dependency variable must have an initializer to infer a default value.',
      element: element,
    );
  }
  return initializer.toSource();
}

/// Detects writes to annotated variables in [stmts] and private helpers.
/// Returns the set of component/dependency class names that are written to.
Set<String> detectInteractsWith(
  NodeList<Statement> stmts,
  CompilationUnit unit,
  DslContext ctx,
) {
  final result = <String>{};

  void collectWrites(AstNode node) {
    if (node is AssignmentExpression) {
      final lhs = node.leftHandSide;
      if (lhs is SimpleIdentifier) {
        final className = ctx.components[lhs.name] ?? ctx.dependencies[lhs.name];
        if (className != null) result.add(className);
      }
    }
    // Event calls (trigger) count as interactsWith.
    if (node is MethodInvocation && node.target == null) {
      final name = node.methodName.name;
      final className = ctx.events[name];
      if (className != null) result.add(className);
    }
    for (final child in node.childEntities) {
      if (child is AstNode) collectWrites(child);
    }
  }

  for (final stmt in stmts) {
    collectWrites(stmt);
  }

  // Also scan private helpers.
  final helpers = collectPrivateHelpers(stmts, unit);
  for (final helperName in helpers) {
    for (final decl in unit.declarations) {
      if (decl is FunctionDeclaration && decl.name.lexeme == helperName) {
        final body = decl.functionExpression.body;
        if (body is BlockFunctionBody) {
          for (final stmt in body.block.statements) {
            collectWrites(stmt);
          }
        }
        break;
      }
    }
  }

  return result;
}

/// Emits a helper function from [unit] as a private method string,
/// with its body transformed by [ctx].
String emitPrivateMethod(
  String name,
  CompilationUnit unit,
  DslContext ctx,
) {
  for (final decl in unit.declarations) {
    if (decl is FunctionDeclaration && decl.name.lexeme == name) {
      final func = decl.functionExpression;
      final returnType = decl.returnType?.toSource() ?? 'void';
      final params = func.parameters?.toSource() ?? '()';
      final body = func.body;
      if (body is BlockFunctionBody) {
        final transformed = transformDslStatements(body.block.statements, ctx);
        final buffer = StringBuffer();
        buffer.writeln('  $returnType $name$params {');
        buffer.write(transformed);
        buffer.writeln('  }');
        return buffer.toString();
      }
    }
  }
  return '';
}
```

> **Note:** The `ExpressionStatement2` wrapper used in `transformDslStatement` doesn't exist in the analyzer — remove that section and simplify. The actual implementation is simpler: for event call arguments, directly visit child nodes using the same `_transformExpr` helper. The code above shows the intent but needs cleanup — see the actual implementation in Step 3.

- [ ] **Step 2b: Simplify `_helpers.dart` by removing the `ExpressionStatement2` reference**

The `transformDslStatement` function above has a mistake in the event-call branch. Replace the event-call block with this simpler version that transforms arguments via `_transformExpr`:

```dart
    if (node is MethodInvocation && node.target == null) {
      final name = node.methodName.name;
      final className = ctx.events[name];
      if (className != null) {
        final args = node.argumentList.arguments;
        final relStart = node.offset - stmt.offset;
        final relEnd = node.end - stmt.offset;
        if (args.isEmpty) {
          replacements.add((relStart, relEnd, 'getEntity<$className>().trigger()'));
        } else {
          final transformedArgs =
              args.map((a) => _transformExpr(a, ctx)).join(', ');
          replacements.add((relStart, relEnd, 'getEntity<$className>().trigger($transformedArgs)'));
        }
        return;
      }
    }
```

And update `_transformExpr` to not take `baseOffset`:

```dart
String _transformExpr(Expression expr, DslContext ctx) {
  final source = expr.toSource();
  final replacements = <(int start, int end, String text)>[];

  void visit(AstNode node) {
    if (node is SimpleIdentifier) {
      final name = node.name;
      if (node.parent is MethodInvocation &&
          (node.parent as MethodInvocation).methodName == node) return;
      final paramReplacement = ctx.paramReplacements[name];
      if (paramReplacement != null) {
        replacements.add((node.offset - expr.offset, node.end - expr.offset, paramReplacement));
        return;
      }
      final className = ctx.components[name] ?? ctx.dependencies[name];
      if (className != null) {
        replacements.add((node.offset - expr.offset, node.end - expr.offset, 'getEntity<$className>().value'));
        return;
      }
    }
    for (final child in node.childEntities) {
      if (child is AstNode) visit(child);
    }
  }

  visit(expr);
  if (replacements.isEmpty) return source;
  replacements.sort((a, b) => b.$1.compareTo(a.$1));
  var result = source;
  for (final (start, end, text) in replacements) {
    result = result.substring(0, start) + text + result.substring(end);
  }
  return result;
}
```

### Step 3: Rewrite entity generators

- [ ] **Step 3a: Rewrite `generator/lib/src/generators/entity_generator.dart`**

```dart
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
import 'package:source_gen/source_gen.dart';
import '_helpers.dart';

final class ComponentGenerator extends GeneratorForAnnotation<Component> {
  const ComponentGenerator()
      : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! TopLevelVariableElement) {
      throw InvalidGenerationSourceError(
        '@Component can only be applied to top-level variables.',
        element: element,
      );
    }

    final astNode = await buildStep.resolver.astNodeFor(
      element.firstFragment,
      resolve: true,
    );

    final varDecl = _findVarDecl(astNode, element.name!);
    final defaultValue = extractInitializerSource(varDecl, element);
    final varName = element.name!;
    final type = element.type.getDisplayString();
    final description = annotation.peek('description')?.stringValue;
    final className = '${capitalize(varName)}Component';

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSComponent<$type> {');
    buffer.writeln('  $className([super.value = $defaultValue]);');
    buffer.writeln('}');
    return buffer.toString();
  }
}

final class DependencyGenerator extends GeneratorForAnnotation<Dependency> {
  const DependencyGenerator()
      : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! TopLevelVariableElement) {
      throw InvalidGenerationSourceError(
        '@Dependency can only be applied to top-level variables.',
        element: element,
      );
    }

    final astNode = await buildStep.resolver.astNodeFor(
      element.firstFragment,
      resolve: true,
    );

    final varDecl = _findVarDecl(astNode, element.name!);
    final defaultValue = extractInitializerSource(varDecl, element);
    final varName = element.name!;
    final type = element.type.getDisplayString();
    final description = annotation.peek('description')?.stringValue;
    final className = '${capitalize(varName)}Dependency';

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSDependency<$type> {');
    buffer.writeln('  $className([super.value = $defaultValue]);');
    buffer.writeln('}');
    return buffer.toString();
  }
}

final class EventGenerator extends GeneratorForAnnotation<Event> {
  const EventGenerator()
      : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! TopLevelFunctionElement) {
      throw InvalidGenerationSourceError(
        '@Event can only be applied to top-level void functions.',
        element: element,
      );
    }

    final params = element.parameters;
    if (params.length > 1) {
      throw InvalidGenerationSourceError(
        '@Event functions must have zero or one parameter. '
        'Multi-parameter events are not supported.',
        element: element,
      );
    }

    final funcName = element.name!;
    final description = annotation.peek('description')?.stringValue;
    final raw = capitalize(funcName);
    final className = raw.endsWith('Event') ? raw : '${raw}Event';

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');

    if (params.isEmpty) {
      // No-data event.
      buffer.writeln('final class $className extends ECSEvent {}');
    } else {
      // Data event — type comes from the single parameter.
      final param = params.first;
      final type = param.type.getDisplayString();
      buffer.writeln('final class $className extends ECSDataEvent<$type> {');
      buffer.writeln('  @override');
      // For primitive types, add a default value; otherwise, require the argument.
      final primitiveDefault = _primitiveDefault(type);
      if (primitiveDefault != null) {
        buffer.writeln('  void trigger([$type data = $primitiveDefault]) => super.trigger(data);');
      } else {
        buffer.writeln('  void trigger($type data) => super.trigger(data);');
      }
      buffer.writeln('}');
    }

    return buffer.toString();
  }

  String? _primitiveDefault(String typeName) {
    return switch (typeName) {
      'int' => '0',
      'double' => '0.0',
      'String' => '""',
      'bool' => 'false',
      _ => null,
    };
  }
}

/// Finds the [VariableDeclaration] for [varName] in the AST node returned by
/// [resolver.astNodeFor] for a [TopLevelVariableElement].
VariableDeclaration _findVarDecl(AstNode? astNode, String varName) {
  // astNodeFor a TopLevelVariableElement returns the VariableDeclaration itself.
  if (astNode is VariableDeclaration && astNode.name.lexeme == varName) {
    return astNode;
  }
  // Fallback: walk up to TopLevelVariableDeclaration.
  if (astNode is TopLevelVariableDeclaration) {
    for (final v in astNode.variables.variables) {
      if (v.name.lexeme == varName) return v;
    }
  }
  throw StateError('Could not find VariableDeclaration for $varName');
}
```

- [ ] **Step 3b: Run entity generator tests — all must pass**

```bash
cd generator && dart test test/component_generator_test.dart test/event_generator_test.dart test/dependency_generator_test.dart
```

Expected: all tests pass. If any fail, diagnose and fix before proceeding.

- [ ] **Step 3c: Commit**

```bash
git add annotations/ generator/lib/ generator/test/component_generator_test.dart generator/test/event_generator_test.dart generator/test/dependency_generator_test.dart
git commit -m "feat: new ECS DSL — annotations rewrite + entity generators"
```

---

## Task 4: Rewrite system generators

**Files:**
- Rewrite: `generator/lib/src/generators/system_generator.dart`
- Rewrite: `generator/test/reactive_system_generator_test.dart`
- Rewrite: `generator/test/initialize_system_generator_test.dart`
- Rewrite: `generator/test/teardown_system_generator_test.dart`
- Rewrite: `generator/test/cleanup_system_generator_test.dart`
- Rewrite: `generator/test/execute_system_generator_test.dart`

### Step 1: Write failing tests

- [ ] **Step 1a: Rewrite `reactive_system_generator_test.dart`**

```dart
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:flutter_event_component_system_generator/flutter_event_component_system_generator.dart';

const _outputKey =
    'flutter_event_component_system_generator|lib/input.ecs.g.dart';
const _annotationAsset =
    'flutter_event_component_system_annotations|lib/flutter_event_component_system_annotations.dart';
const _annotationSource = '''
  final class Component { final String? description; const Component({this.description}); }
  final class Event { final String? description; const Event({this.description}); }
  final class Dependency { final String? description; const Dependency({this.description}); }
  final class ReactiveSystem { final String? description; const ReactiveSystem({this.description}); }
  final class InitializeSystem { final String? description; const InitializeSystem({this.description}); }
  final class TeardownSystem { final String? description; const TeardownSystem({this.description}); }
  final class CleanupSystem { final String? description; const CleanupSystem({this.description}); }
  final class ExecuteSystem { final String? description; const ExecuteSystem({this.description}); }
''';

Map<String, String> buildSources(String body) {
  return {
    _annotationAsset: _annotationSource,
    'flutter_event_component_system_generator|lib/input.dart': '''
        import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
        part 'input.ecs.g.dart';
        $body
      ''',
  };
}

void main() {
  group('ReactiveSystemGenerator', () {
    test('auto-detects reactsTo from @Event function body', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) { applyAddHealth(amount); }

          @ReactiveSystem()
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

    test('auto-detects interactsWith from writes in body', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) { applyAddHealth(amount); }

          @ReactiveSystem()
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

    test('rewrites component write in react body', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) { applyAddHealth(amount); }

          @ReactiveSystem()
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

    test('injects event data for reactive system with parameter', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) { applyAddHealth(amount); }

          @ReactiveSystem()
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

    test('handles no-data reactive system with no parameter', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 100;
          @Event() void logout() { logoutSystem(); }

          @ReactiveSystem()
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

    test('private helpers become private methods on generated class', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) { applyAddHealth(amount); }

          @ReactiveSystem()
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

    test('private helper writes are included in interactsWith', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Event() void addHealth(int amount) { applyAddHealth(amount); }

          @ReactiveSystem()
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

    test('reads are NOT included in interactsWith', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;
          @Component() int maxHealth = 100;
          @Event() void checkHealth() { checkSystem(); }

          @ReactiveSystem()
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

    test('includes doc comment when description is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Event() void logout() { logoutSystem(); }

          @ReactiveSystem(description: "Handles logout")
          void logoutSystem() {}
        '''),
        outputs: {
          _outputKey: decodedMatches(contains('/// Handles logout')),
        },
      );
    });
  });
}
```

- [ ] **Step 1b: Rewrite `initialize_system_generator_test.dart`**

```dart
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:flutter_event_component_system_generator/flutter_event_component_system_generator.dart';

const _outputKey =
    'flutter_event_component_system_generator|lib/input.ecs.g.dart';
const _annotationAsset =
    'flutter_event_component_system_annotations|lib/flutter_event_component_system_annotations.dart';
const _annotationSource = '''
  final class Component { final String? description; const Component({this.description}); }
  final class Event { final String? description; const Event({this.description}); }
  final class Dependency { final String? description; const Dependency({this.description}); }
  final class ReactiveSystem { final String? description; const ReactiveSystem({this.description}); }
  final class InitializeSystem { final String? description; const InitializeSystem({this.description}); }
  final class TeardownSystem { final String? description; const TeardownSystem({this.description}); }
  final class CleanupSystem { final String? description; const CleanupSystem({this.description}); }
  final class ExecuteSystem { final String? description; const ExecuteSystem({this.description}); }
''';

Map<String, String> buildSources(String body) {
  return {
    _annotationAsset: _annotationSource,
    'flutter_event_component_system_generator|lib/input.dart': '''
        import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
        part 'input.ecs.g.dart';
        $body
      ''',
  };
}

void main() {
  group('InitializeSystemGenerator', () {
    test('generates initialize system class', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Event() void timerStart() {}

          @InitializeSystem()
          void startTimerInitialize() {
            timerStart();
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class StartTimerInitializeInitializeSystem extends ECSInitializeSystem'),
            contains('void initialize()'),
            contains('getEntity<TimerStartEvent>().trigger()'),
          ])),
        },
      );
    });

    test('rewrites component write in initialize body', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int health = 0;

          @InitializeSystem()
          void initHealth() {
            health = 100;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(
            contains('getEntity<HealthComponent>().value = 100'),
          ),
        },
      );
    });

    test('includes doc comment when description is provided', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @InitializeSystem(description: "Set up timer")
          void startTimer() {}
        '''),
        outputs: {
          _outputKey: decodedMatches(contains('/// Set up timer')),
        },
      );
    });
  });
}
```

- [ ] **Step 1c: Rewrite `teardown_system_generator_test.dart`**

```dart
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:flutter_event_component_system_generator/flutter_event_component_system_generator.dart';

const _outputKey =
    'flutter_event_component_system_generator|lib/input.ecs.g.dart';
const _annotationAsset =
    'flutter_event_component_system_annotations|lib/flutter_event_component_system_annotations.dart';
const _annotationSource = '''
  final class Component { final String? description; const Component({this.description}); }
  final class Event { final String? description; const Event({this.description}); }
  final class Dependency { final String? description; const Dependency({this.description}); }
  final class ReactiveSystem { final String? description; const ReactiveSystem({this.description}); }
  final class InitializeSystem { final String? description; const InitializeSystem({this.description}); }
  final class TeardownSystem { final String? description; const TeardownSystem({this.description}); }
  final class CleanupSystem { final String? description; const CleanupSystem({this.description}); }
  final class ExecuteSystem { final String? description; const ExecuteSystem({this.description}); }
''';

Map<String, String> buildSources(String body) {
  return {
    _annotationAsset: _annotationSource,
    'flutter_event_component_system_generator|lib/input.dart': '''
        import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
        part 'input.ecs.g.dart';
        $body
      ''',
  };
}

void main() {
  group('TeardownSystemGenerator', () {
    test('generates teardown system class', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          enum AuthState { unknown }
          @Component() AuthState authState = AuthState.unknown;

          @TeardownSystem()
          void disposeAuth() {
            authState = AuthState.unknown;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('final class DisposeAuthTeardownSystem extends ECSTeardownSystem'),
            contains('void teardown()'),
            contains('getEntity<AuthStateComponent>().value = AuthState.unknown'),
          ])),
        },
      );
    });
  });
}
```

- [ ] **Step 1d: Rewrite `cleanup_system_generator_test.dart`**

```dart
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:flutter_event_component_system_generator/flutter_event_component_system_generator.dart';

const _outputKey =
    'flutter_event_component_system_generator|lib/input.ecs.g.dart';
const _annotationAsset =
    'flutter_event_component_system_annotations|lib/flutter_event_component_system_annotations.dart';
const _annotationSource = '''
  final class Component { final String? description; const Component({this.description}); }
  final class Event { final String? description; const Event({this.description}); }
  final class Dependency { final String? description; const Dependency({this.description}); }
  final class ReactiveSystem { final String? description; const ReactiveSystem({this.description}); }
  final class InitializeSystem { final String? description; const InitializeSystem({this.description}); }
  final class TeardownSystem { final String? description; const TeardownSystem({this.description}); }
  final class CleanupSystem { final String? description; const CleanupSystem({this.description}); }
  final class ExecuteSystem { final String? description; const ExecuteSystem({this.description}); }
''';

Map<String, String> buildSources(String body) {
  return {
    _annotationAsset: _annotationSource,
    'flutter_event_component_system_generator|lib/input.dart': '''
        import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
        part 'input.ecs.g.dart';
        $body
      ''',
  };
}

void main() {
  group('CleanupSystemGenerator', () {
    test('generates cleanup system class', () async {
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
          _outputKey: decodedMatches(allOf([
            contains('final class CleanupLoginCleanupSystem extends ECSCleanupSystem'),
            contains('void cleanup()'),
            contains('getEntity<LoginProcessComponent>().value = 0'),
          ])),
        },
      );
    });
  });
}
```

- [ ] **Step 1e: Rewrite `execute_system_generator_test.dart`**

```dart
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:flutter_event_component_system_generator/flutter_event_component_system_generator.dart';

const _outputKey =
    'flutter_event_component_system_generator|lib/input.ecs.g.dart';
const _annotationAsset =
    'flutter_event_component_system_annotations|lib/flutter_event_component_system_annotations.dart';
const _annotationSource = '''
  final class Component { final String? description; const Component({this.description}); }
  final class Event { final String? description; const Event({this.description}); }
  final class Dependency { final String? description; const Dependency({this.description}); }
  final class ReactiveSystem { final String? description; const ReactiveSystem({this.description}); }
  final class InitializeSystem { final String? description; const InitializeSystem({this.description}); }
  final class TeardownSystem { final String? description; const TeardownSystem({this.description}); }
  final class CleanupSystem { final String? description; const CleanupSystem({this.description}); }
  final class ExecuteSystem { final String? description; const ExecuteSystem({this.description}); }
''';

Map<String, String> buildSources(String body) {
  return {
    _annotationAsset: _annotationSource,
    'flutter_event_component_system_generator|lib/input.dart': '''
        import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
        part 'input.ecs.g.dart';
        $body
      ''',
  };
}

void main() {
  group('ExecuteSystemGenerator', () {
    test('generates execute system class with elapsed parameter', () async {
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
          _outputKey: decodedMatches(allOf([
            contains('final class UpdateTimerExecuteSystem extends ECSExecuteSystem'),
            contains('void execute(Duration elapsed)'),
            contains('getEntity<TimerValueComponent>().value += elapsed.inMilliseconds'),
          ])),
        },
      );
    });

    test('reads are not included in interactsWith', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        buildSources('''
          @Component() int timerState = 0;
          @Component() int timerValue = 0;

          @ExecuteSystem()
          void updateTimer(Duration elapsed) {
            if (timerState != 0) return;
            timerValue += elapsed.inMilliseconds;
          }
        '''),
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('TimerValueComponent'),
            isNot(contains('TimerStateComponent')),
          ])),
        },
      );
    });
  });
}
```

- [ ] **Step 1f: Run system tests — all must FAIL**

```bash
cd generator && dart test test/reactive_system_generator_test.dart test/initialize_system_generator_test.dart test/teardown_system_generator_test.dart test/cleanup_system_generator_test.dart test/execute_system_generator_test.dart
```

Expected: compile errors or failures (system_generator.dart still has old class names).

### Step 2: Rewrite system generators

- [ ] **Step 2a: Rewrite `generator/lib/src/generators/system_generator.dart`**

```dart
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
import 'package:source_gen/source_gen.dart';
import '_helpers.dart';

// TypeChecker constants shared by all system generators.
const _componentChecker = TypeChecker.typeNamed(
  Component,
  inPackage: 'flutter_event_component_system_annotations',
);
const _eventChecker = TypeChecker.typeNamed(
  Event,
  inPackage: 'flutter_event_component_system_annotations',
);
const _dependencyChecker = TypeChecker.typeNamed(
  Dependency,
  inPackage: 'flutter_event_component_system_annotations',
);

/// Builds a [DslContext] by scanning the [library] for annotated entities.
DslContext buildDslContext(LibraryReader library) {
  final components = <String, String>{};
  final events = <String, String>{};
  final dependencies = <String, String>{};

  for (final a in library.annotatedWith(_componentChecker)) {
    final name = a.element.name;
    if (name != null) components[name] = '${capitalize(name)}Component';
  }
  for (final a in library.annotatedWith(_eventChecker)) {
    final name = a.element.name;
    if (name != null) events[name] = '${capitalize(name)}Event';
  }
  for (final a in library.annotatedWith(_dependencyChecker)) {
    final name = a.element.name;
    if (name != null) dependencies[name] = '${capitalize(name)}Dependency';
  }

  return DslContext(
    components: components,
    events: events,
    dependencies: dependencies,
  );
}

final class ReactiveSystemGenerator
    extends GeneratorForAnnotation<ReactiveSystem> {
  const ReactiveSystemGenerator()
      : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! TopLevelFunctionElement) {
      throw InvalidGenerationSourceError(
        '@ReactiveSystem can only be applied to top-level functions.',
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

    final library = LibraryReader(element.library!);
    final baseCtx = buildDslContext(library);
    final unit = astNode.root as CompilationUnit;
    final funcName = element.name!;
    final description = annotation.peek('description')?.stringValue;
    final raw = capitalize(funcName);
    final className =
        raw.endsWith('ReactiveSystem') ? raw : '${raw}ReactiveSystem';

    // Build param replacements: each parameter of this system corresponds to
    // the event data for the event(s) that react to this system.
    // We find the event(s) by scanning @Event function bodies for calls to this system.
    final reactsToClasses = _detectReactsTo(funcName, unit, baseCtx);
    final paramReplacements = _buildParamReplacements(
      element.parameters,
      reactsToClasses,
    );
    final ctx = baseCtx.withParamReplacements(paramReplacements);

    final body = astNode.functionExpression.body;
    if (body is! BlockFunctionBody) {
      throw InvalidGenerationSourceError(
        'System function must use a block body {}.',
        element: element,
      );
    }

    final reactBody = transformDslStatements(body.block.statements, ctx);
    final interactsWith = detectInteractsWith(body.block.statements, unit, ctx);
    final privateHelpers = collectPrivateHelpers(body.block.statements, unit);

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSReactiveSystem {');

    buffer.writeln('  @override');
    buffer.writeln('  Set<Type> get reactsTo {');
    buffer.writeln('    return const {${reactsToClasses.join(', ')}};');
    buffer.writeln('  }');

    if (interactsWith.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('  @override');
      buffer.writeln('  Set<Type> get interactsWith {');
      buffer.writeln('    return const {${interactsWith.join(', ')}};');
      buffer.writeln('  }');
    }

    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  void react() {');
    buffer.write(reactBody);
    buffer.writeln('  }');

    for (final helperName in privateHelpers) {
      buffer.writeln();
      buffer.write(emitPrivateMethod(helperName, unit, ctx));
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  /// Scans all @Event function bodies in [unit] for calls to [systemFuncName].
  /// Returns the list of event class names this system reacts to.
  List<String> _detectReactsTo(
    String systemFuncName,
    CompilationUnit unit,
    DslContext ctx,
  ) {
    final result = <String>[];
    for (final decl in unit.declarations) {
      if (decl is! FunctionDeclaration) continue;
      final eventClassName = ctx.events[decl.name.lexeme];
      if (eventClassName == null) continue;
      // This is an @Event function — scan its body for calls to our system.
      final body = decl.functionExpression.body;
      if (body is! BlockFunctionBody) continue;
      for (final stmt in body.block.statements) {
        if (_stmtCallsFunction(stmt, systemFuncName)) {
          result.add(eventClassName);
          break;
        }
      }
    }
    return result;
  }

  bool _stmtCallsFunction(Statement stmt, String funcName) {
    bool found = false;
    void visit(AstNode node) {
      if (found) return;
      if (node is MethodInvocation &&
          node.target == null &&
          node.methodName.name == funcName) {
        found = true;
        return;
      }
      for (final child in node.childEntities) {
        if (child is AstNode) visit(child);
      }
    }
    visit(stmt);
    return found;
  }

  /// For each system parameter, builds the event data replacement expression.
  /// A system parameter `amount` for event `AddHealthEvent` becomes
  /// `getEntity<AddHealthEvent>().data`.
  Map<String, String> _buildParamReplacements(
    List<ParameterElement> params,
    List<String> reactsToClasses,
  ) {
    if (params.isEmpty || reactsToClasses.isEmpty) return const {};
    // Use the first reacting event (systems typically react to one event).
    final eventClass = reactsToClasses.first;
    return {
      for (final p in params) p.name!: 'getEntity<$eventClass>().data',
    };
  }
}

final class InitializeSystemGenerator
    extends GeneratorForAnnotation<InitializeSystem> {
  const InitializeSystemGenerator()
      : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! TopLevelFunctionElement) {
      throw InvalidGenerationSourceError(
        '@InitializeSystem can only be applied to top-level functions.',
        element: element,
      );
    }

    final astNode = await buildStep.resolver.astNodeFor(
      element.firstFragment,
      resolve: true,
    );
    if (astNode is! FunctionDeclaration) {
      throw InvalidGenerationSourceError('Could not resolve AST.', element: element);
    }

    final library = LibraryReader(element.library!);
    final ctx = buildDslContext(library);
    final unit = astNode.root as CompilationUnit;
    final funcName = element.name!;
    final description = annotation.peek('description')?.stringValue;
    final raw = capitalize(funcName);
    final className =
        raw.endsWith('InitializeSystem') ? raw : '${raw}InitializeSystem';

    final body = astNode.functionExpression.body;
    if (body is! BlockFunctionBody) {
      throw InvalidGenerationSourceError('System must use block body.', element: element);
    }
    final transformed = transformDslStatements(body.block.statements, ctx);
    final privateHelpers = collectPrivateHelpers(body.block.statements, unit);

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSInitializeSystem {');
    buffer.writeln('  @override');
    buffer.writeln('  void initialize() {');
    buffer.write(transformed);
    buffer.writeln('  }');
    for (final h in privateHelpers) {
      buffer.writeln();
      buffer.write(emitPrivateMethod(h, unit, ctx));
    }
    buffer.writeln('}');
    return buffer.toString();
  }
}

final class TeardownSystemGenerator
    extends GeneratorForAnnotation<TeardownSystem> {
  const TeardownSystemGenerator()
      : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! TopLevelFunctionElement) {
      throw InvalidGenerationSourceError(
        '@TeardownSystem can only be applied to top-level functions.',
        element: element,
      );
    }

    final astNode = await buildStep.resolver.astNodeFor(
      element.firstFragment,
      resolve: true,
    );
    if (astNode is! FunctionDeclaration) {
      throw InvalidGenerationSourceError('Could not resolve AST.', element: element);
    }

    final library = LibraryReader(element.library!);
    final ctx = buildDslContext(library);
    final unit = astNode.root as CompilationUnit;
    final funcName = element.name!;
    final description = annotation.peek('description')?.stringValue;
    final raw = capitalize(funcName);
    final className =
        raw.endsWith('TeardownSystem') ? raw : '${raw}TeardownSystem';

    final body = astNode.functionExpression.body;
    if (body is! BlockFunctionBody) {
      throw InvalidGenerationSourceError('System must use block body.', element: element);
    }
    final transformed = transformDslStatements(body.block.statements, ctx);
    final privateHelpers = collectPrivateHelpers(body.block.statements, unit);

    final buffer = StringBuffer();
    if (description != null) buffer.writeln('/// $description');
    buffer.writeln('final class $className extends ECSTeardownSystem {');
    buffer.writeln('  @override');
    buffer.writeln('  void teardown() {');
    buffer.write(transformed);
    buffer.writeln('  }');
    for (final h in privateHelpers) {
      buffer.writeln();
      buffer.write(emitPrivateMethod(h, unit, ctx));
    }
    buffer.writeln('}');
    return buffer.toString();
  }
}

final class CleanupSystemGenerator
    extends GeneratorForAnnotation<CleanupSystem> {
  const CleanupSystemGenerator()
      : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! TopLevelFunctionElement) {
      throw InvalidGenerationSourceError(
        '@CleanupSystem can only be applied to top-level functions.',
        element: element,
      );
    }

    final astNode = await buildStep.resolver.astNodeFor(
      element.firstFragment,
      resolve: true,
    );
    if (astNode is! FunctionDeclaration) {
      throw InvalidGenerationSourceError('Could not resolve AST.', element: element);
    }

    final library = LibraryReader(element.library!);
    final ctx = buildDslContext(library);
    final unit = astNode.root as CompilationUnit;
    final funcName = element.name!;
    final description = annotation.peek('description')?.stringValue;
    final raw = capitalize(funcName);
    final className =
        raw.endsWith('CleanupSystem') ? raw : '${raw}CleanupSystem';

    final body = astNode.functionExpression.body;
    if (body is! BlockFunctionBody) {
      throw InvalidGenerationSourceError('System must use block body.', element: element);
    }
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
  }
}

final class ExecuteSystemGenerator
    extends GeneratorForAnnotation<ExecuteSystem> {
  const ExecuteSystemGenerator()
      : super(inPackage: 'flutter_event_component_system_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! TopLevelFunctionElement) {
      throw InvalidGenerationSourceError(
        '@ExecuteSystem can only be applied to top-level functions.',
        element: element,
      );
    }

    final astNode = await buildStep.resolver.astNodeFor(
      element.firstFragment,
      resolve: true,
    );
    if (astNode is! FunctionDeclaration) {
      throw InvalidGenerationSourceError('Could not resolve AST.', element: element);
    }

    final library = LibraryReader(element.library!);
    final ctx = buildDslContext(library);
    final unit = astNode.root as CompilationUnit;
    final funcName = element.name!;
    final description = annotation.peek('description')?.stringValue;
    final raw = capitalize(funcName);
    final className =
        raw.endsWith('ExecuteSystem') ? raw : '${raw}ExecuteSystem';

    final body = astNode.functionExpression.body;
    if (body is! BlockFunctionBody) {
      throw InvalidGenerationSourceError('System must use block body.', element: element);
    }
    // `elapsed` is the standard parameter name — do NOT replace it with event data.
    // We still transform component reads/writes inside the body.
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
    for (final h in privateHelpers) {
      buffer.writeln();
      buffer.write(emitPrivateMethod(h, unit, ctx));
    }
    buffer.writeln('}');
    return buffer.toString();
  }
}
```

- [ ] **Step 2b: Run system tests — all must pass**

```bash
cd generator && dart test test/reactive_system_generator_test.dart test/initialize_system_generator_test.dart test/teardown_system_generator_test.dart test/cleanup_system_generator_test.dart test/execute_system_generator_test.dart
```

Expected: all pass. Diagnose and fix any failures before proceeding.

- [ ] **Step 2c: Commit**

```bash
git add generator/lib/src/generators/system_generator.dart generator/test/reactive_system_generator_test.dart generator/test/initialize_system_generator_test.dart generator/test/teardown_system_generator_test.dart generator/test/cleanup_system_generator_test.dart generator/test/execute_system_generator_test.dart
git commit -m "feat: new ECS DSL — system generators with auto-detected reactsTo/interactsWith"
```

---

## Task 5: Rewrite feature generator

**Files:**
- Rewrite: `generator/lib/src/generators/feature_generator.dart`
- Rewrite: `generator/test/feature_generator_test.dart`
- Rewrite: `generator/test/ecs_generator_test.dart`

### Step 1: Write failing test

- [ ] **Step 1a: Rewrite `feature_generator_test.dart`**

```dart
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:flutter_event_component_system_generator/flutter_event_component_system_generator.dart';

const _outputKey =
    'flutter_event_component_system_generator|lib/timer_feature.ecs.g.dart';
const _annotationAsset =
    'flutter_event_component_system_annotations|lib/flutter_event_component_system_annotations.dart';
const _annotationSource = '''
  final class Component { final String? description; const Component({this.description}); }
  final class Event { final String? description; const Event({this.description}); }
  final class Dependency { final String? description; const Dependency({this.description}); }
  final class ReactiveSystem { final String? description; const ReactiveSystem({this.description}); }
  final class InitializeSystem { final String? description; const InitializeSystem({this.description}); }
  final class TeardownSystem { final String? description; const TeardownSystem({this.description}); }
  final class CleanupSystem { final String? description; const CleanupSystem({this.description}); }
  final class ExecuteSystem { final String? description; const ExecuteSystem({this.description}); }
''';

void main() {
  group('FeatureGenerator', () {
    test('derives class name from filename', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        {
          _annotationAsset: _annotationSource,
          'flutter_event_component_system_generator|lib/timer_feature.dart': '''
            import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
            part 'timer_feature.ecs.g.dart';

            @Component() int timerValue = 0;
          ''',
        },
        outputs: {
          _outputKey: decodedMatches(
            contains('final class TimerFeature extends ECSFeature'),
          ),
        },
      );
    });

    test('registers all components as entities', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        {
          _annotationAsset: _annotationSource,
          'flutter_event_component_system_generator|lib/timer_feature.dart': '''
            import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
            part 'timer_feature.ecs.g.dart';

            @Component() int timerValue = 0;
            @Component() int timerState = 0;
          ''',
        },
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('addEntity(TimerValueComponent())'),
            contains('addEntity(TimerStateComponent())'),
          ])),
        },
      );
    });

    test('registers events as entities', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        {
          _annotationAsset: _annotationSource,
          'flutter_event_component_system_generator|lib/timer_feature.dart': '''
            import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
            part 'timer_feature.ecs.g.dart';

            @Event() void timerStart() {}
          ''',
        },
        outputs: {
          _outputKey: decodedMatches(contains('addEntity(TimerStartEvent())')),
        },
      );
    });

    test('registers reactive systems', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        {
          _annotationAsset: _annotationSource,
          'flutter_event_component_system_generator|lib/timer_feature.dart': '''
            import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
            part 'timer_feature.ecs.g.dart';

            @Event() void timerStart() { startTimerReactive(); }

            @ReactiveSystem()
            void startTimerReactive() {}
          ''',
        },
        outputs: {
          _outputKey: decodedMatches(
            contains('addSystem(StartTimerReactiveReactiveSystem())'),
          ),
        },
      );
    });

    test('registers initialize, teardown, cleanup, and execute systems', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        {
          _annotationAsset: _annotationSource,
          'flutter_event_component_system_generator|lib/timer_feature.dart': '''
            import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
            part 'timer_feature.ecs.g.dart';

            @InitializeSystem() void setupTimer() {}
            @TeardownSystem() void teardownTimer() {}
            @CleanupSystem() void cleanupTimer() {}
            @ExecuteSystem() void tickTimer(Duration elapsed) {}
          ''',
        },
        outputs: {
          _outputKey: decodedMatches(allOf([
            contains('addSystem(SetupTimerInitializeSystem())'),
            contains('addSystem(TeardownTimerTeardownSystem())'),
            contains('addSystem(CleanupTimerCleanupSystem())'),
            contains('addSystem(TickTimerExecuteSystem())'),
          ])),
        },
      );
    });

    test('derives PascalCase name from snake_case filename', () async {
      await testBuilder(
        ecsBuilder(BuilderOptions.empty),
        {
          _annotationAsset: _annotationSource,
          'flutter_event_component_system_generator|lib/user_auth_feature.dart': '''
            import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
            part 'user_auth_feature.ecs.g.dart';

            @Component() int authState = 0;
          ''',
        },
        outputs: {
          'flutter_event_component_system_generator|lib/user_auth_feature.ecs.g.dart':
              decodedMatches(contains('final class UserAuthFeature extends ECSFeature')),
        },
      );
    });
  });
}
```

- [ ] **Step 1b: Run feature generator test — must FAIL**

```bash
cd generator && dart test test/feature_generator_test.dart
```

Expected: compile errors or failures.

### Step 2: Rewrite feature generator

- [ ] **Step 2a: Rewrite `generator/lib/src/generators/feature_generator.dart`**

```dart
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
import 'package:source_gen/source_gen.dart';
import '_helpers.dart';

final class FeatureGenerator extends Generator {
  const FeatureGenerator();

  static const _componentChecker = TypeChecker.typeNamed(
    Component,
    inPackage: 'flutter_event_component_system_annotations',
  );
  static const _eventChecker = TypeChecker.typeNamed(
    Event,
    inPackage: 'flutter_event_component_system_annotations',
  );
  static const _dependencyChecker = TypeChecker.typeNamed(
    Dependency,
    inPackage: 'flutter_event_component_system_annotations',
  );
  static const _reactiveSystemChecker = TypeChecker.typeNamed(
    ReactiveSystem,
    inPackage: 'flutter_event_component_system_annotations',
  );
  static const _initializeSystemChecker = TypeChecker.typeNamed(
    InitializeSystem,
    inPackage: 'flutter_event_component_system_annotations',
  );
  static const _teardownSystemChecker = TypeChecker.typeNamed(
    TeardownSystem,
    inPackage: 'flutter_event_component_system_annotations',
  );
  static const _cleanupSystemChecker = TypeChecker.typeNamed(
    CleanupSystem,
    inPackage: 'flutter_event_component_system_annotations',
  );
  static const _executeSystemChecker = TypeChecker.typeNamed(
    ExecuteSystem,
    inPackage: 'flutter_event_component_system_annotations',
  );

  @override
  String? generate(LibraryReader library, BuildStep buildStep) {
    final components = library.annotatedWith(_componentChecker).toList();
    final events = library.annotatedWith(_eventChecker).toList();
    final dependencies = library.annotatedWith(_dependencyChecker).toList();
    final reactiveSystems = library.annotatedWith(_reactiveSystemChecker).toList();
    final initializeSystems =
        library.annotatedWith(_initializeSystemChecker).toList();
    final teardownSystems =
        library.annotatedWith(_teardownSystemChecker).toList();
    final cleanupSystems = library.annotatedWith(_cleanupSystemChecker).toList();
    final executeSystems = library.annotatedWith(_executeSystemChecker).toList();

    final hasAnything = components.isNotEmpty ||
        events.isNotEmpty ||
        dependencies.isNotEmpty ||
        reactiveSystems.isNotEmpty ||
        initializeSystems.isNotEmpty ||
        teardownSystems.isNotEmpty ||
        cleanupSystems.isNotEmpty ||
        executeSystems.isNotEmpty;

    if (!hasAnything) return null;

    // Derive the Feature class name from the source file's name.
    // e.g. "lib/timer_feature.dart" → "TimerFeature"
    final path = buildStep.inputId.path; // e.g. "lib/timer_feature.dart"
    final filename = path.split('/').last; // "timer_feature.dart"
    final stem = filename.replaceAll('.dart', ''); // "timer_feature"
    final baseName = toPascalCase(stem); // "TimerFeature"
    final className =
        baseName.endsWith('Feature') ? baseName : '${baseName}Feature';

    final buffer = StringBuffer();
    buffer.writeln('final class $className extends ECSFeature {');
    buffer.writeln('  $className() {');

    for (final a in components) {
      final raw = capitalize(a.element.name!);
      final name = raw.endsWith('Component') ? raw : '${raw}Component';
      buffer.writeln('    addEntity($name());');
    }
    for (final a in events) {
      final raw = capitalize(a.element.name!);
      final name = raw.endsWith('Event') ? raw : '${raw}Event';
      buffer.writeln('    addEntity($name());');
    }
    for (final a in dependencies) {
      final raw = capitalize(a.element.name!);
      final name = raw.endsWith('Dependency') ? raw : '${raw}Dependency';
      buffer.writeln('    addEntity($name());');
    }
    for (final a in reactiveSystems) {
      final raw = capitalize(a.element.name!);
      final name = raw.endsWith('ReactiveSystem') ? raw : '${raw}ReactiveSystem';
      buffer.writeln('    addSystem($name());');
    }
    for (final a in initializeSystems) {
      final raw = capitalize(a.element.name!);
      final name = raw.endsWith('InitializeSystem') ? raw : '${raw}InitializeSystem';
      buffer.writeln('    addSystem($name());');
    }
    for (final a in teardownSystems) {
      final raw = capitalize(a.element.name!);
      final name = raw.endsWith('TeardownSystem') ? raw : '${raw}TeardownSystem';
      buffer.writeln('    addSystem($name());');
    }
    for (final a in cleanupSystems) {
      final raw = capitalize(a.element.name!);
      final name = raw.endsWith('CleanupSystem') ? raw : '${raw}CleanupSystem';
      buffer.writeln('    addSystem($name());');
    }
    for (final a in executeSystems) {
      final raw = capitalize(a.element.name!);
      final name = raw.endsWith('ExecuteSystem') ? raw : '${raw}ExecuteSystem';
      buffer.writeln('    addSystem($name());');
    }

    buffer.writeln('  }');
    buffer.writeln('}');
    return buffer.toString();
  }
}
```

- [ ] **Step 2b: Run feature generator test — all must pass**

```bash
cd generator && dart test test/feature_generator_test.dart
```

Expected: all pass.

### Step 3: Update ecs_generator_test.dart and run full suite

- [ ] **Step 3a: Rewrite `generator/test/ecs_generator_test.dart`**

```dart
// Full test suite — imports all individual test files.
import 'component_generator_test.dart' as component;
import 'event_generator_test.dart' as event;
import 'dependency_generator_test.dart' as dependency;
import 'reactive_system_generator_test.dart' as reactive;
import 'initialize_system_generator_test.dart' as initialize;
import 'teardown_system_generator_test.dart' as teardown;
import 'cleanup_system_generator_test.dart' as cleanup;
import 'execute_system_generator_test.dart' as execute;
import 'feature_generator_test.dart' as feature;

void main() {
  component.main();
  event.main();
  dependency.main();
  reactive.main();
  initialize.main();
  teardown.main();
  cleanup.main();
  execute.main();
  feature.main();
}
```

- [ ] **Step 3b: Run the full test suite — all must pass**

```bash
cd generator && dart test test/ecs_generator_test.dart --reporter expanded
```

Expected: all tests pass. Diagnose and fix any failures before proceeding.

- [ ] **Step 3c: Commit**

```bash
git add generator/lib/src/generators/feature_generator.dart generator/test/feature_generator_test.dart generator/test/ecs_generator_test.dart
git commit -m "feat: new ECS DSL — filename-based FeatureGenerator"
```

---

## Task 6: Update example files

**Files:**
- Modify: `example/lib/features/**/*.dart` — rewrite each feature file to the new DSL

For each existing example feature file:
1. Remove old `@ECSFeatureDefinition`, `@ECSComponentDefinition`, `@ECSReactiveSystemDefinition` etc.
2. Change `part 'xxx.ecs.dart'` → `part 'xxx.ecs.g.dart'`
3. Add `@Component()` to component variables (make non-const, typed)
4. Add `@Event()` to event functions (move from const variables to void functions)
5. Replace system annotations with `@ReactiveSystem()`, `@InitializeSystem()` etc.
6. Remove `ECSSystemReference system` parameter from system functions
7. Replace `system.getComponent(foo)` with direct `foo` references
8. Delete old generated `.ecs.dart` files if they exist

- [ ] **Step 1: List all example feature files**

```bash
find example/lib/features -name "*.dart" | grep -v ".ecs" | sort
```

- [ ] **Step 2: Rewrite each feature file**

For each feature file found in Step 1, apply the transformation described above. The example in the spec (`user_auth_feature.dart`) is a complete reference.

- [ ] **Step 3: Run `dart analyze` on the example to check for errors**

```bash
cd example && dart analyze lib/
```

Expected: no errors in feature source files (the generated `.ecs.g.dart` files won't exist yet, but the source should be valid).

- [ ] **Step 4: Run the generator to regenerate all `.ecs.g.dart` files**

```bash
cd example && dart run build_runner build --delete-conflicting-outputs
```

Expected: generates `.ecs.g.dart` files for all feature files with a matching part directive.

- [ ] **Step 5: Commit**

```bash
git add example/
git commit -m "feat: update example to new ECS DSL"
```

---

## Final verification

- [ ] **Run full generator test suite**

```bash
cd generator && dart test test/ecs_generator_test.dart --reporter expanded
```

Expected: all tests pass.

- [ ] **Run example analyzer**

```bash
cd example && dart analyze lib/
```

Expected: no analysis errors.
