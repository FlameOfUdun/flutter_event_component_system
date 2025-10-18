import 'dart:async';
import 'package:flutter/foundation.dart';

/// Benchmark result for a single test
@immutable
class BenchmarkResult {
  final String testName;
  final String implementation;
  final Duration duration;
  final Duration? stateUpdateDuration;
  final Duration? uiPropagationDuration;
  final int operations;
  final Map<String, dynamic> additionalMetrics;

  const BenchmarkResult({
    required this.testName,
    required this.implementation,
    required this.duration,
    this.stateUpdateDuration,
    this.uiPropagationDuration,
    required this.operations,
    this.additionalMetrics = const {},
  });

  double get operationsPerSecond => operations / duration.inMicroseconds * 1000000;
  double get averageTimePerOperation => duration.inMicroseconds / operations;

  double? get stateUpdateOpsPerSecond => stateUpdateDuration != null ? operations / stateUpdateDuration!.inMicroseconds * 1000000 : null;

  double? get uiPropagationOpsPerSecond => uiPropagationDuration != null ? operations / uiPropagationDuration!.inMicroseconds * 1000000 : null;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('BenchmarkResult('
        'test: $testName, '
        'impl: $implementation, '
        'total: ${duration.inMilliseconds}ms, '
        'ops/sec: ${operationsPerSecond.toStringAsFixed(2)}');

    if (stateUpdateDuration != null) {
      buffer.write(', state: ${stateUpdateDuration!.inMilliseconds}ms');
    }

    if (uiPropagationDuration != null) {
      buffer.write(', ui: ${uiPropagationDuration!.inMilliseconds}ms');
    }

    return buffer.toString();
  }
}

/// Benchmark runner for comparing state management solutions
class BenchmarkRunner {
  final List<BenchmarkResult> _results = [];

  List<BenchmarkResult> get results => List.unmodifiable(_results);

  /// Run a benchmark test with separate timing for state update and UI propagation
  Future<BenchmarkResult> runBenchmark({
    required String testName,
    required String implementation,
    required Future<void> Function() test,
    int operations = 1,
    Map<String, dynamic> additionalMetrics = const {},
  }) async {
    // Force garbage collection before test
    if (!kIsWeb) {
      // Note: GC not directly accessible in Dart, system will handle it
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final stopwatch = Stopwatch()..start();

    await test();

    stopwatch.stop();

    final result = BenchmarkResult(
      testName: testName,
      implementation: implementation,
      duration: stopwatch.elapsed,
      operations: operations,
      additionalMetrics: additionalMetrics,
    );

    _results.add(result);
    return result;
  }

  /// Run a benchmark test with separate timing measurements
  Future<BenchmarkResult> runBenchmarkWithSeparateTiming({
    required String testName,
    required String implementation,
    required Future<Duration> Function() stateUpdateTest,
    required Future<Duration> Function() uiPropagationTest,
    int operations = 1,
    Map<String, dynamic> additionalMetrics = const {},
  }) async {
    // Force garbage collection before test
    if (!kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final totalStopwatch = Stopwatch()..start();

    // Measure state update time
    final stateUpdateDuration = await stateUpdateTest();

    // Measure UI propagation time
    final uiPropagationDuration = await uiPropagationTest();

    totalStopwatch.stop();

    final result = BenchmarkResult(
      testName: testName,
      implementation: implementation,
      duration: totalStopwatch.elapsed,
      stateUpdateDuration: stateUpdateDuration,
      uiPropagationDuration: uiPropagationDuration,
      operations: operations,
      additionalMetrics: additionalMetrics,
    );

    _results.add(result);
    return result;
  }

  /// Run multiple iterations of a benchmark with separate timing
  Future<List<BenchmarkResult>> runBenchmarkIterationsWithSeparateTiming({
    required String testName,
    required String implementation,
    required Future<Duration> Function() stateUpdateTest,
    required Future<Duration> Function() uiPropagationTest,
    int iterations = 10,
    int operations = 1,
  }) async {
    final results = <BenchmarkResult>[];

    for (int i = 0; i < iterations; i++) {
      final result = await runBenchmarkWithSeparateTiming(
        testName: '$testName (iteration ${i + 1})',
        implementation: implementation,
        stateUpdateTest: stateUpdateTest,
        uiPropagationTest: uiPropagationTest,
        operations: operations,
      );
      results.add(result);
    }

    return results;
  }

  /// Run multiple iterations of a benchmark
  Future<List<BenchmarkResult>> runBenchmarkIterations({
    required String testName,
    required String implementation,
    required Future<void> Function() test,
    int iterations = 10,
    int operations = 1,
  }) async {
    final results = <BenchmarkResult>[];

    for (int i = 0; i < iterations; i++) {
      final result = await runBenchmark(
        testName: '$testName (iteration ${i + 1})',
        implementation: implementation,
        test: test,
        operations: operations,
      );
      results.add(result);
    }

    return results;
  }

  /// Get average results for a specific test and implementation
  BenchmarkResult getAverageResult(String testName, String implementation) {
    final relevantResults = _results.where((r) => r.testName.startsWith(testName) && r.implementation == implementation).toList();

    if (relevantResults.isEmpty) {
      throw ArgumentError('No results found for $testName with $implementation');
    }

    final avgDuration = Duration(
      microseconds: (relevantResults.map((r) => r.duration.inMicroseconds).reduce((a, b) => a + b) / relevantResults.length).round(),
    );

    Duration? avgStateUpdateDuration;
    Duration? avgUiPropagationDuration;

    // Calculate averages for separate timings if available
    final stateUpdateDurations =
        relevantResults.where((r) => r.stateUpdateDuration != null).map((r) => r.stateUpdateDuration!.inMicroseconds).toList();

    if (stateUpdateDurations.isNotEmpty) {
      avgStateUpdateDuration = Duration(
        microseconds: (stateUpdateDurations.reduce((a, b) => a + b) / stateUpdateDurations.length).round(),
      );
    }

    final uiPropagationDurations =
        relevantResults.where((r) => r.uiPropagationDuration != null).map((r) => r.uiPropagationDuration!.inMicroseconds).toList();

    if (uiPropagationDurations.isNotEmpty) {
      avgUiPropagationDuration = Duration(
        microseconds: (uiPropagationDurations.reduce((a, b) => a + b) / uiPropagationDurations.length).round(),
      );
    }

    final totalOperations = relevantResults.first.operations;

    return BenchmarkResult(
      testName: '$testName (average)',
      implementation: implementation,
      duration: avgDuration,
      stateUpdateDuration: avgStateUpdateDuration,
      uiPropagationDuration: avgUiPropagationDuration,
      operations: totalOperations,
    );
  }

  /// Generate comparison report
  String generateReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== Benchmark Results ===\n');

    // Group results by test name
    final groupedResults = <String, List<BenchmarkResult>>{};
    for (final result in _results) {
      final testName = result.testName.split(' (').first;
      groupedResults.putIfAbsent(testName, () => []).add(result);
    }

    for (final testName in groupedResults.keys) {
      buffer.writeln('Test: $testName');
      buffer.writeln('-' * 50);

      final implementations = groupedResults[testName]!.map((r) => r.implementation).toSet();

      for (final impl in implementations) {
        try {
          final avgResult = getAverageResult(testName, impl);
          buffer.writeln('  $impl:');
          buffer.writeln('    Total Duration: ${avgResult.duration.inMilliseconds}ms');
          buffer.writeln('    Ops/sec: ${avgResult.operationsPerSecond.toStringAsFixed(2)}');

          if (avgResult.stateUpdateDuration != null) {
            buffer.writeln('    State Update: ${avgResult.stateUpdateDuration!.inMilliseconds}ms');
            buffer.writeln('    State Ops/sec: ${avgResult.stateUpdateOpsPerSecond!.toStringAsFixed(2)}');
          }

          if (avgResult.uiPropagationDuration != null) {
            buffer.writeln('    UI Propagation: ${avgResult.uiPropagationDuration!.inMilliseconds}ms');
            buffer.writeln('    UI Ops/sec: ${avgResult.uiPropagationOpsPerSecond!.toStringAsFixed(2)}');
          }

        } catch (e) {
          buffer.writeln('  $impl: No average available');
        }
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Clear all results
  void clear() {
    _results.clear();
  }
}

/// Global benchmark runner instance
final benchmarkRunner = BenchmarkRunner();
