import 'package:flutter/foundation.dart';
import '../models/benchmark_models.dart';

/// Provider Implementation for benchmarking

// Counter Provider
class CounterProvider extends ChangeNotifier {
  CounterModel _counter = const CounterModel(0);
  
  CounterModel get counter => _counter;
  
  void increment() {
    _counter = _counter.increment();
    notifyListeners();
  }
  
  void decrement() {
    _counter = _counter.decrement();
    notifyListeners();
  }
  
  void reset() {
    _counter = _counter.reset();
    notifyListeners();
  }
}

// Todo Provider
class TodoProvider extends ChangeNotifier {
  TodoListModel _todoList = const TodoListModel();
  
  TodoListModel get todoList => _todoList;
  List<TodoItem> get filteredItems => _todoList.filteredItems;
  int get activeCount => _todoList.activeCount;
  int get completedCount => _todoList.completedCount;
  String get filter => _todoList.filter;
  
  void addItem(TodoItem item) {
    _todoList = _todoList.addItem(item);
    notifyListeners();
  }
  
  void removeItem(String id) {
    _todoList = _todoList.removeItem(id);
    notifyListeners();
  }
  
  void toggleItem(String id) {
    _todoList = _todoList.toggleItem(id);
    notifyListeners();
  }
  
  void setFilter(String filter) {
    _todoList = _todoList.setFilter(filter);
    notifyListeners();
  }
  
  void clearCompleted() {
    _todoList = _todoList.clearCompleted();
    notifyListeners();
  }
}

// User Profile Provider
class UserProfileProvider extends ChangeNotifier {
  UserProfile? _currentUser;
  
  UserProfile? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  
  void updateUser(UserProfile user) {
    _currentUser = user;
    notifyListeners();
  }
  
  void login(UserProfile user) {
    _currentUser = user;
    notifyListeners();
  }
  
  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}

// Loading Provider
class LoadingProvider extends ChangeNotifier {
  bool _isLoading = false;
  
  bool get isLoading => _isLoading;
  
  void startLoading() {
    _isLoading = true;
    notifyListeners();
  }
  
  void stopLoading() {
    _isLoading = false;
    notifyListeners();
  }
}

// App State Provider (combines all providers)
class AppStateProvider extends ChangeNotifier {
  final CounterProvider _counter = CounterProvider();
  final TodoProvider _todo = TodoProvider();
  final UserProfileProvider _userProfile = UserProfileProvider();
  final LoadingProvider _loading = LoadingProvider();
  
  CounterProvider get counter => _counter;
  TodoProvider get todo => _todo;
  UserProfileProvider get userProfile => _userProfile;
  LoadingProvider get loading => _loading;
  
  AppStateProvider() {
    _counter.addListener(notifyListeners);
    _todo.addListener(notifyListeners);
    _userProfile.addListener(notifyListeners);
    _loading.addListener(notifyListeners);
  }
  
  @override
  void dispose() {
    _counter.dispose();
    _todo.dispose();
    _userProfile.dispose();
    _loading.dispose();
    super.dispose();
  }
}
