/// Marks a top-level function as a reactive system.
/// `reactsTo` is auto-detected from the @Event function bodies that call this system.
/// `interactsWith` is auto-detected from writes in the body and its private helpers.
final class ReactiveSystem {
  final String? description;
  const ReactiveSystem({this.description});
}

/// Marks a top-level function as an initialize system.
final class InitializeSystem {
  final String? description;
  const InitializeSystem({this.description});
}

/// Marks a top-level function as a teardown system.
final class TeardownSystem {
  final String? description;
  const TeardownSystem({this.description});
}

/// Marks a top-level function as a cleanup system.
final class CleanupSystem {
  final String? description;
  const CleanupSystem({this.description});
}

/// Marks a top-level function as an execute system.
/// The function must accept a single `Duration elapsed` parameter.
final class ExecuteSystem {
  final String? description;
  const ExecuteSystem({this.description});
}
