part of '../navigation_feature.dart';

final class NavigateToSelectedRouteReactiveSystem extends ReactiveSystem {
  final ECSManager manager;
  final GlobalKey<NavigatorState> navigatorKey;

  NavigateToSelectedRouteReactiveSystem(
    this.manager, {
    required this.navigatorKey,
  });

  @override
  Set<Type> get reactsTo {
    return const {
      AppRouteComponent,
    };
  }

  @override
  Set<Type> get interactsWith {
    return const {};
  }

  @override
  void react() {
    final appRoute = manager.getEntity<AppRouteComponent>().value;
    navigatorKey.currentState?.pushReplacementNamed(appRoute.path);
  }
}
