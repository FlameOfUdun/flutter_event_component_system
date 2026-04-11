part of 'ecs_builder.dart';

final class ReactiveSystemDefinition {
  ReactiveSystemDefinition._({
    bool Function()? reactsIf,
    required Set<ListenableEntityDefinition> reactsTo,
    required void Function() react,
  });
}

final class ExecuteSystemDefinition {
  ExecuteSystemDefinition._({
    bool Function()? executesIf,
    required void Function(Duration elapsed) execute,
  });
}

final class CleanupSystemDefinition {
  CleanupSystemDefinition._({
    bool Function()? cleansIf,
    required void Function() cleanup,
  });
}

final class TeardownSystemDefinition {
  TeardownSystemDefinition._({
    required void Function() teardown,
  });
}

final class InitializeSystemDefinition {
  InitializeSystemDefinition._({
    required void Function() initialize,
  });
}
