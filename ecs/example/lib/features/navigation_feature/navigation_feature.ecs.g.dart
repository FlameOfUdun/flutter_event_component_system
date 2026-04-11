// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_feature.dart';

final class AppRouteComponent extends ECSComponent<AppRoutes> {
  AppRouteComponent() : super(AppRoutes.home);
}

final class SelectedRouteComponent extends ECSComponent<AppRoutes> {
  SelectedRouteComponent() : super(AppRoutes.home);
}

final class NavigatorKeyDependency extends ECSDependency<GlobalKey<NavigatorState>> {
  NavigatorKeyDependency() : super(GlobalKey<NavigatorState>());
}

final class NavigateToDashboardWhenLoggedInReactiveSystem extends ECSReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return const {AuthStateComponent};
  }

  @override
  Set<Type> get interactsWith {
    return const {SelectedRouteComponent};
  }

  @override
  bool get reactsIf {
    return getEntity<AuthStateComponent>().value == AuthState.loggedIn;
  }

  @override
  void react() {
    getEntity<SelectedRouteComponent>().value = AppRoutes.dashboard;
  }
}

final class HandleNavigateToLoginWhenLoggedOutReactiveSystem extends ECSReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return const {AuthStateComponent};
  }

  @override
  Set<Type> get interactsWith {
    return const {SelectedRouteComponent};
  }

  @override
  bool get reactsIf {
    return getEntity<AuthStateComponent>().value == AuthState.loggedOut;
  }

  @override
  void react() {
    getEntity<SelectedRouteComponent>().value = AppRoutes.login;
  }
}

final class HandleNavigateToSelectedRouteReactiveSystem extends ECSReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return const {SelectedRouteComponent};
  }

  @override
  void react() {
    final route = getEntity<SelectedRouteComponent>().value.path;
    final key = getEntity<NavigatorKeyDependency>().value.currentState!;
    key.pushReplacementNamed(route);
  }
}

final class NavigationFeature extends ECSFeature {
  NavigationFeature() {
    addEntity(AppRouteComponent());
    addEntity(SelectedRouteComponent());
    addEntity(NavigatorKeyDependency());
    addSystem(NavigateToDashboardWhenLoggedInReactiveSystem());
    addSystem(HandleNavigateToLoginWhenLoggedOutReactiveSystem());
    addSystem(HandleNavigateToSelectedRouteReactiveSystem());
  }
}
