import 'package:flutter_event_component_system/flutter_event_component_system.dart';
import '../models/benchmark_models.dart';

/// ECS Implementation for benchmarking

// Counter Feature
class CounterFeature extends ECSFeature {
  CounterFeature(ECSManager manager) {
    addEntity(CounterComponent());

    addEntity(IncrementEvent());
    addEntity(DecrementEvent());
    addEntity(ResetCounterEvent());

    addSystem(IncrementCounterSystem(manager));
    addSystem(DecrementCounterSystem(manager));
    addSystem(ResetCounterSystem(manager));
  }
}

class CounterComponent extends ECSComponent<CounterModel> {
  CounterComponent() : super(const CounterModel(0));
}

class IncrementEvent extends ECSEvent {}

class DecrementEvent extends ECSEvent {}

class ResetCounterEvent extends ECSEvent {}

class IncrementCounterSystem extends ReactiveSystem {
  final ECSManager manager;

  IncrementCounterSystem(this.manager);

  CounterComponent? counter;

  @override
  Set<Type> get reactsTo => {IncrementEvent};

  @override
  void react() {
    counter ??= manager.getEntity<CounterComponent>();
    counter!.update(counter!.value.increment());
  }
}

class DecrementCounterSystem extends ReactiveSystem {
  final ECSManager manager;

  DecrementCounterSystem(this.manager);

  CounterComponent? counter;

  @override
  Set<Type> get reactsTo => {DecrementEvent};

  @override
  void react() {
    counter ??= manager.getEntity<CounterComponent>();
    counter!.update(counter!.value.decrement());
  }
}

class ResetCounterSystem extends ReactiveSystem {
  final ECSManager manager;

  ResetCounterSystem(this.manager);

  CounterComponent? counter;

  @override
  Set<Type> get reactsTo => {ResetCounterEvent};

  @override
  void react() {
    counter ??= manager.getEntity<CounterComponent>();
    counter!.update(counter!.value.reset());
  }
}

// Todo Feature
class TodoFeature extends ECSFeature {
  TodoFeature(ECSManager manager) {
    addEntity(TodoListComponent());

    addEntity(AddTodoEvent());
    addEntity(RemoveTodoEvent());
    addEntity(ToggleTodoEvent());
    addEntity(SetFilterEvent());
    addEntity(ClearCompletedEvent());

    addSystem(AddTodoSystem(manager));
    addSystem(RemoveTodoSystem(manager));
    addSystem(ToggleTodoSystem(manager));
    addSystem(SetFilterSystem(manager));
    addSystem(ClearCompletedSystem(manager));
  }
}

class TodoListComponent extends ECSComponent<TodoListModel> {
  TodoListComponent() : super(const TodoListModel());
}

class AddTodoEvent extends ECSEvent {
  TodoItem? item;

  void triggerWith(TodoItem newItem) {
    item = newItem;
    notifyListeners();
  }
}

class RemoveTodoEvent extends ECSEvent {
  String? id;

  void triggerWith(String newId) {
    id = newId;
    notifyListeners();
  }
}

class ToggleTodoEvent extends ECSEvent {
  String? id;

  void triggerWith(String newId) {
    id = newId;
    notifyListeners();
  }
}

class SetFilterEvent extends ECSEvent {
  String? filter;

  void triggerWith(String newFilter) {
    filter = newFilter;
    notifyListeners();
  }
}

class ClearCompletedEvent extends ECSEvent {}

class AddTodoSystem extends ReactiveSystem {
  final ECSManager manager;

  TodoListComponent? todoList;
  AddTodoEvent? addEvent;

  AddTodoSystem(this.manager);

  @override
  Set<Type> get reactsTo => {AddTodoEvent};

  @override
  void react() {
    todoList ??= manager.getEntity<TodoListComponent>();
    addEvent ??= manager.getEntity<AddTodoEvent>();
    todoList!.update(todoList!.value.addItem(addEvent!.item!));
  }
}

class RemoveTodoSystem extends ReactiveSystem {
  final ECSManager manager;

  TodoListComponent? todoList;
  RemoveTodoEvent? removeEvent;

  RemoveTodoSystem(this.manager);

  @override
  Set<Type> get reactsTo => {RemoveTodoEvent};

  @override
  void react() {
    todoList ??= manager.getEntity<TodoListComponent>();
    removeEvent ??= manager.getEntity<RemoveTodoEvent>();
    todoList!.update(todoList!.value.removeItem(removeEvent!.id!));
  }
}

class ToggleTodoSystem extends ReactiveSystem {
  final ECSManager manager;

  TodoListComponent? todoList;
  ToggleTodoEvent? toggleEvent;

  ToggleTodoSystem(this.manager);

  @override
  Set<Type> get reactsTo => {ToggleTodoEvent};

  @override
  void react() {
    todoList ??= manager.getEntity<TodoListComponent>();
    toggleEvent ??= manager.getEntity<ToggleTodoEvent>();
    todoList!.update(todoList!.value.toggleItem(toggleEvent!.id!));
  }
}

class SetFilterSystem extends ReactiveSystem {
  final ECSManager manager;

  TodoListComponent? todoList;
  SetFilterEvent? setFilterEvent;

  SetFilterSystem(this.manager);

  @override
  Set<Type> get reactsTo => {SetFilterEvent};

  @override
  void react() {
    todoList ??= manager.getEntity<TodoListComponent>();
    setFilterEvent ??= manager.getEntity<SetFilterEvent>();
    todoList!.update(todoList!.value.setFilter(setFilterEvent!.filter!));
  }
}

class ClearCompletedSystem extends ReactiveSystem {
  final ECSManager manager;

  TodoListComponent? todoList;

  ClearCompletedSystem(this.manager);

  @override
  Set<Type> get reactsTo => {ClearCompletedEvent};

  @override
  void react() {
    todoList ??= manager.getEntity<TodoListComponent>();
    todoList!.update(todoList!.value.clearCompleted());
  }
}

// User Profile Feature
class UserProfileFeature extends ECSFeature {
  UserProfileFeature(ECSManager manager) {
    addEntity(UserProfileComponent());
    
    addEntity(UpdateUserEvent());
    addEntity(LoginEvent());
    addEntity(LogoutEvent());

    addSystem(UpdateUserSystem(manager));
    addSystem(LoginSystem(manager));
    addSystem(LogoutSystem(manager));
  }
}

class UserProfileComponent extends ECSComponent<UserProfile?> {
  UserProfileComponent() : super(null);
}

class UpdateUserEvent extends ECSEvent {
  UserProfile? user;

  void triggerWith(UserProfile newUser) {
    user = newUser;
    notifyListeners();
  }
}

class LoginEvent extends ECSEvent {
  UserProfile? user;

  void triggerWith(UserProfile newUser) {
    user = newUser;
    notifyListeners();
  }
}

class LogoutEvent extends ECSEvent {}

class UpdateUserSystem extends ReactiveSystem {
  final ECSManager manager;

  UserProfileComponent? userProfile;
  UpdateUserEvent? updateEvent;

  UpdateUserSystem(this.manager);

  @override
  Set<Type> get reactsTo => {UpdateUserEvent};

  @override
  void react() {
    userProfile ??= manager.getEntity<UserProfileComponent>();
    updateEvent ??= manager.getEntity<UpdateUserEvent>();
    userProfile!.update(updateEvent!.user);
  }
}

class LoginSystem extends ReactiveSystem {
  final ECSManager manager;

  UserProfileComponent? userProfile;
  LoginEvent? loginEvent;

  LoginSystem(this.manager);

  @override
  Set<Type> get reactsTo => {LoginEvent};

  @override
  void react() {
    userProfile ??= manager.getEntity<UserProfileComponent>();
    loginEvent ??= manager.getEntity<LoginEvent>();
    userProfile!.update(loginEvent!.user);
  }
}

class LogoutSystem extends ReactiveSystem {
  final ECSManager manager;

  UserProfileComponent? userProfile;

  LogoutSystem(this.manager);

  @override
  Set<Type> get reactsTo => {LogoutEvent};

  @override
  void react() {
    userProfile ??= manager.getEntity<UserProfileComponent>();
    userProfile!.update(null);
  }
}

// Loading Feature
class LoadingFeature extends ECSFeature {
  LoadingFeature(ECSManager manager) {
    addEntity(LoadingComponent());

    addEntity(StartLoadingEvent());
    addEntity(StopLoadingEvent());

    addSystem(StartLoadingSystem(manager));
    addSystem(StopLoadingSystem(manager));
  }
}

class LoadingComponent extends ECSComponent<bool> {
  LoadingComponent() : super(false);
}

class StartLoadingEvent extends ECSEvent {}

class StopLoadingEvent extends ECSEvent {}

class StartLoadingSystem extends ReactiveSystem {
  final ECSManager manager;

  LoadingComponent? loading;

  StartLoadingSystem(this.manager);

  @override
  Set<Type> get reactsTo => {StartLoadingEvent};

  @override
  void react() {
    loading ??= manager.getEntity<LoadingComponent>();
    loading!.update(true);
  }
}

class StopLoadingSystem extends ReactiveSystem {
  final ECSManager manager;

  LoadingComponent? loading;

  StopLoadingSystem(this.manager);

  @override
  Set<Type> get reactsTo => {StopLoadingEvent};

  @override
  void react() {
    loading ??= manager.getEntity<LoadingComponent>();
    loading!.update(false);
  }
}
