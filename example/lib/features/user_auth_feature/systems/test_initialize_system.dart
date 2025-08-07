part of '../user_auth_feature.dart';

final class TestInitializeSystem extends InitializeSystem {
  @override
  Set<Type> get interactsWith {
    return const {
      ReloadUserEvent
    };
  }

  @override
  void initialize() {
    // Do nothing
  }
}
