import 'package:flutter_event_component_system/flutter_event_component_system.dart';
import '../models/benchmark_models.dart';

/// ECS Implementation for benchmarking

// Counter Feature
class CounterFeature extends ECSFeature {
  CounterFeature() {
    addEntity(CounterComponent());

    addEntity(IncrementEvent());
    addEntity(DecrementEvent());
    addEntity(ResetCounterEvent());

    addSystem(IncrementCounterSystem());
    addSystem(DecrementCounterSystem());
    addSystem(ResetCounterSystem());
  }
}

class CounterComponent extends ECSComponent<CounterModel> {
  CounterComponent() : super(const CounterModel(0));
}

class IncrementEvent extends ECSEvent {}

class DecrementEvent extends ECSEvent {}

class ResetCounterEvent extends ECSEvent {}

class IncrementCounterSystem extends ReactiveSystem {
  @override
  Set<Type> get reactsTo => {IncrementEvent};

  @override
  void react() {
    final counter = getEntity<CounterComponent>();
    counter.update(counter.value.increment());
  }
}

class DecrementCounterSystem extends ReactiveSystem {
  @override
  Set<Type> get reactsTo => {DecrementEvent};

  @override
  void react() {
    final counter = getEntity<CounterComponent>();
    counter.update(counter.value.decrement());
  }
}

class ResetCounterSystem extends ReactiveSystem {
  @override
  Set<Type> get reactsTo => {ResetCounterEvent};

  @override
  void react() {
    final counter = getEntity<CounterComponent>();
    counter.update(counter.value.reset());
  }
}

// Todo Feature
class TodoFeature extends ECSFeature {
  TodoFeature() {
    addEntity(TodoListComponent());

    addEntity(AddTodoEvent());
    addEntity(RemoveTodoEvent());
    addEntity(ToggleTodoEvent());
    addEntity(SetFilterEvent());
    addEntity(ClearCompletedEvent());

    addSystem(AddTodoSystem());
    addSystem(RemoveTodoSystem());
    addSystem(ToggleTodoSystem());
    addSystem(SetFilterSystem());
    addSystem(ClearCompletedSystem());
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
  @override
  Set<Type> get reactsTo => {AddTodoEvent};

  @override
  void react() {
    final todoList = getEntity<TodoListComponent>();
    final addEvent = getEntity<AddTodoEvent>();
    todoList.update(todoList.value.addItem(addEvent.item!));
  }
}

class RemoveTodoSystem extends ReactiveSystem {
  @override
  Set<Type> get reactsTo => {RemoveTodoEvent};

  @override
  void react() {
    final todoList = getEntity<TodoListComponent>();
    final removeEvent = getEntity<RemoveTodoEvent>();
    todoList.update(todoList.value.removeItem(removeEvent.id!));
  }
}

class ToggleTodoSystem extends ReactiveSystem {
  @override
  Set<Type> get reactsTo => {ToggleTodoEvent};

  @override
  void react() {
    final todoList = getEntity<TodoListComponent>();
    final toggleEvent = getEntity<ToggleTodoEvent>();
    todoList.update(todoList.value.toggleItem(toggleEvent.id!));
  }
}

class SetFilterSystem extends ReactiveSystem {
  @override
  Set<Type> get reactsTo => {SetFilterEvent};

  @override
  void react() {
    final todoList = getEntity<TodoListComponent>();
    final setFilterEvent = getEntity<SetFilterEvent>();
    todoList.update(todoList.value.setFilter(setFilterEvent.filter!));
  }
}

class ClearCompletedSystem extends ReactiveSystem {
  @override
  Set<Type> get reactsTo => {ClearCompletedEvent};

  @override
  void react() {
    final todoList = getEntity<TodoListComponent>();
    todoList.update(todoList.value.clearCompleted());
  }
}

// User Profile Feature
class UserProfileFeature extends ECSFeature {
  UserProfileFeature() {
    addEntity(UserProfileComponent());
    
    addEntity(UpdateUserEvent());
    addEntity(LoginEvent());
    addEntity(LogoutEvent());

    addSystem(UpdateUserSystem());
    addSystem(LoginSystem());
    addSystem(LogoutSystem());
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
  @override
  Set<Type> get reactsTo => {UpdateUserEvent};

  @override
  void react() {
    final userProfile = getEntity<UserProfileComponent>();
    final updateEvent = getEntity<UpdateUserEvent>();
    userProfile.update(updateEvent.user);
  }
}

class LoginSystem extends ReactiveSystem {
  @override
  Set<Type> get reactsTo => {LoginEvent};

  @override
  void react() {
    final userProfile = getEntity<UserProfileComponent>();
    final loginEvent = getEntity<LoginEvent>();
    userProfile.update(loginEvent.user);
  }
}

class LogoutSystem extends ReactiveSystem {
  @override
  Set<Type> get reactsTo => {LogoutEvent};

  @override
  void react() {
    final userProfile = getEntity<UserProfileComponent>();
    userProfile.update(null);
  }
}

// Loading Feature
class LoadingFeature extends ECSFeature {
  LoadingFeature() {
    addEntity(LoadingComponent());

    addEntity(StartLoadingEvent());
    addEntity(StopLoadingEvent());

    addSystem(StartLoadingSystem());
    addSystem(StopLoadingSystem());
  }
}

class LoadingComponent extends ECSComponent<bool> {
  LoadingComponent() : super(false);
}

class StartLoadingEvent extends ECSEvent {}

class StopLoadingEvent extends ECSEvent {}

class StartLoadingSystem extends ReactiveSystem {
  
  @override
  Set<Type> get reactsTo => {StartLoadingEvent};

  @override
  void react() {
    final loading = getEntity<LoadingComponent>();
    loading.update(true);
  }
}

class StopLoadingSystem extends ReactiveSystem {
  @override
  Set<Type> get reactsTo => {StopLoadingEvent};

  @override
  void react() {
    final loading = getEntity<LoadingComponent>();
    loading.update(false);
  }
}
