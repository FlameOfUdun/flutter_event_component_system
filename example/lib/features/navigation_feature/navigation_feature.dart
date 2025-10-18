import 'package:flutter/material.dart';
import 'package:flutter_event_component_system/flutter_event_component_system.dart';

import '../user_auth_feature/user_auth_feature.dart';

part 'components/app_route_component.dart';

part 'systems/navigate_to_selected_route_reactive_system.dart';
part 'systems/navigate_to_dashboard_when_logged_in_reactive_system.dart';
part 'systems/navigate_to_login_when_logged_out_reactive_system.dart';

final class NavigationFeature extends ECSFeature {
  NavigationFeature({
    required GlobalKey<NavigatorState> navigatorKey,
  }) {
    addEntity(AppRouteComponent());

    addSystem(NavigateToDashboardWhenLoggedInReactiveSystem());
    addSystem(NavigateToLoginWhenLoggedOutReactiveSystem());

    addSystem(
      NavigateToSelectedRouteReactiveSystem(
        navigatorKey: navigatorKey,
      ),
    );
  }
}
