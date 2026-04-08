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

/// Marks a top-level void function as a no-data ECS event.
final class Event {
  final String? description;
  const Event({this.description});
}

/// Marks a top-level typed function as a data-carrying ECS event.
/// The function's return type is the event's data type.
/// The function's parameter is the data value.
final class DataEvent {
  final String? description;
  const DataEvent({this.description});
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

```dart
final class ReactiveSystem {
  final Set<Object> reactsTo;
  final Set<Object> interactsWith;
  final String? description;
  const ReactiveSystem({
    required this.reactsTo,
    this.interactsWith = const {},
    this.description,
  });
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

### Parameter annotation

```dart
/// Used on a system function parameter to inject the data payload
/// from the named data event.
final class From {
  final Object event;
  const From(this.event);
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

**Constraint:** The default value must be a valid Dart constant expression (same requirement as today). Non-primitive defaults are allowed as long as they are `const`.

### 3.2 No-data events

A top-level `void` function annotated with `@Event()`. The body is empty — it exists only as an identifier.

```dart
@Event() void logout() {}
@Event() void timerStart() {}
@Event() void reloadUser() {}
```

### 3.3 Data events

A top-level function annotated with `@DataEvent()`. The return type is the data type. The single parameter is the data value. The body returns that parameter (identity function).

```dart
@DataEvent() LoginCredentials login(LoginCredentials credentials) => credentials;
@DataEvent() int addHealth(int amount) => amount;
```

**Constraint:** Exactly one parameter. Return type must match parameter type.

### 3.4 Dependencies

A top-level variable annotated with `@Dependency()`. Same rules as `@Component()`.

```dart
@Dependency() AuthRepository authRepo = AuthRepository();
```

### 3.5 Systems

All system types are top-level functions annotated with the appropriate system annotation. The function body is plain Dart code. The generator rewrites component access and event calls inside the body (see Section 4).

**Reactive system:**

```dart
@ReactiveSystem(reactsTo: {login}, interactsWith: {loginProcess, authState})
void loginSystem(@From(login) LoginCredentials credentials) {
  _performLogin(credentials).ignore();
}
```

- `reactsTo`: set of `@Event` or `@DataEvent` identifiers that trigger this system
- `interactsWith`: set of `@Component` or `@Dependency` identifiers this system reads or writes
- `@From(eventIdentifier)` on a parameter: the generator injects the data event's payload as that parameter's value in the generated `react()` body
- Guard condition (`reactsIf`): expressed as a plain `if` check inside the body — no separate function reference needed

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

**Execute system** (receives `Duration elapsed` as first parameter):

```dart
@ExecuteSystem(interactsWith: {timerValue, timerState})
void updateTimer(Duration elapsed) {
  if (timerState != TimerState.running) return;
  timerValue = timerValue + elapsed;
}
```

**Cleanup system:**

```dart
@CleanupSystem(interactsWith: {loginProcess})
void cleanupLogin() {
  loginProcess = const LoginProcess.idle();
}
```

### 3.6 Private helpers

Plain top-level functions without any ECS annotation are **not touched by the generator**. They can be called from system bodies freely. Component assignments and event calls inside private helpers **are** rewritten by the generator.

```dart
Future<void> _performLogin(LoginCredentials credentials) async {
  loginProcess = const LoginProcess.running();
  // ... async work ...
  authState = AuthState.loggedIn;
}
```

---

## 4. Generator Rewrites

The generator transforms the source body of each system function (and any private helpers declared in the same file) into the generated class body. Rewrites apply to:

### 4.1 Component / dependency reads

Any bare read of an annotated variable identifier is rewritten:

| Source | Generated |
|--------|-----------|
| `health` | `getEntity<HealthComponent>().value` |
| `timerState` | `getEntity<TimerStateComponent>().value` |

Exception: inside `reactsTo` and `interactsWith` annotation arguments, identifiers are resolved to their generated class names (already implemented).

### 4.2 Component / dependency writes (assignment)

Any assignment to an annotated variable is rewritten:

| Source | Generated |
|--------|-----------|
| `health = 0` | `getEntity<HealthComponent>().update(0)` |
| `health += amount` | `getEntity<HealthComponent>().update(getEntity<HealthComponent>().value + amount)` |
| `authState = AuthState.loggedIn` | `getEntity<AuthStateComponent>().update(AuthState.loggedIn)` |

### 4.3 No-data event calls

Any call to an `@Event`-annotated function is rewritten:

| Source | Generated |
|--------|-----------|
| `timerStart()` | `getEntity<TimerStartEvent>().trigger()` |
| `logout()` | `getEntity<LogoutEvent>().trigger()` |

### 4.4 Data event calls

Any call to a `@DataEvent`-annotated function is rewritten:

| Source | Generated |
|--------|-----------|
| `addHealth(10)` | `getEntity<AddHealthEvent>().trigger(10)` |
| `login(credentials)` | `getEntity<LoginEvent>().trigger(credentials)` |

### 4.5 `@From` parameter injection

In a reactive system function, a parameter annotated with `@From(eventIdentifier)` is not declared in the generated class method signature. Instead, its value is inlined at each use site:

| Source | Generated |
|--------|-----------|
| `@From(login) LoginCredentials credentials` | Each use of `credentials` in the body → `getEntity<LoginEvent>().data` |

### 4.6 Scope of rewrites

Rewrites apply to:
- The annotated system function's body
- Any private (underscore-prefixed) top-level function bodies in the same file

Rewrites do **not** apply to:
- Annotation arguments
- Model/enum class definitions
- Function signatures (parameter types, return types)

---

## 5. Generated Output

### 5.1 Per-entity classes

Same as today — one generated class per annotated entity:

```dart
// @Component() int health = 0
final class HealthComponent extends ECSComponent<int> {
  HealthComponent([super.value = 0]);
}

// @Event() void timerStart() {}
final class TimerStartEvent extends ECSEvent {}

// @DataEvent() int addHealth(int amount) => amount
final class AddHealthEvent extends ECSDataEvent<int> {
  @override
  void trigger([int data = 0]) => super.trigger(data);
}
```

### 5.2 System classes

One class per annotated system function, same as today:

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
}
```

Private helper methods become private methods on the generated class (or remain top-level — TBD at implementation time based on what's simpler).

### 5.3 Feature class

Auto-generated from filename, registers all entities and systems discovered in the file:

```dart
final class UserAuthFeature extends ECSFeature {
  UserAuthFeature() {
    addEntity(AuthStateComponent());
    addEntity(LoginProcessComponent());
    addEntity(LogoutProcessComponent());
    addEntity(LoginEvent());
    addEntity(LogoutEvent());
    addEntity(ReloadUserEvent());
    addSystem(LoginSystemReactiveSystem());
    addSystem(LogoutSystemReactiveSystem());
    addSystem(ReloadUserSystemReactiveSystem());
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

// Events
@Event() void reloadUser() {}
@Event() void logout() {}
@DataEvent() LoginCredentials login(LoginCredentials credentials) => credentials;

// Systems
@ReactiveSystem(reactsTo: {reloadUser}, interactsWith: {authState})
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

@ReactiveSystem(reactsTo: {login}, interactsWith: {loginProcess, authState})
void loginSystem(@From(login) LoginCredentials credentials) {
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

@ReactiveSystem(reactsTo: {logout}, interactsWith: {logoutProcess, authState})
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
- `@Component()` with non-const defaults (compile error, same as today)
- Multi-file entity cross-referencing in `reactsTo`/`interactsWith` (already supported via `TypeChecker` from the Issue 4 fix)
