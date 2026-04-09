/// Marks a top-level function as a reactive system.
/// `reactsTo` is a list of `@Event`-annotated function references this system reacts to.
///   Cross-library events are supported. Pass as a list literal: `reactsTo: [myEvent]`.
/// `interactsWith` is auto-detected from writes in the body and its private helpers.
/// `reactsIf` is an optional reference to a `bool` function with the same parameters
/// as the system; if provided, its body is inlined as the `bool get reactsIf` getter.
final class ReactiveSystem {
  final String? description;
  final List<Function>? reactsTo;
  final Function? reactsIf;
  const ReactiveSystem({this.description, this.reactsTo, this.reactsIf});
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
/// `cleansIf` is an optional reference to a no-parameter `bool` function;
/// if provided, its body is inlined as the `bool get cleansIf` getter override.
final class CleanupSystem {
  final String? description;
  final Function? cleansIf;
  const CleanupSystem({this.description, this.cleansIf});
}

/// Marks a top-level function as an execute system.
/// The function must accept a single `Duration elapsed` parameter.
/// `executesIf` is an optional reference to a `bool` function with the same
/// `Duration elapsed` parameter; if provided, its body is inlined as the
/// `bool get executesIf` getter override.
final class ExecuteSystem {
  final String? description;
  final Function? executesIf;
  const ExecuteSystem({this.description, this.executesIf});
}
