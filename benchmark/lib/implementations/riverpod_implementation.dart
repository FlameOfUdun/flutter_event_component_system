import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/benchmark_models.dart';

/// Riverpod Implementation for benchmarking

// Counter Providers
class CounterNotifier extends StateNotifier<CounterModel> {
  CounterNotifier() : super(const CounterModel(0));
  
  void increment() {
    state = CounterModel(state.value + 1);
  }
  
  void decrement() {
    state = CounterModel(state.value - 1);
  }
  
  void reset() {
    state = const CounterModel(0);
  }
}

final counterProvider = StateNotifierProvider<CounterNotifier, CounterModel>(
  (ref) => CounterNotifier(),
);

// Todo Providers
class TodoNotifier extends StateNotifier<TodoListModel> {
  TodoNotifier() : super(const TodoListModel());
  
  void addItem(TodoItem item) {
    state = state.addItem(item);
  }
  
  void removeItem(String id) {
    state = state.removeItem(id);
  }
  
  void toggleItem(String id) {
    state = state.toggleItem(id);
  }
  
  void setFilter(String filter) {
    state = state.setFilter(filter);
  }
  
  void clearCompleted() {
    state = state.clearCompleted();
  }
}

final todoProvider = StateNotifierProvider<TodoNotifier, TodoListModel>(
  (ref) => TodoNotifier(),
);

final filteredTodosProvider = Provider<List<TodoItem>>((ref) {
  final todoList = ref.watch(todoProvider);
  return todoList.filteredItems;
});

final activeCountProvider = Provider<int>((ref) {
  final todoList = ref.watch(todoProvider);
  return todoList.activeCount;
});

final completedCountProvider = Provider<int>((ref) {
  final todoList = ref.watch(todoProvider);
  return todoList.completedCount;
});

// User Profile Providers
class UserProfileNotifier extends StateNotifier<UserProfile?> {
  UserProfileNotifier() : super(null);
  
  void updateUser(UserProfile user) {
    state = user;
  }
  
  void login(UserProfile user) {
    state = user;
  }
  
  void logout() {
    state = null;
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile?>(
  (ref) => UserProfileNotifier(),
);

final isLoggedInProvider = Provider<bool>((ref) {
  final user = ref.watch(userProfileProvider);
  return user != null;
});

// Loading Providers
class LoadingNotifier extends StateNotifier<bool> {
  LoadingNotifier() : super(false);
  
  void startLoading() {
    state = true;
  }
  
  void stopLoading() {
    state = false;
  }
}

final loadingProvider = StateNotifierProvider<LoadingNotifier, bool>(
  (ref) => LoadingNotifier(),
);
