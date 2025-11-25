part of '../navigation_feature.dart';

final class NavigateToLoginWhenLoggedOutReactiveSystem extends ReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return {
      AuthStateComponent,
    };
  }

  @override
  bool get reactsIf {
    final authState = getEntity<AuthStateComponent>().value;
    return authState == AuthState.loggedOut;
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
    routeComponent.value = AppRoutes.login;
  }
}
