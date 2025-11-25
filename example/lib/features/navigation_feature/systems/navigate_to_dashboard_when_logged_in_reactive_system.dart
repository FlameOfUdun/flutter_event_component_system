part of '../navigation_feature.dart';

final class NavigateToDashboardWhenLoggedInReactiveSystem extends ReactiveSystem {
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
  void react() {
    final routeComponent = getEntity<AppRouteComponent>();
    routeComponent.value = AppRoutes.dashboard;
  }
}
