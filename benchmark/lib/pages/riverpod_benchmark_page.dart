import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../implementations/riverpod_implementation.dart';
import '../models/benchmark_models.dart';
import '../utilties/benchmark_runner.dart';

class RiverpodBenchmarkPage extends StatelessWidget {
  const RiverpodBenchmarkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: _MainContent(),
    );
  }
}

class _MainContent extends ConsumerStatefulWidget {
  const _MainContent();

  @override
  ConsumerState<_MainContent> createState() => _RiverpodBenchmarkPageState();
}

class _RiverpodBenchmarkPageState extends ConsumerState<_MainContent> {
  Completer<void>? completer;

  @override
  Widget build(BuildContext context) {
    // Watch all providers to trigger rebuilds
    ref.watch(counterProvider);
    ref.watch(todoProvider);
    ref.watch(loadingProvider);
    ref.watch(userProfileProvider);

    // Complete the completer when the widget rebuilds (indicating state change)
    if (completer != null && !completer!.isCompleted) {
      completer!.complete();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riverpod Benchmark'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await runCounterBenchmark();
                await runProfileBenchmark();
                await runTodoBenchmark();
              },
              child: const Text('Run Riverpod Benchmark'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> runCounterBenchmark() async {
    debugPrint('Running Counter Benchmark...');

    final counterNotifier = ref.read(counterProvider.notifier);

    await benchmarkRunner.runBenchmarkIterations(
      testName: 'Counter Benchmark',
      implementation: 'Riverpod',
      iterations: 100,
      operations: 3,
      test: () async {
        completer = Completer<void>();
        counterNotifier.increment();
        await completer!.future;

        completer = Completer<void>();
        counterNotifier.decrement();
        await completer!.future;

        completer = Completer<void>();
        counterNotifier.reset();
        await completer!.future;
      },
    );

    debugPrint(benchmarkRunner.generateReport());
  }

  Future<void> runProfileBenchmark() async {
    debugPrint('Running User Profile Benchmark...');

    final userNotifier = ref.read(userProfileProvider.notifier);

    await benchmarkRunner.runBenchmarkIterations(
      testName: 'User Profile Benchmark',
      implementation: 'Riverpod',
      iterations: 100,
      operations: 3,
      test: () async {
        completer = Completer<void>();
        userNotifier.login(UserProfile(
          id: 'user',
          name: 'User',
          email: 'user@example.com',
        ));
        await completer!.future;

        completer = Completer<void>();
        userNotifier.updateUser(UserProfile(
          id: 'user',
          name: 'Updated User',
          email: 'user@example.com',
        ));
        await completer!.future;

        completer = Completer<void>();
        userNotifier.logout();
        await completer!.future;
      },
    );

    debugPrint(benchmarkRunner.generateReport());
  }

  Future<void> runTodoBenchmark() async {
    debugPrint('Running Todo Benchmark...');

    final todoNotifier = ref.read(todoProvider.notifier);

    await benchmarkRunner.runBenchmarkIterations(
      testName: 'Todo Benchmark',
      implementation: 'Riverpod',
      iterations: 100,
      operations: 3,
      test: () async {
        completer = Completer<void>();
        todoNotifier.addItem(TodoItem(
          id: 'todo',
          title: 'Todo',
          isCompleted: false,
          createdAt: DateTime.now(),
        ));
        await completer!.future;

        completer = Completer<void>();
        todoNotifier.toggleItem('todo');
        await completer!.future;

        completer = Completer<void>();
        todoNotifier.removeItem('todo');
        await completer!.future;
      },
    );

    debugPrint(benchmarkRunner.generateReport());
  }
}
