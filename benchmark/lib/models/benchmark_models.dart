import 'package:meta/meta.dart';

/// Simple counter model for basic benchmarks
@immutable
class CounterModel {
  final int value;

  const CounterModel(this.value);

  CounterModel increment() => CounterModel(value + 1);
  CounterModel decrement() => CounterModel(value - 1);
  CounterModel reset() => const CounterModel(0);
}

/// Todo item model
@immutable
class TodoItem {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;

  const TodoItem({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
  });

  TodoItem copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Todo list model
@immutable
class TodoListModel {
  final List<TodoItem> items;
  final String filter; // 'all', 'active', 'completed'

  const TodoListModel({
    this.items = const [],
    this.filter = 'all',
  });

  TodoListModel addItem(TodoItem item) {
    return TodoListModel(
      items: [...items, item],
      filter: filter,
    );
  }

  TodoListModel removeItem(String id) {
    return TodoListModel(
      items: items.where((item) => item.id != id).toList(),
      filter: filter,
    );
  }

  TodoListModel toggleItem(String id) {
    return TodoListModel(
      items: items.map((item) => item.id == id ? item.copyWith(isCompleted: !item.isCompleted) : item).toList(),
      filter: filter,
    );
  }

  TodoListModel setFilter(String newFilter) {
    return TodoListModel(items: items, filter: newFilter);
  }

  TodoListModel clearCompleted() {
    return TodoListModel(
      items: items.where((item) => !item.isCompleted).toList(),
      filter: filter,
    );
  }

  List<TodoItem> get filteredItems {
    switch (filter) {
      case 'active':
        return items.where((item) => !item.isCompleted).toList();
      case 'completed':
        return items.where((item) => item.isCompleted).toList();
      default:
        return items;
    }
  }

  int get activeCount => items.where((item) => !item.isCompleted).length;
  int get completedCount => items.where((item) => item.isCompleted).length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoListModel && other.filter == filter && other.items.length == items.length && other.items.every((item) => items.contains(item));

  @override
  int get hashCode => Object.hash(items, filter);
}

/// Complex nested data model for performance testing
@immutable
class UserProfile {
  final String id;
  final String name;
  final String email;
  final List<String> tags;
  final Map<String, dynamic> preferences;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.tags = const [],
    this.preferences = const {},
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    List<String>? tags,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      tags: tags ?? this.tags,
      preferences: preferences ?? this.preferences,
    );
  }
}
