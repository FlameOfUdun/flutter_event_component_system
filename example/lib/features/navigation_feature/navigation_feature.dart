import 'package:flutter/material.dart';
import 'package:flutter_event_component_system/flutter_event_component_system.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';

import '../user_auth_feature/user_auth_feature.dart';

part 'models/app_routes.dart';
part 'navigation_feature.ecs.g.dart';

@Component()
AppRoutes appRoute = AppRoutes.home;

@Dependency()
GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@ReactiveSystem(reactsIf: navigateToDashboardWhenLoggedInIf)
void handleNavigateToDashboardWhenLoggedIn() {
  appRoute = AppRoutes.dashboard;
}

bool navigateToDashboardWhenLoggedInIf() {
  return authState == AuthState.loggedIn;
}

@ReactiveSystem(reactsIf: navigateToLoginWhenLoggedOutIf)
void navigateToLoginWhenLoggedOut() {
  appRoute = AppRoutes.login;
}

bool navigateToLoginWhenLoggedOutIf() {
  return authState == AuthState.loggedOut;
}

@ReactiveSystem()
void handleNavigateToSelectedRoute(AppRoutes selectedRoute) {
  final routeName = appRoute.path;
  navigatorKey.currentState?.pushReplacementNamed(routeName);
}
