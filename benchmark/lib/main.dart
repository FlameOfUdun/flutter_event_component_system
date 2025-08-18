import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pages/ecs_benchmark_page.dart';
import 'pages/provider_benchmark_page.dart';
import 'pages/riverpod_benchmark_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      child: const BenchmarkApp(),
    ),
  );
}

class BenchmarkApp extends StatelessWidget {
  const BenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ECS vs Provider vs Riverpod Benchmark',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text('ECS vs Provider vs Riverpod Benchmark'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ECSBenchmarkPage(),
                        ),
                      );
                    },
                    child: Text('ECS Benchmark'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProviderBenchmarkPage(),
                        ),
                      );
                    },
                    child: Text('Provider Benchmark'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RiverpodBenchmarkPage(),
                        ),
                      );
                    },
                    child: Text('Riverpod Benchmark'),
                  ),
                  
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}
