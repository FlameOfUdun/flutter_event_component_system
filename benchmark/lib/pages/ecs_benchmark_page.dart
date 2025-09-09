import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_event_component_system/flutter_event_component_system.dart';

import '../implementations/ecs_implementation.dart';
import '../models/benchmark_models.dart';
import '../utilties/benchmark_runner.dart';

class ECSBenchmarkPage extends StatelessWidget {
  const ECSBenchmarkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ECSScope(
      features: (manager) {
        return {
          CounterFeature(manager),
          TodoFeature(manager),
          LoadingFeature(manager),
          UserProfileFeature(manager),
        };
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ECS Benchmark'),
        ),
        body: _MainContent(),
      ),
    );
  }
}

class _MainContent extends ECSStatefulWidget {
  const _MainContent();

  @override
  ECSState<_MainContent> createState() => _MainContentState();
}

class _MainContentState extends ECSState<_MainContent> {
  Completer<void>? completer;

  @override
  Widget build(BuildContext context) {
    ecs.watch<CounterComponent>();
    ecs.watch<TodoListComponent>();
    ecs.watch<LoadingComponent>();
    ecs.watch<UserProfileComponent>();

    if (completer != null && !completer!.isCompleted) {
      completer!.complete();
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () async {
              print('Running ECS Benchmark (Basic)...');
              await runCounterBenchmark();
              await runProfileBenchmark();
              await runTodoBenchmark();
              print('ECS Benchmark (Basic) completed');
            },
            child: const Text('Run ECS Benchmark (Basic)'),
          ),
        ],
      ),
    );
  }

  Future<void> runCounterBenchmark() async {
    print('Running Counter Benchmark...');

    final incrementEvent = ecs.get<IncrementEvent>();
    final decrementEvent = ecs.get<DecrementEvent>();
    final resetEvent = ecs.get<ResetCounterEvent>();

    await benchmarkRunner.runBenchmarkIterations(
      testName: 'Counter Benchmark',
      implementation: 'ECS',
      iterations: 100,
      operations: 3,
      test: () async {
        completer = Completer<void>();
        incrementEvent.trigger();
        await completer!.future;

        completer = Completer<void>();
        decrementEvent.trigger();
        await completer!.future;

        completer = Completer<void>();
        resetEvent.trigger();
        await completer!.future;
      },
    );

    final average = benchmarkRunner.getAverageResult('Counter Benchmark', 'ECS');
    print('Counter Benchmark completed: $average');
  }

  Future<void> runProfileBenchmark() async {
    print('Running User Profile Benchmark...');

    final updateEvent = ecs.get<UpdateUserEvent>();
    final loginEvent = ecs.get<LoginEvent>();
    final logoutEvent = ecs.get<LogoutEvent>();

    await benchmarkRunner.runBenchmarkIterations(
      testName: 'User Profile Benchmark',
      implementation: 'ECS',
      iterations: 100,
      operations: 3,
      test: () async {
        completer = Completer<void>();
        loginEvent.triggerWith(UserProfile(
          id: 'user',
          name: 'User',
          email: 'user@example.com',
        ));
        await completer!.future;

        completer = Completer<void>();
        updateEvent.triggerWith(UserProfile(
          id: 'user',
          name: 'Updated User',
          email: 'user@example.com',
        ));
        await completer!.future;

        completer = Completer<void>();
        logoutEvent.trigger();
        await completer!.future;
      },
    );
    
    final average = benchmarkRunner.getAverageResult('User Profile Benchmark', 'ECS');
    print('User Profile Benchmark completed: $average');
  }

  Future<void> runTodoBenchmark() async {
    print('Running Todo Benchmark...');

    final addEvent = ecs.get<AddTodoEvent>();
    final removeEvent = ecs.get<RemoveTodoEvent>();
    final toggleEvent = ecs.get<ToggleTodoEvent>();

    await benchmarkRunner.runBenchmarkIterations(
      testName: 'Todo Benchmark',
      implementation: 'ECS',
      iterations: 100,
      operations: 3,
      test: () async {
        completer = Completer<void>();
        addEvent.triggerWith(TodoItem(
          id: 'todo',
          title: 'Todo',
          isCompleted: false,
          createdAt: DateTime.now(),
        ));
        await completer!.future;

        completer = Completer<void>();
        toggleEvent.triggerWith('todo');
        await completer!.future;

        completer = Completer<void>();
        removeEvent.triggerWith('todo');
        await completer!.future;
      },
    );
    
    final average = benchmarkRunner.getAverageResult('Todo Benchmark', 'ECS');
    print('Todo Benchmark completed: $average');
  }
}
