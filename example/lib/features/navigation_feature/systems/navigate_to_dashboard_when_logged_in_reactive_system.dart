part of '../navigation_feature.dart';

final class NavigateToDashboardWhenLoggedInReactiveSystem extends ReactiveSystem {
  NavigateToDashboardWhenLoggedInReactiveSystem();

  @override
  Set<Type> get reactsTo {
    return const {
      AuthStateComponent,
    };
  }

  @override
  bool get reactsIf {
    final authState = manager.getEntity<AuthStateComponent>().value;
    return authState == AuthState.loggedIn;
  }

  @override
  Set<Type> get interactsWith {
    return const {
      AppRouteComponent,
    };
  }

  @override
  void react() {
    final routeComponent = manager.getEntity<AppRouteComponent>();
    routeComponent.value = AppRoutes.dashboard;
  }
}
