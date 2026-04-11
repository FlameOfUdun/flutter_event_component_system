# Flutter Event Component System Generator

[![pub package](https://img.shields.io/pub/v/flutter_event_component_system_generator.svg)](https://pub.dev/packages/flutter_event_component_system)
[![Apache 2.0 License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)](https://dart.dev)

A `build_runner` code generator for the [`flutter_event_component_system`](https://pub.dev/packages/flutter_event_component_system) (ECS) package. Write your ECS features, entities, and systems declaratively using plain Dart and let the generator produce all the boilerplate class definitions automatically.

---

## Table of Contents

- [Overview](#overview)
- [How It Works](#how-it-works)
- [Installation](#installation)
- [Setup](#setup)
- [Quick Start](#quick-start)
- [Entity Types](#entity-types)
- [System Types](#system-types)
- [Guard Conditions](#guard-conditions)
- [Helper Functions](#helper-functions)
- [Cross-File Features](#cross-file-features)
- [Generated Output](#generated-output)
- [Running the Generator](#running-the-generator)
- [Rules & Constraints](#rules--constraints)

---

## Overview

The `flutter_event_component_system_generator` package analyses your ECS declaration files using the Dart analyzer and generates fully-typed, boilerplate-free ECS classes. All entity variables, component mutations, event triggers, and system logic you write declaratively are automatically translated into proper class definitions that extend the base classes from `flutter_event_component_system`.

Instead of writing:

```dart
// Manually written boilerplate
final class IsLoadingComponent extends ECSComponent<bool> {
  IsLoadingComponent() : super(false);
}

final class DataFetchedEvent extends ECSEvent {}

final class LoadingReactiveSystem extends ECSReactiveSystem {
  @override
  Set get reactsTo {
    return const {DataFetchedEvent};
  }

  @override
  Set get interactsWith {
    return const {IsLoadingComponent};
  }

  @override
  void react() {
    getEntity<IsLoadingComponent>().value = false;
  }
}

final class AuthFeature extends ECSFeature {
  AuthFeature() {
    addEntity(IsLoadingComponent());
    addEntity(DataFetchedEvent());
    addSystem(LoadingReactiveSystem());
  }
}
```

You simply write:

```dart
// Declarative definition — generator handles everything else
final authFeature = ECS.createFeature();
final isLoading = authFeature.addComponent(false);
final dataFetched = authFeature.addEvent();

final onDataFetched = authFeature.addReactiveSystem(
  reactsTo: {dataFetched},
  react: () {
    isLoading.value = false;
  },
);
```

---

## How It Works

The generator runs as a `build_runner` builder and processes each `.dart` file in your project:

1. **Feature discovery** — `FeatureVisitor` finds every `ECS.createFeature()` call and registers it.
2. **Entity discovery** — `EntityVisitor` finds all `addComponent`, `addEvent`, `addDataEvent`, and `addDependency` calls attached to a known feature.
3. **System discovery** — `SystemVisitor` finds all `addReactiveSystem`, `addExecuteSystem`, `addCleanupSystem`, `addTeardownSystem`, and `addInitializeSystem` calls.
4. **AST rewriting** — All expression bodies are rewritten using the Dart AST, replacing local variable references with proper `getEntity<Type>()` calls.
5. **`interactsWith` inference** — The generator automatically detects which entities each system mutates (via `.value =`, `.update()`, or `.trigger()`) and populates the `interactsWith` set.
6. **Code generation** — A formatted `.ecs.g.dart` `part` file is written alongside each source file.

---

## Installation

Add both the runtime package and this generator to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_event_component_system: ^<latest_version>

dev_dependencies:
  flutter_event_component_system_generator: ^<latest_version>
  build_runner: ^<compatible_verrsion>
```

---

## Setup

### 1. Register the builder

Create a `build.yaml` file at the root of your project:

```yaml
targets:
  $default:
    builders:
      flutter_event_component_system_generator:
        enabled: true
```

### 2. Add the `part` directive

In every file where you declare a feature, add a `part` directive pointing to the generated file:

```dart
// my_feature.dart
part 'my_feature.ecs.g.dart';
```

---

## Quick Start

```dart
// user_profile_feature.dart
import 'package:flutter_event_component_system/flutter_event_component_system.dart';

part 'user_profile_feature.ecs.g.dart';

// 1. Create a feature (one per file)
final userProfileFeature = ECS.createFeature();

// 2. Declare entities
final username      = userProfileFeature.addComponent('');         // ECSComponent<String>
final isLoggedIn    = userProfileFeature.addComponent(false);      // ECSComponent<bool>
final loggedIn      = userProfileFeature.addEvent();               // ECSEvent
final errorOccurred = userProfileFeature.addDataEvent<String>();  // ECSDataEvent<String>

// 3. Declare systems
final onLogin = userProfileFeature.addReactiveSystem(
  reactsTo: {loggedIn},
  react: () {
    isLoggedIn.value = true;
  },
);

final onError = userProfileFeature.addReactiveSystem(
  reactsTo: {errorOccurred},
  react: () {
    isLoggedIn.value = false;
    _logError(errorOccurred.data);
  },
);

void _logError(String message) {
  // handle error
}

final sessionTimer = userProfileFeature.addExecuteSystem(
  executesIf: () {
    return isLoggedIn.value;
  },
  execute: (Duration elapsed) {
    sessionDuration.value += elapsed.inSeconds;
  },
);
```

Run the generator (see [Running the Generator](#running-the-generator)) and `user_profile_feature.ecs.g.dart` will contain all the concrete class definitions.

---

## Entity Types

| Method | Generated Base Class | Description |
| - | - | - |
| `addComponent<T>(defaultValue)` | `ECSComponent<T>` | Stateful data holder with `.value`, `.previous`, `.updatedAt` |
| `addEvent()` | `ECSEvent` | Signal with no payload; carries a `.triggeredAt` timestamp |
| `addDataEvent<T>()` | `ECSDataEvent<T>` | Signal that carries a typed `.data` payload |
| `addDependency<T>(value)` | `ECSDependency<T>` | Externally injected value, accessible across systems |

### Component

```dart
final pageIndex    = myFeature.addComponent(0);              // ECSComponent<int>
final searchQuery  = myFeature.addComponent('');             // ECSComponent<String>
final currentUser  = myFeature.addComponent<User?>(null);    // ECSComponent<User?>
```

Accessing component state in a system body:

```dart
react: () {
  pageIndex.value;                                // current value
  pageIndex.previous;                             // value before last update
  pageIndex.updatedAt;                            // DateTime of last update
  pageIndex.value = 2;                            // direct assignment
  pageIndex.update(2, notify: true, force: false); // explicit update with options
},
```

### Events

```dart
final formSubmitted  = myFeature.addEvent();                  // no payload
final userSelected   = myFeature.addDataEvent<String>();      // carries a String id

// In a system body:
react: () {
  formSubmitted.trigger();                // fire the event
  userSelected.trigger('user-123');       // fire with payload
  userSelected.data;                      // read the payload
  userSelected.triggeredAt;              // DateTime last triggered
},
```

### Dependency

```dart
final apiService = myFeature.addDependency<ApiService>(ApiService());
```

---

## System Types

### Reactive System

Triggers in response to one or more entities changing (component updated or event fired).

```dart
final onSubmit = myFeature.addReactiveSystem(
  reactsTo: {formSubmitted},
  react: () {
    isLoading.value = true;
    submitForm.trigger();
  },
);
```

### Execute System

Runs every tick/frame. Receives the `Duration` elapsed since the last tick.

```dart
final countdownSystem = myFeature.addExecuteSystem(
  execute: (Duration elapsed) {
    timeRemaining.value -= elapsed.inSeconds;
  },
);
```

### Cleanup System

Runs to reset or flush transient per-frame state.

```dart
final clearNotifications = myFeature.addCleanupSystem(
  cleanup: () {
    pendingNotificationCount.value = 0;
  },
);
```

### Initialize System

Runs once when the feature is first initialized.

```dart
final setup = myFeature.addInitializeSystem(
  initialize: () {
    pageIndex.value = 0;
    isLoading.value = false;
  },
);
```

### Teardown System

Runs when the feature is being disposed.

```dart
final dispose = myFeature.addTeardownSystem(
  teardown: () {
    currentUser.value = null;
    isLoggedIn.value = false;
  },
);
```

---

## Guard Conditions

Every system type (except teardown) supports an optional guard. The system only executes when the guard returns `true`.

| System | Guard Parameter |
| - | - |
| `addReactiveSystem` | `reactsIf` |
| `addExecuteSystem` | `executesIf` |
| `addCleanupSystem` | `cleansIf` |

```dart
final onUserSelected = myFeature.addReactiveSystem(
  reactsTo: {userSelected},
  reactsIf: () {
    return isLoggedIn.value;
  },   // only react when authenticated
  react: () {
    activeUserId.value = userSelected.data;
  },
);

final countdownSystem = myFeature.addExecuteSystem(
  executesIf: () {
    return timeRemaining.value > 0;
  },  // stop when timer reaches zero
  execute: (Duration elapsed) {
    timeRemaining.value -= elapsed.inSeconds;
  },
);
```

---

## Helper Functions

You can call top-level helper functions from within system bodies. The generator resolves them automatically — including transitive call chains — and rewrites all entity references before inlining them into the generated class.

```dart
final onSubmit = myFeature.addReactiveSystem(
  reactsTo: {formSubmitted},
  react: () {
    _processForm();
  },
);

void _processForm() {
  final sanitized = _sanitizeInput(inputText.value);
  inputText.value = sanitized;
}

String _sanitizeInput(String raw) {
  return raw.trim().toLowerCase();
}
```

The generator walks the call graph from `_processForm`, discovers `_sanitizeInput`, rewrites all entity accesses (e.g. `inputText` → `getEntity<InputTextComponent>()`), and includes both helpers in the generated system class.

---

## Cross-File Features

Entities declared in imported files are fully resolved. When feature B imports feature A, the generator scans all transitive imports and resolves entity references across file boundaries.

```dart
// session_feature.dart
import 'package:flutter_event_component_system/flutter_event_component_system.dart';

part 'session_feature.ecs.g.dart';

final sessionFeature = ECS.createFeature();
final authToken = sessionFeature.addComponent<String?>(null);
```

```dart
// settings_feature.dart
import 'package:flutter_event_component_system/flutter_event_component_system.dart';
import 'session_feature.dart';

part 'settings_feature.ecs.g.dart';

final settingsFeature = ECS.createFeature();
final settingsSaved = settingsFeature.addEvent();

final onSettingsSaved = settingsFeature.addReactiveSystem(
  reactsTo: {settingsSaved},
  react: () {
    // cross-file entity reference — fully supported
    if (authToken.value == null) return;
    syncSettings.trigger();
  },
);
```

---

## Generated Output

For the quick-start example, the generator produces `user_profile_feature.ecs.g.dart`:

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_feature.dart';

final class UsernameComponent extends ECSComponent<String> {
  UsernameComponent() : super('');
}

final class IsLoggedInComponent extends ECSComponent<bool> {
  IsLoggedInComponent() : super(false);
}

final class LoggedInEvent extends ECSEvent {}

final class ErrorOccurredEvent extends ECSDataEvent<String> {}

final class OnLoginReactiveSystem extends ECSReactiveSystem {
  @override
  Set get reactsTo {
    return const {LoggedInEvent};
  }

  @override
  Set get interactsWith {
    return const {IsLoggedInComponent};
  }

  @override
  void react() {
    getEntity<IsLoggedInComponent>().value = true;
  }
}

final class OnErrorReactiveSystem extends ECSReactiveSystem {
  @override
  Set get reactsTo {
    return const {ErrorOccurredEvent};
  }

  @override
  Set get interactsWith {
    return const {IsLoggedInComponent};
  }

  @override
  void react() {
    getEntity<IsLoggedInComponent>().value = false;
    _logError(getEntity<ErrorOccurredEvent>().data);
  }

  void _logError(String message) {
    // handle error
  }
}

final class UserProfileFeature extends ECSFeature {
  UserProfileFeature() {
    addEntity(UsernameComponent());
    addEntity(IsLoggedInComponent());
    addEntity(LoggedInEvent());
    addEntity(ErrorOccurredEvent());
    addSystem(OnLoginReactiveSystem());
    addSystem(OnErrorReactiveSystem());
  }
}
```

Key things to note in the generated output:

- All local variable references (e.g. `isLoggedIn`, `errorOccurred`) are rewritten to `getEntity<Type>()` calls.
- The `interactsWith` set is **automatically inferred** — you never write it manually.
- Guard conditions become getter overrides on the generated class.
- Helper functions are resolved, rewritten, and inlined into the system class.
- The feature class registers all entities and systems in its constructor.

---

## Running the Generator

**One-time build:**

```bash
dart run build_runner build
```

**Watch mode** (re-generates on every file save):

```bash
dart run build_runner watch
```

**Clean conflicting outputs first:**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated `.ecs.g.dart` files are deterministic and should be **committed to version control**.

---

## Rules & Constraints

- **One feature per file** — each `.dart` file must contain exactly one `ECS.createFeature()` call. Files with more than one feature log a warning and produce no output.
- **Function body required** — `react`, `execute`, `cleanup`, `initialize`, `teardown`, and guard parameters must be function body expressions, not references to named functions and not lambdas.
- **Top-level declarations only** — features, entities, and systems must be top-level variables, not members of a class or locals inside a function.
- **`part` directive required** — the source file must include `part '<filename>.ecs.g.dart';` to use the generated code.
- **Auto-naming** — missing suffixes are appended automatically: `isLoading` → `IsLoadingComponent`, `formSubmitted` → `FormSubmittedEvent`, `onLogin` → `OnLoginReactiveSystem`.
