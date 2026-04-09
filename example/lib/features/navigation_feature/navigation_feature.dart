import 'package:flutter/material.dart';
import 'package:flutter_event_component_system/flutter_event_component_system.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';

import '../user_auth_feature/user_auth_feature.dart';

part 'models/app_routes.dart';
part 'navigation_feature.ecs.g.dart';

@Component()
AppRoutes appRoute = AppRoutes.home;

@Component()
AppRoutes selectedRoute = AppRoutes.home;

@Dependency()
GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@ReactiveSystem()
class HandleNavigateToDashboardWhenLoggedIn {
  List get reactsTo {
    return [authState];
  }

  bool get reactsIf {
    return authState == AuthState.loggedIn;
  }

  void react() {
    selectedRoute = AppRoutes.dashboard;
  }
}

@ReactiveSystem()
class HandleNavigateToLoginWhenLoggedOut {
  List get reactsTo {
    return [authState];
  }

  bool get reactsIf {
    return authState == AuthState.loggedOut;
  }

  void react() {
    selectedRoute = AppRoutes.login;
  }
}

@ReactiveSystem()
class HandleNavigateToSelectedRoute {
  List get reactsTo {
    return [selectedRoute];
  }

  void react(AppRoutes route) {
    final key = navigatorKey.currentState!;
    key.pushReplacementNamed(route.path);
  }
}


