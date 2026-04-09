// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'navigation_feature.dart';

// **************************************************************************
// ComponentGenerator
// **************************************************************************

final class AppRouteComponent extends ECSComponent<AppRoutes> {
  AppRouteComponent() : super(AppRoutes.home);
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
    return const {};
  }

  @override
  Set<Type> get interactsWith {
    return const {AppRouteComponent};
  }

  @override
  bool get reactsIf {
    return authState == AuthState.loggedIn;
  }

  @override
  void react() {
    getEntity<AppRouteComponent>().value = AppRoutes.dashboard;
  }
}

final class NavigateToLoginWhenLoggedOutReactiveSystem
    extends ECSReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return const {};
  }

  @override
  Set<Type> get interactsWith {
    return const {AppRouteComponent};
  }

  @override
  bool get reactsIf {
    return authState == AuthState.loggedOut;
  }

  @override
  void react() {
    getEntity<AppRouteComponent>().value = AppRoutes.login;
  }
}

final class HandleNavigateToSelectedRouteReactiveSystem
    extends ECSReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return const {};
  }

  @override
  void react() {
    final routeName = appRoute.path;
    navigatorKey.currentState?.pushReplacementNamed(routeName);
  }
}

// **************************************************************************
// FeatureGenerator
// **************************************************************************

final class NavigationFeature extends ECSFeature {
  NavigationFeature() {
    addEntity(AppRouteComponent());
    addEntity(NavigatorKeyDependency());
    addSystem(HandleNavigateToDashboardWhenLoggedInReactiveSystem());
    addSystem(NavigateToLoginWhenLoggedOutReactiveSystem());
    addSystem(HandleNavigateToSelectedRouteReactiveSystem());
  }
}
