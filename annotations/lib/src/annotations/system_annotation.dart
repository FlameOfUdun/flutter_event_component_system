/// Marks a top-level class as a reactive system.
final class ReactiveSystem {
  final String? description;
  const ReactiveSystem({this.description});
}

/// Marks a top-level class as an initialize system.
final class InitializeSystem {
  final String? description;
  const InitializeSystem({this.description});
}

/// Marks a top-level class as a teardown system.
final class TeardownSystem {
  final String? description;
  const TeardownSystem({this.description});
}

/// Marks a top-level class as a cleanup system.
final class CleanupSystem {
  final String? description;
  const CleanupSystem({this.description});
}

/// Marks a top-level class as an execute system.
final class ExecuteSystem {
  final String? description;
  const ExecuteSystem({this.description});
}
