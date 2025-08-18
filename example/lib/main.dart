import 'package:flutter/material.dart';
import 'package:flutter_event_component_system/flutter_event_component_system.dart';

import 'features/navigation_feature/navigation_feature.dart';
import 'features/timer_feature/timer_feature.dart';
import 'features/user_auth_feature/user_auth_feature.dart';
import 'pages/dashboard_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(_Application());
}

class _Application extends StatelessWidget {
  final navigatorKey = GlobalKey<NavigatorState>();

  _Application();

  @override
  Widget build(BuildContext context) {
    return ECSScope(
      features: (manager) {
        return {
          NavigationFeature(
            manager,
            navigatorKey: navigatorKey,
          ),
          UserAuthFeature(manager),
          TimerFeature(manager),
        };
      },
      child: MaterialApp(
        navigatorKey: navigatorKey,
        routes: {
          '/': (context) => const HomePage(),
          '/dashboard': (context) => const DashboardPage(),
          '/login': (context) => const LoginPage(),
        },
        builder: (context, child) {
          return Row(
            children: [
              Expanded(
                child: child ?? const SizedBox.shrink(),
              ),
              Expanded(
                child: MaterialApp(
                  home: ECSInspector(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
