part of '../navigation_feature.dart';

final class NavigateToDashboardWhenLoggedInReactiveSystem extends ECSReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return const {
      AuthStateComponent,
    };
  }

  @override
  bool get reactsIf {
    final authState = getEntity<AuthStateComponent>().value;
    return authState == AuthState.loggedIn;
  }

  @override
  Set<Type> get interactsWith {
    return const {
      AppRouteComponent,
    };
  }

  @override
  void react() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate async work
    final routeComponent = getEntity<AppRouteComponent>();
    routeComponent.value = AppRoutes.dashboard;
  }
}
