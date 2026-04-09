/// Marks a top-level function as a reactive system.
/// `reactsTo` is auto-detected from the @Event function bodies that call this system.
/// `interactsWith` is auto-detected from writes in the body and its private helpers.
/// `reactsIf` is an optional reference to a `bool` function with the same parameters
/// as the system; if provided, its body is inlined as the `bool get reactsIf` getter.
final class ReactiveSystem {
  final String? description;
  final Function? reactsIf;
  const ReactiveSystem({this.description, this.reactsIf});
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
