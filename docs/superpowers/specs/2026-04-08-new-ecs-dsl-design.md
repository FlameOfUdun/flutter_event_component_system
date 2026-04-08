# New ECS DSL Design

**Date:** 2026-04-08
**Status:** Approved for implementation

---

## Goal

Replace the current annotation-heavy, const-variable-based DSL with a natural Dart DSL where components are typed variables, events are functions, and system bodies read like normal code. The generator handles all class scaffolding invisibly.

---

## 1. Opt-in Signal

A file opts into ECS generation by declaring a `part` directive whose filename ends with `.ecs.g.dart`:

```dart
part 'timer_feature.ecs.g.dart';
```

The builder scans all Dart files in the project. Any file containing such a `part` directive is treated as an ECS feature file. No `@Feature` annotation is needed. The generated file is named `<source_filename>.ecs.g.dart`.

The generated `Feature` class name is derived from the source filename:
- `timer_feature.dart` → `TimerFeature`
- `user_auth_feature.dart` → `UserAuthFeature`

---

## 2. Annotations Package

The `flutter_event_component_system_annotations` package exports exactly these annotation classes and nothing else. All existing `ECSXxxDefinition`, `ECSXxxReference`, and `ECSSystemReference` classes are removed.

### Entity annotations

```dart
/// Marks a top-level variable as an ECS component.
/// The variable's type is the component's value type.
/// The variable's initializer is the default value.
final class Component {
  final String? description;
  const Component({this.description});
}

/// Marks a top-level function as an ECS event.
/// The generator infers the event kind from the function signature:
/// - No parameters → no-data event (ECSEvent)
/// - One parameter  → data event (ECSDataEvent<T>) where T is the parameter type
/// The function body lists the systems that react to this event.
/// The body is never executed at runtime — it is a declaration for the generator only.
final class Event {
  final String? description;
  const Event({this.description});
}

/// Marks a top-level variable as an ECS dependency.
/// The variable's type is the dependency's value type.
/// The variable's initializer is the default value.
final class Dependency {
  final String? description;
  const Dependency({this.description});
}
```

### System annotations

All system annotations are parameter-free (except `description`). `reactsTo` and `interactsWith` are both fully auto-detected by the generator.

```dart
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
```

---

## 3. Source DSL

### 3.1 Components

A top-level variable annotated with `@Component()`. The variable's type is the component's value type. The variable's initializer is the default value.

```dart
@Component() int health = 0;
@Component() AuthState authState = AuthState.unknown;
@Component() Duration timerValue = Duration.zero;
```

**Constraint:** The default value must be a valid Dart constant expression.

### 3.2 Events

A top-level `void` function annotated with `@Event()`. The generator infers the event kind from the parameter list. The function body calls the systems that react to this event — it is a pure declaration, never executed at runtime.

**No-data event** — no parameters:

```dart
@Event()
void logout() {
  logoutSystem();
  cleanupSession();
}
```

**Data event** — exactly one parameter, whose type becomes the event's data type:

```dart
@Event()
void login(LoginCredentials credentials) {
  loginSystem(credentials);
}

@Event()
void addHealth(int amount) {
  applyAddHealth(amount);
}
```

**Constraint:** Events must have zero or one parameter. Multi-parameter events are a generator error.

### 3.3 Dependencies

A top-level variable annotated with `@Dependency()`. Same rules as `@Component()`.

```dart
@Dependency() AuthRepository authRepo = AuthRepository();
```

### 3.4 Systems

All system types are top-level functions annotated with the appropriate annotation. The function body is plain Dart code. The generator rewrites component access and event calls (see Section 4), auto-detects `reactsTo` from event bodies, and auto-detects `interactsWith` from writes in the system body and its private helpers.

**Reactive system:**

A reactive system's parameter list matches the event's parameter list. If the event carries data, the system receives it as a plain parameter — the generator injects the event's data at each use site.

```dart
@ReactiveSystem()
void loginSystem(LoginCredentials credentials) {
  _performLogin(credentials).ignore();
}

@ReactiveSystem()
void applyAddHealth(int amount) {
  health += amount;
}

// No-data — no parameters
@ReactiveSystem()
void logoutSystem() {
  _performLogout().ignore();
}
```

**Initialize system:**

```dart
@InitializeSystem()
void startTimerInitialize() {
  timerStart();
}
```

**Teardown system:**

```dart
@TeardownSystem()
void disposeAuth() {
  authState = AuthState.unknown;
}
```

**Execute system** — receives `Duration elapsed` as its only parameter:

```dart
@ExecuteSystem()
void updateTimer(Duration elapsed) {
  if (timerState != TimerState.running) return;
  timerValue = timerValue + elapsed;
}
```

**Cleanup system:**

```dart
@CleanupSystem()
void cleanupLogin() {
  loginProcess = const LoginProcess.idle();
}
```

### 3.5 Private helpers

Plain top-level functions without any ECS annotation are structural — not turned into separate classes. Component assignments and event calls inside them are rewritten, and any writes they perform are included in the owning system's auto-detected `interactsWith`.

```dart
Future<void> _performLogin(LoginCredentials credentials) async {
  loginProcess = const LoginProcess.running();  // → detected write
  authState = AuthState.loggedIn;               // → detected write
}
```

**Scope rule:** A private helper is attributed to the system that calls it (directly or transitively) within the same file. If called by multiple systems, its writes are attributed to all of them.

---

## 4. Generator Rewrites

### 4.1 Component / dependency reads

Any bare read of an annotated variable in expression context is rewritten:

| Source                               | Generated                                |
|--------------------------------------|------------------------------------------|
| `health` (in expression context)     | `getEntity<HealthComponent>().value`     |
| `timerState` (in expression context) | `getEntity<TimerStateComponent>().value` |

### 4.2 Component / dependency writes

Any assignment to an annotated variable is rewritten using `.value`. Compound assignments are preserved:

| Source                           | Generated                                                    |
|----------------------------------|--------------------------------------------------------------|
| `health = 0`                     | `getEntity<HealthComponent>().value = 0`                     |
| `health += amount`               | `getEntity<HealthComponent>().value += amount`               |
| `authState = AuthState.loggedIn` | `getEntity<AuthStateComponent>().value = AuthState.loggedIn` |

### 4.3 No-data event calls

Any call to a no-data `@Event` function inside a system body is rewritten:

| Source         | Generated                                |
|----------------|------------------------------------------|
| `timerStart()` | `getEntity<TimerStartEvent>().trigger()` |
| `logout()`     | `getEntity<LogoutEvent>().trigger()`     |

### 4.4 Data event calls

Any call to a data `@Event` function inside a system body is rewritten:

| Source                | Generated                                      |
|-----------------------|------------------------------------------------|
| `addHealth(10)`       | `getEntity<AddHealthEvent>().trigger(10)`      |
| `login(credentials)`  | `getEntity<LoginEvent>().trigger(credentials)` |

### 4.5 Auto-detection of `reactsTo`

The generator reads each `@Event` function body. Every call to a `@ReactiveSystem` function inside that body registers that system as reacting to the event.

```dart
@Event()
void login(LoginCredentials credentials) {
  loginSystem(credentials);   // → loginSystem reactsTo LoginEvent
}

@Event()
void timerStart() {
  startTimer();               // → startTimer reactsTo TimerStartEvent
  resetTimerDisplay();        // → resetTimerDisplay reactsTo TimerStartEvent
}
```

The data payload injection: if the system has a parameter and the event has a matching parameter, the generator replaces every use of that parameter in the system body with `getEntity<LoginEvent>().data`.

### 4.6 Auto-detection of `interactsWith`

The generator scans the system body and all private helpers transitively called from it. It collects every:

- Component or dependency that is **written to** (any assignment, including `+=`, `-=`, etc.)
- Event that is **triggered** (called as a function)

Components/dependencies that are only **read** are not included.

| Detected in body                    | Added to `interactsWith` |
|-------------------------------------|--------------------------|
| `health = x`                        | `HealthComponent`        |
| `health += x`                       | `HealthComponent`        |
| `timerStart()`                      | `TimerStartEvent`        |
| `if (authState == ...)` (read only) | *(not added)*            |

### 4.7 Scope of rewrites

Rewrites apply to:

- Annotated system function bodies
- Private (underscore-prefixed) top-level function bodies in the same file

Rewrites do **not** apply to:

- `@Event` function bodies (declaration-only, never emitted to generated output)
- Model/enum/class definitions
- Function signatures (parameter types, return types)

---

## 5. Generated Output

### 5.1 Per-entity classes

```dart
// @Component() int health = 0
final class HealthComponent extends ECSComponent<int> {
  HealthComponent([super.value = 0]);
}

// @Event() void timerStart() { ... }
final class TimerStartEvent extends ECSEvent {}

// @Event() void addHealth(int amount) { ... }
final class AddHealthEvent extends ECSDataEvent<int> {
  @override
  void trigger([int data = 0]) => super.trigger(data);
}
```

### 5.2 System classes

`reactsTo` and `interactsWith` are both auto-populated. Private helpers become private methods on the generated system class.

```dart
final class LoginSystemReactiveSystem extends ECSReactiveSystem {
  @override
  Set<Type> get reactsTo => const {LoginEvent};

  @override
  Set<Type> get interactsWith => const {LoginProcessComponent, AuthStateComponent};

  @override
  void react() {
    _performLogin(getEntity<LoginEvent>().data).ignore();
  }

  Future<void> _performLogin(LoginCredentials credentials) async {
    getEntity<LoginProcessComponent>().value = const LoginProcess.running();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('auth_state', AuthState.loggedIn.name);
    await Future.delayed(const Duration(seconds: 2));
    getEntity<LoginProcessComponent>().value = const LoginProcess.success('mock_token');
    getEntity<AuthStateComponent>().value = AuthState.loggedIn;
  }
}
```

### 5.3 Feature class

Auto-generated from filename, registers all annotated entities and systems:

```dart
final class UserAuthFeature extends ECSFeature {
  UserAuthFeature() {
    addEntity(AuthStateComponent());
    addEntity(LoginProcessComponent());
    addEntity(LogoutProcessComponent());
    addEntity(LoginEvent());
    addEntity(LogoutEvent());
    addEntity(ReloadUserEvent());
    addSystem(ReloadUserSystemReactiveSystem());
    addSystem(LoginSystemReactiveSystem());
    addSystem(LogoutSystemReactiveSystem());
  }
}
```

---

## 6. Complete Example

### Source (`user_auth_feature.dart`)

```dart
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'user_auth_feature.ecs.g.dart';

enum AuthState { unknown, loggedIn, loggedOut, mfaRequired }

class LoginCredentials {
  final String username;
  final String password;
  const LoginCredentials({required this.username, required this.password});
}

// Components
@Component() AuthState authState = AuthState.unknown;
@Component() LoginProcess loginProcess = const LoginProcess.idle();
@Component() LogoutProcess logoutProcess = const LogoutProcess.idle();

// Events — bodies are declarations only, never executed at runtime
@Event()
void reloadUser() {
  reloadUserSystem();
}

@Event()
void logout() {
  logoutSystem();
}

@Event()
void login(LoginCredentials credentials) {
  loginSystem(credentials);
}

// Systems
@ReactiveSystem()
void reloadUserSystem() {
  _performReload().ignore();
}

Future<void> _performReload() async {
  final preferences = await SharedPreferences.getInstance();
  final value = preferences.getString('auth_state');
  authState = value == null
      ? AuthState.loggedOut
      : AuthState.values.byName(value);
}

@ReactiveSystem()
void loginSystem(LoginCredentials credentials) {
  _performLogin(credentials).ignore();
}

Future<void> _performLogin(LoginCredentials credentials) async {
  loginProcess = const LoginProcess.running();
  final preferences = await SharedPreferences.getInstance();
  await preferences.setString('auth_state', AuthState.loggedIn.name);
  await Future.delayed(const Duration(seconds: 2));
  loginProcess = const LoginProcess.success('mock_token');
  authState = AuthState.loggedIn;
}

@ReactiveSystem()
void logoutSystem() {
  _performLogout().ignore();
}

Future<void> _performLogout() async {
  logoutProcess = const LogoutProcess.running();
  final preferences = await SharedPreferences.getInstance();
  await preferences.setString('auth_state', AuthState.loggedOut.name);
  await Future.delayed(const Duration(seconds: 2));
  logoutProcess = const LogoutProcess.success();
  authState = AuthState.loggedOut;
}
```

---

## 7. Breaking Changes

This is a **full breaking change** to the developer-facing DSL:

- All `ECSXxxDefinition` and `ECSXxxReference` annotation classes removed
- All source files using the old DSL must be rewritten to the new one
- Generated file extension changes from `.ecs.dart` to `.ecs.g.dart`
- The `build.yaml` builder configuration must be updated to target `.ecs.g.dart`

The runtime (`flutter_event_component_system`) and generated class structure are unchanged.

---

## 8. Out of Scope

- Migration tooling / codemod for existing projects
- IDE plugin or analysis server extension
- `@Component()` with non-const defaults (compile error)
- Multi-file entity cross-referencing in `reactsTo` (already supported via `TypeChecker`)
