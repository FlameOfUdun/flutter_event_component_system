part of '../navigation_feature.dart';

final class NavigateToSelectedRouteReactiveSystem extends ReactiveSystem {
  final GlobalKey<NavigatorState> navigatorKey;

  NavigateToSelectedRouteReactiveSystem({
    required this.navigatorKey,
  });

  @override
  Set<Type> get reactsTo {
    return const {
      AppRouteComponent,
    };
  }

  @override
  void react() {
    final appRoute = manager.getEntity<AppRouteComponent>().value;
    navigatorKey.currentState?.pushReplacementNamed(appRoute.path);
  }
}
