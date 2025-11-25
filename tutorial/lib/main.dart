import 'package:flutter/material.dart';
import 'package:flutter_event_component_system/flutter_event_component_system.dart';

import 'user_profile_feature/components/loading_error_component.dart';
import 'user_profile_feature/components/loading_state_component.dart';
import 'user_profile_feature/components/user_data_component.dart';
import 'user_profile_feature/events/load_user_event.dart';
import 'user_profile_feature/user_profile_feature.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ECSScope(
      features: {UserProfileFeature()},
      child: const MaterialApp(
        home: UserProfilePage(userId: '123')
      ),
    );
  }
}

class UserProfilePage extends ECSWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, ECSContext ecs) {
    final loadEvent = ecs.get<LoadUserEvent>();
    final userData = ecs.watch<UserDataComponent>();
    final loadingState = ecs.watch<LoadingStateComponent>();
    final loadingError = ecs.watch<LoadingErrorComponent>();

    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: Builder(
        builder: (context) {
          // Display loading indicator, error message, or user data based on state
          if (loadingState.value == LoadingState.running) {
            return const Center(child: CircularProgressIndicator());
          }
      
          // Handle error state
          if (loadingState.value == LoadingState.error) {
            return Center(child: Text('Error: ${loadingError.value}'));
          }
      
          // Display user data if loaded
          if (userData.value != null) {
            return Center(child: Text('User Loaded: ${userData.value!.name} - ${userData.value!.email}'));
          }
      
          // Initial state with load button
          return Center(
            child: ElevatedButton(
              onPressed: () => loadEvent.triggerWithUserId(userId), 
              child: const Text('Load User Profile')),
          );
        },
      ),
    );
  }
}
