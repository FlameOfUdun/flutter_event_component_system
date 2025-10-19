import 'package:flutter_event_component_system/flutter_event_component_system.dart';

import '../components/loading_error_component.dart';
import '../components/loading_state_component.dart';
import '../components/user_data_component.dart';
import '../events/load_user_event.dart';

class LoadUserDataReactiveSystem extends ReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return const {LoadUserEvent};
  }

  @override
  Set<Type> get interactsWith {
    return const {UserDataComponent, LoadingStateComponent, LoadingErrorComponent};
  }

  @override
  bool get reactsIf {
    final loadEvent = manager.getEntity<LoadUserEvent>();
    final loadingState = manager.getEntity<LoadingStateComponent>();
    return loadEvent.userId != null && loadingState.value != LoadingState.running;
  }

  @override
  void react() async {
    // Retrieve necessary entities
    final loadEvent = manager.getEntity<LoadUserEvent>();
    final loadingState = manager.getEntity<LoadingStateComponent>();
    final loadingError = manager.getEntity<LoadingErrorComponent>();
    final userData = manager.getEntity<UserDataComponent>();

    // Extract userId from the load event
    final userId = loadEvent.userId!;
    // Set loading state to running
    loadingState.value = LoadingState.running;
    // Clear previous error
    loadingError.value = null;

    try {
      // Load user data
      userData.value = await _loadUser(userId);
      // Set loading state to success
      loadingState.value = LoadingState.success;
    } catch (error) {
      // Set loading state to error and record the error message
      loadingError.value = error.toString();
      // Set loading state to error
      loadingState.value = LoadingState.error;
    } finally {
      // Clean up the load event entity
      loadEvent.clearData();
    }
  }

  Future<User> _loadUser(String userId) async {
    // Simulate a network call to load user data
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
    // Return dummy user data
    return User(id: userId, name: 'John Doe', email: 'email@example.com');
  }
}
