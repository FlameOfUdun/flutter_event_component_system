import 'package:flutter/material.dart';
import 'package:flutter_event_component_system/flutter_event_component_system.dart';

import '../features/user_auth_feature/user_auth_feature.dart';

class LoginPage extends ECSWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, ECSContext ecs) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: const Center(
        child: _LoginButton(),
      ),
    );
  }
}

class _LoginButton extends ECSWidget {
  const _LoginButton();

  @override
  Widget build(BuildContext context, ECSContext ecs) {
    final process = ecs.watch<LoginProcessComponent>().value;

    return ElevatedButton(
      onPressed: process.isRunning ? null : ecs.get<LoginEvent>().trigger,
      child: const Text('Login'),
    );
  }
}
