import 'package:flutter/material.dart';
import 'package:flutter_event_component_system/flutter_event_component_system.dart';

import '../features/user_auth_feature/user_auth_feature.dart';

class HomePage extends ECSWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, ECSContext ecs) {
    ecs.onEnter(() {
      ecs.get<ReloadUserEvent>().trigger();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to the Home Page!'),
          ],
        ),
      ),
    );
  }
}
