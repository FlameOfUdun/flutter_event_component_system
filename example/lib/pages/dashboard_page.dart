import 'package:flutter/material.dart';
import 'package:flutter_event_component_system/flutter_event_component_system.dart';

import '../features/nested_feature/nested_feature.dart';
import '../features/user_auth_feature/user_auth_feature.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ECSScope(
      features: {
        NestedFeature(),
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
        ),
        body: const Center(
          child: _LogoutButton(),
        ),
      ),
    );
  }
}

class _LogoutButton extends ECSWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, ECSContext ecs) {
    final process = ecs.watch<LogoutProcessComponent>().value;

    return ElevatedButton(
      onPressed: process.isRunning ? null : ecs.get<LogoutEvent>().trigger,
      child: const Text('Logout'),
    );
  }
}
