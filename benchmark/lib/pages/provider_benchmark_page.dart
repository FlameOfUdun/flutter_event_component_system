import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../implementations/provider_implementation.dart';
import '../models/benchmark_models.dart';
import '../utilties/benchmark_runner.dart';

class ProviderBenchmarkPage extends StatelessWidget {
  const ProviderBenchmarkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CounterProvider()),
        ChangeNotifierProvider(create: (_) => TodoProvider()),
        ChangeNotifierProvider(create: (_) => LoadingProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Provider Benchmark'),
        ),
        body: _MainContent(),
      ),
    );
  }
}

class _MainContent extends StatefulWidget {
  const _MainContent();

  @override
  State<_MainContent> createState() => _MainContentState();
}

class _MainContentState extends State<_MainContent> {
  Completer<void>? completer;

  @override
  Widget build(BuildContext context) {
    return Consumer4<CounterProvider, TodoProvider, LoadingProvider, UserProfileProvider>(
      builder: (context, counter, todo, loading, userProfile, child) {
        // Complete the completer when the widget rebuilds (indicating state change)
        if (completer != null && !completer!.isCompleted) {
          completer!.complete();
        }
    
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  print('Running Provider Benchmark (Basic)...');
                  await runCounterBenchmark();
                  await runProfileBenchmark();
                  await runTodoBenchmark();
                  print('Provider Benchmark (Basic) completed');
                },
                child: const Text('Run Provider Benchmark (Basic)'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> runCounterBenchmark() async {
    print('Running Counter Benchmark...');

    final counterProvider = Provider.of<CounterProvider>(context, listen: false);

    await benchmarkRunner.runBenchmarkIterations(
      testName: 'Counter Benchmark',
      implementation: 'Provider',
      iterations: 100,
      operations: 3,
      test: () async {
        completer = Completer<void>();
        counterProvider.increment();
        await completer!.future;

        completer = Completer<void>();
        counterProvider.decrement();
        await completer!.future;

        completer = Completer<void>();
        counterProvider.reset();
        await completer!.future;
      },
    );

    final average = benchmarkRunner.getAverageResult('Counter Benchmark', 'Provider');
    print('Counter Benchmark completed: $average');
  }

  Future<void> runProfileBenchmark() async {
    print('Running User Profile Benchmark...');

    final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);

    await benchmarkRunner.runBenchmarkIterations(
      testName: 'User Profile Benchmark',
      implementation: 'Provider',
      iterations: 100,
      operations: 3,
      test: () async {
        completer = Completer<void>();
        userProfileProvider.login(UserProfile(
          id: 'user',
          name: 'User',
          email: 'user@example.com',
        ));
        await completer!.future;

        completer = Completer<void>();
        userProfileProvider.updateUser(UserProfile(
          id: 'user',
          name: 'Updated User',
          email: 'user@example.com',
        ));
        await completer!.future;

        completer = Completer<void>();
        userProfileProvider.logout();
        await completer!.future;
      },
    );

    final average = benchmarkRunner.getAverageResult('User Profile Benchmark', 'Provider');
    print('User Profile Benchmark completed: $average');
  }

  Future<void> runTodoBenchmark() async {
    print('Running Todo Benchmark...');

    final todoProvider = Provider.of<TodoProvider>(context, listen: false);

    await benchmarkRunner.runBenchmarkIterations(
      testName: 'Todo Benchmark',
      implementation: 'Provider',
      iterations: 100,
      operations: 3,
      test: () async {
        completer = Completer<void>();
        todoProvider.addItem(TodoItem(
          id: 'todo',
          title: 'Todo',
          isCompleted: false,
          createdAt: DateTime.now(),
        ));
        await completer!.future;

        completer = Completer<void>();
        todoProvider.toggleItem('todo');
        await completer!.future;

        completer = Completer<void>();
        todoProvider.removeItem('todo');
        await completer!.future;
      },
    );

    final average = benchmarkRunner.getAverageResult('Todo Benchmark', 'Provider');
    print('Todo Benchmark completed: $average');
  }
}
