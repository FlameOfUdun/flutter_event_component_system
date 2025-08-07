part of '../navigation_feature.dart';

final class NavigateToLoginWhenLoggedOutReactiveSystem extends ReactiveSystem {
  final ECSManager manager;

  NavigateToLoginWhenLoggedOutReactiveSystem(this.manager);

  @override
  Set<Type> get reactsTo {
    return {
      AuthStateComponent,
    };
  }

  @override
  bool get reactsIf {
    final authState = manager.getEntity<AuthStateComponent>().value;
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
    final routeComponent = manager.getEntity<AppRouteComponent>();
    routeComponent.update(AppRoutes.login);
  }
}
