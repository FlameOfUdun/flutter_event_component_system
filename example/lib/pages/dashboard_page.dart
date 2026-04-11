import 'package:flutter/material.dart';
import 'package:flutter_event_component_system/flutter_event_component_system.dart';

import '../features/nested_feature/nested_feature.dart';
import '../features/timer_feature/timer_feature.dart';
import '../features/user_auth_feature/user_auth_feature.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ECSScope(
      name: 'NestedScope1',
      features: {
        NestedFeature(),
      },
      child: ECSBuilder(
        builder: (context, ecs) {
          final component = ecs.get<CounterComponent>();
          debugPrint('CounterComponent data: ${component.identifier}');

          return ECSScope(
            name: 'NestedScope2',
            features: {
              NestedFeature(),
            },
            child: ECSBuilder(
              builder: (context, ecs) {
                final component = ecs.get<CounterComponent>();
                debugPrint('CounterComponent data: ${component.identifier}');

                return Scaffold(
                  appBar: AppBar(
                    title: const Text('Dashboard'),
                  ),
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TimerDisplay(),
                        _LogoutButton(),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
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

class _TimerDisplay extends ECSWidget {
  const _TimerDisplay();

  @override
  Widget build(BuildContext context, ECSContext ecs) {
    ecs.onEnter(() {
      ecs.get<StartTimerEvent>().trigger();
    });
    final stopTimer = ecs.get<StopTimerEvent>().trigger;
    ecs.onExit(stopTimer);
    final timerValue = ecs.watch<TimerValueComponent>().value;
    return Text('Timer: ${timerValue.inSeconds} seconds');
  }
}
