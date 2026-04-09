// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'navigation_feature.dart';

// **************************************************************************
// ComponentGenerator
// **************************************************************************

final class AppRouteComponent extends ECSComponent<AppRoutes> {
  AppRouteComponent() : super(AppRoutes.home);
}

final class SelectedRouteComponent extends ECSComponent<AppRoutes> {
  SelectedRouteComponent() : super(AppRoutes.home);
}

// **************************************************************************
// DependencyGenerator
// **************************************************************************

final class NavigatorKeyDependency
    extends ECSDependency<GlobalKey<NavigatorState>> {
  NavigatorKeyDependency() : super(GlobalKey<NavigatorState>());
}

// **************************************************************************
// ReactiveSystemGenerator
// **************************************************************************

final class HandleNavigateToDashboardWhenLoggedInReactiveSystem
    extends ECSReactiveSystem {
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

final class HandleNavigateToLoginWhenLoggedOutReactiveSystem
    extends ECSReactiveSystem {
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

final class HandleNavigateToSelectedRouteReactiveSystem
    extends ECSReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return const {SelectedRouteComponent};
  }

  @override
  void react() {
    final key = getEntity<NavigatorKeyDependency>().value.currentState!;
    key.pushReplacementNamed(getEntity<SelectedRouteComponent>().value.path);
  }
}

// **************************************************************************
// FeatureGenerator
// **************************************************************************

final class NavigationFeature extends ECSFeature {
  NavigationFeature() {
    addEntity(AppRouteComponent());
    addEntity(SelectedRouteComponent());
    addEntity(NavigatorKeyDependency());
    addSystem(HandleNavigateToDashboardWhenLoggedInReactiveSystem());
    addSystem(HandleNavigateToLoginWhenLoggedOutReactiveSystem());
    addSystem(HandleNavigateToSelectedRouteReactiveSystem());
  }
}
