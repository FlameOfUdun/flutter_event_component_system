import 'package:flutter_event_component_system/flutter_event_component_system.dart';

class UserDataComponent extends ECSComponent<User?> {
  UserDataComponent() : super(null);

  @override
  String buildDescriptor(User? value) {
    if (value == null) {
      return 'No User Data';
    } else {
      return "User(id: ${value.id}, name: ${value.name}";
    }
  }
}

class User {
  final String id;
  final String name;
  final String email;

  const User({
    required this.id,
    required this.name,
    required this.email,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }
}
